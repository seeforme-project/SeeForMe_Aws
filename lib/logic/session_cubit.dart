import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voice_engine/flutter_voice_engine.dart';
import 'package:image/image.dart' as imglib;
import 'package:permission_handler/permission_handler.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:seeforyou_aws/services/mlkit_service.dart';
import 'package:flutter/services.dart' show rootBundle;

// Enum for different interaction modes
enum SessionMode {
  idle, // Waiting for gestures, camera preview active
  offline, // MLKit analysis in progress
  online, // WebSocket connection active
}

// SessionState
class SessionState {
  final SessionMode mode;
  final bool isSessionStarted;
  final bool isRecording;

  final bool isError;
  final String? error;

  final bool isInitializingCamera;
  final bool isCameraActive;
  final bool showCameraPreview;
  final bool isStreamingImages;

  final bool connecting;
  final bool isBotSpeaking;

  final double visualizerAmplitude;

  SessionState({
    this.mode = SessionMode.idle,
    this.isSessionStarted = false,
    this.isRecording = false,
    this.isError = false,
    this.error,
    this.isInitializingCamera = false,
    this.isCameraActive = false,
    this.showCameraPreview = false,
    this.isStreamingImages = false,
    this.connecting = false,
    this.isBotSpeaking = false,
    this.visualizerAmplitude = 0.0,
  });

  SessionState copyWith({
    SessionMode? mode,
    bool? isSessionStarted,
    bool? isRecording,
    bool? isError,
    String? error,
    bool? isInitializingCamera,
    bool? isCameraActive,
    bool? showCameraPreview,
    bool? isStreamingImages,
    bool? isBotSpeaking,
    bool? connecting,
    double? visualizerAmplitude,
  }) {
    return SessionState(
      mode: mode ?? this.mode,
      isSessionStarted: isSessionStarted ?? this.isSessionStarted,
      isRecording: isRecording ?? this.isRecording,
      isError: isError ?? this.isError,
      error: error,
      isInitializingCamera: isInitializingCamera ?? this.isInitializingCamera,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      showCameraPreview: showCameraPreview ?? this.showCameraPreview,
      isStreamingImages: isStreamingImages ?? this.isStreamingImages,
      connecting: connecting ?? this.connecting,
      isBotSpeaking: isBotSpeaking ?? this.isBotSpeaking,
      visualizerAmplitude: visualizerAmplitude ?? this.visualizerAmplitude,
    );
  }
}

class SessionCubit extends Cubit<SessionState> {
  GoogleGenAI?
  _genAI; // Changed to nullable to prevent crashes if key is missing

  // --- SERVICES ---
  FlutterVoiceEngine? _voiceEngine;
  LiveSession? _geminiSession;
  final MLKitService _mlKitService =
  MLKitService(); // Initialize ML Kit Service

  // --- CAMERA & STATE VARIABLES ---
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  CameraImage? _latestCameraImage;
  StreamSubscription<dynamic>? _voiceEngineSubscription;
  Timer? _imageSendTimer;
  Timer? _playbackStopTimer;

  bool _isGeminiConnected = false;
  bool _isConnecting = false;

  CameraController? get cameraController => _cameraController;
  bool _isSwitchingCamera = false;

  SessionCubit() : super(SessionState()) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey != null && apiKey.isNotEmpty) {
      _genAI = GoogleGenAI(apiKey: apiKey);
      print('✅ Initialized Gemini AI with API key.');
    } else {
      print('❌ ERROR: GEMINI_API_KEY is missing in .env file!');
      emit(
        state.copyWith(
          isError: true,
          error: "API Key missing. Please check .env file.",
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    print('Closing Session Cubit');
    await _mlKitService.dispose(); // Clean up ML Kit resources
    await stopSession();
    super.close();
  }

  Future<void> startSession() async {
    print('Starting session in idle mode');

    await requestMicrophonePermission();
    await requestCameraPermission();

    try {
      // Initialize camera for idle mode
      await _initCamera();
      emit(
        state.copyWith(
          mode: SessionMode.idle,
          isSessionStarted: true,
          isError: false,
          error: null,
        ),
      );
    } catch (e, stackTrace) {
      print('Initialization failed: $e\n$stackTrace');
      emit(
        state.copyWith(
          error: 'Initialization failed: $e',
          isError: true,
          isSessionStarted: false,
        ),
      );
    }
  }

  // --- ONLINE MODE (GEMINI LIVE) ---

  Future<void> startOnlineMode() async {
    if (state.mode != SessionMode.idle) return;

    print('Starting online mode with Gemini Live API');
    emit(state.copyWith(mode: SessionMode.online, connecting: true));

    try {
      // Switch camera format to YUV420 (required for Gemini Live)
      await _initCameraForOnlineMode();
      await _initVoiceEngine();
      await _connectToGeminiLive();
    } catch (e, stackTrace) {
      print('Online mode initialization failed: $e\n$stackTrace');
      emit(
        state.copyWith(
          error: 'Failed to start online mode: $e',
          isError: true,
          mode: SessionMode.idle,
          connecting: false,
        ),
      );
    }
  }

  // --- OFFLINE MODE (ML KIT) ---

  Future<void> startOfflineMode() async {
    if (state.mode != SessionMode.idle) return;

    print('Starting offline mode');
    emit(state.copyWith(mode: SessionMode.offline));

    // 1. Switch Format Safely
    await _initCameraForOfflineMode();

    // 2. Wait for Focus/Stream
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      if (_latestCameraImage != null && _cameraController != null) {
        // 3. Perform Analysis
        await _mlKitService.performOfflineAnalysis(
          _latestCameraImage!,
          _cameraController!.description,
        );
      } else {
        await _mlKitService.speak("Camera not ready.");
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isError: true));
    } finally {
      // 4. Return to idle
      await cancelCurrentMode();
    }
  }

  // --- MODE MANAGEMENT ---

  // Central function to stop whatever is currently running
  Future<void> cancelCurrentMode() async {
    print('Canceling current mode: ${state.mode}');

    // 1. Always stop ML Kit TTS if it is speaking
    await _mlKitService.stopSpeaking();

    switch (state.mode) {
      case SessionMode.online:
        await _stopOnlineMode();
        break;
      case SessionMode.offline:
      // Offline mode usually stops itself via the finally block in startOfflineMode,
      // but we call this to be safe (e.g. user double tapped mid-sentence)
        await _stopOfflineMode();
        break;
      case SessionMode.idle:
        break;
    }

    emit(
      state.copyWith(
        mode: SessionMode.idle,
        isRecording: false,
        connecting: false,
        isBotSpeaking: false,
        isError: false,
        error: null,
      ),
    );

    // Reinitialize camera to NV21 format for idle state (readiness)
    if (state.isCameraActive) {
      await _initCamera();
    }
  }

  Future<void> _stopOnlineMode() async {
    print('Stopping online mode');
    _imageSendTimer?.cancel();
    _imageSendTimer = null;
    _playbackStopTimer?.cancel();
    _playbackStopTimer = null;

    await stopRecording();
    await _voiceEngine?.stopPlayback();

    await _geminiSession?.close();
    _isGeminiConnected = false;
    _isConnecting = false;
  }

  Future<void> _stopOfflineMode() async {
    print('Stopping offline mode');
    // Logic handled mostly by _mlKitService.stopSpeaking() in cancelCurrentMode
  }

  Future<void> stopSession() async {
    print('Stopping session completely');
    await cancelCurrentMode(); // Use helper to stop current mode first

    // Dispose camera
    if (_cameraController != null) {
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();
      _cameraController = null;
    }

    // Shutdown voice engine completely
    if (_voiceEngine?.isInitialized ?? false) {
      if (Platform.isAndroid) {
        await _voiceEngine?.shutdownAll();
      } else {
        await _voiceEngine?.shutdownBot();
      }
      _voiceEngine = null;
    }

    emit(SessionState()); // Reset state
  }

  // --- INTERNAL HELPERS (Voice, Camera, Gemini) ---

  Future<void> _initVoiceEngine() async {
    print('Initializing VoiceEngine');
    try {
      if (_voiceEngine != null && _voiceEngine!.isInitialized) {
        return;
      }

      _voiceEngine = FlutterVoiceEngine();
      _voiceEngine!.audioConfig = AudioConfig(
        sampleRate: 16000,
        channels: 1,
        bitDepth: 16,
        bufferSize: 4096,
        enableAEC: true,
      );
      _voiceEngine!.sessionConfig = AudioSessionConfig(
        category: AudioCategory.playAndRecord,
        mode: AudioMode.spokenAudio,
        options: {
          AudioOption.defaultToSpeaker,
          AudioOption.allowBluetoothA2DP,
          AudioOption.mixWithOthers,
        },
      );
      await _voiceEngine!.initialize();
    } catch (e, stackTrace) {
      print('VoiceEngine initialization failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _connectToGeminiLive() async {
    if (_genAI == null) {
      emit(
        state.copyWith(error: "Gemini API Key not initialized", isError: true),
      );
      return;
    }

    if (_isConnecting || _isGeminiConnected) return;

    print('Connecting to Gemini Live API...');
    _isConnecting = true;
    emit(state.copyWith(connecting: true, isError: false, error: null));

    try {
      final systemPrompt = await rootBundle.loadString(
        'assets/live_api_system_prompt.txt',
      );

      // Use bang operator (!) because we checked for null at start
      final session = await _genAI!.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          config: GenerationConfig(
            responseModalities: [Modality.AUDIO],
            temperature: 0.8,
            topK: 40,
            topP: 0.95,
          ),
          systemInstruction: Content(parts: [Part(text: systemPrompt)]),
          callbacks: LiveCallbacks(
            onOpen: () {
              print('Gemini Live session opened');
              _isGeminiConnected = true;
              _isConnecting = false;
              _startRecordingAndImageStreaming();
            },
            onMessage: _handleGeminiLiveMessage,
            onError: (error, stack) {
              print('Gemini Live error: $error');
              _handleConnectionError(error.toString());
            },
            onClose: (code, reason) {
              print('Gemini Live disconnected: $code');
              _handleConnectionError('Disconnected');
            },
          ),
        ),
      );

      _geminiSession = session;
    } catch (e, stackTrace) {
      print('Gemini Live connection failed: $e\n$stackTrace');
      _handleConnectionError(e.toString());
    }
  }

  void _handleConnectionError(String msg) {
    _isGeminiConnected = false;
    _isConnecting = false;
    _imageSendTimer?.cancel();
    emit(
      state.copyWith(
        isError: true,
        error: msg,
        mode: SessionMode.idle,
        connecting: false,
        isStreamingImages: false,
      ),
    );
    _stopAllStreams();
  }

  Future<void> _startRecordingAndImageStreaming() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await startRecording();
    await _ensureCameraStreamingForOnlineMode();
    await Future.delayed(const Duration(milliseconds: 1000));
    _startImageSendTimer();

    emit(
      state.copyWith(
        mode: SessionMode.online,
        isSessionStarted: true,
        connecting: false,
        isStreamingImages: true,
      ),
    );
  }

  void _handleGeminiLiveMessage(LiveServerMessage message) {
    try {
      if (message.serverContent?.modelTurn?.parts != null) {
        for (final part in message.serverContent!.modelTurn!.parts!) {
          if (part.inlineData != null &&
              part.inlineData!.mimeType.startsWith('audio/')) {
            final audioData = base64Decode(part.inlineData!.data);
            final amplitude = computeRMSAmplitude(audioData);
            emit(
              state.copyWith(
                isBotSpeaking: true,
                visualizerAmplitude: amplitude,
              ),
            );

            try {
              final Uint8List amplifiedAudio = _amplifyAudio(
                audioData,
                amplificationFactor: 12.0,
              );
              _voiceEngine?.playAudioChunk(amplifiedAudio);
            } catch (e) {
              print('Playback error: $e');
            }
          }
        }
      }

      if ((message.serverContent?.turnComplete ?? false) ||
          (message.serverContent?.generationComplete ?? false)) {
        _schedulePlaybackStop();
      }
    } catch (e) {
      print('Gemini message error: $e');
    }
  }

  void _schedulePlaybackStop() {
    _playbackStopTimer?.cancel();
    _playbackStopTimer = Timer(const Duration(milliseconds: 1000), () {
      _voiceEngine?.stopPlayback();
      emit(state.copyWith(isBotSpeaking: false, visualizerAmplitude: 0.0));
      _playbackStopTimer = null;
    });
  }

  Future<void> _stopAllStreams() async {
    _imageSendTimer?.cancel();
    _playbackStopTimer?.cancel();
    _latestCameraImage = null;
    await stopRecording();
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController?.stopImageStream();
    }
    emit(
      state.copyWith(
        isRecording: false,
        isStreamingImages: false,
        connecting: false,
        isBotSpeaking: false,
      ),
    );
  }

  // --- CAMERA HANDLING ---

  Future<void> _initCamera() async {
    await _initCameraWithFormat(ImageFormatGroup.nv21);
  }

  Future<void> _initCameraForOnlineMode() async {
    await _initCameraWithFormat(
      Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
  }

  Future<void> _initCameraForOfflineMode() async {
    await _initCameraWithFormat(
      Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
  }

  Future<void> _initCameraWithFormat(ImageFormatGroup format) async {
    if (_isSwitchingCamera) return; // Prevent overlapping calls
    _isSwitchingCamera = true;

    emit(
      state.copyWith(isInitializingCamera: true, error: null, isError: false),
    );

    try {
      // 1. Safely dispose old controller
      if (_cameraController != null) {
        // Stop stream first
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
        _latestCameraImage = null;
      }

      // 2. Init new controller
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras available.");

      final camera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: format,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream((CameraImage image) {
        _latestCameraImage = image;
      });

      emit(
        state.copyWith(
          isInitializingCamera: false,
          isCameraActive: true,
          showCameraPreview: true,
        ),
      );
    } catch (e) {
      print('Camera init failed: $e');
      emit(
        state.copyWith(
          isInitializingCamera: false,
          error: 'Camera error. Please restart app.',
          isError: true,
        ),
      );
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> _ensureCameraStreamingForOnlineMode() async {
    await _initCameraForOnlineMode();
  }

  void _startImageSendTimer() {
    _imageSendTimer?.cancel();
    _imageSendTimer = Timer.periodic(const Duration(milliseconds: 3000), (
        timer,
        ) async {
      if (_latestCameraImage != null &&
          _geminiSession != null &&
          _isGeminiConnected) {
        try {
          final Uint8List? jpegBytes = await compute(
            convertCameraImageToJpeg,
            _latestCameraImage!,
          );
          if (jpegBytes != null) {
            final String base64Image = base64Encode(jpegBytes);
            _geminiSession!.sendMessage(
              LiveClientMessage(
                realtimeInput: LiveClientRealtimeInput(
                  video: Blob(mimeType: 'image/jpeg', data: base64Image),
                ),
              ),
            );
          }
        } catch (e) {
          print("Image send error: $e");
        }
      }
    });
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    if (state.isInitializingCamera) return;

    emit(state.copyWith(isInitializingCamera: true, showCameraPreview: false));

    try {
      final currentLens = _cameraController!.description.lensDirection;
      final newCamera = _cameras.firstWhere(
            (c) => c.lensDirection != currentLens,
      );

      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      ImageFormatGroup format = (state.mode == SessionMode.online)
          ? (Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888)
          : (Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888);

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: format,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(
            (image) => _latestCameraImage = image,
      );

      emit(
        state.copyWith(
          isInitializingCamera: false,
          isCameraActive: true,
          showCameraPreview: true,
          isStreamingImages: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Switch camera failed: $e', isError: true));
    }
  }

  // --- RECORDING (AUDIO) ---

  Future<void> startRecording() async {
    try {
      if (!(_voiceEngine?.isInitialized ?? false)) {
        await _initVoiceEngine();
      }

      emit(state.copyWith(isRecording: true));

      _voiceEngineSubscription?.cancel();
      _voiceEngineSubscription = _voiceEngine!.audioChunkStream.listen(
            (audioData) {
          if (_geminiSession != null &&
              _isGeminiConnected &&
              state.isRecording) {
            _geminiSession!.sendMessage(
              LiveClientMessage(
                realtimeInput: LiveClientRealtimeInput(
                  audio: Blob(
                    mimeType: 'audio/pcm;rate=16000',
                    data: base64Encode(audioData),
                  ),
                ),
              ),
            );
          }
          final amplitude = computeRMSAmplitude(audioData);
          emit(state.copyWith(visualizerAmplitude: amplitude));
        },
        onError: (error) => emit(
          state.copyWith(error: 'Recording error: $error', isError: true),
        ),
      );

      await _voiceEngine!.startRecording();
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to start recording: $e', isError: true),
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      _voiceEngineSubscription?.cancel();
      if (_voiceEngine?.isRecording ?? false) {
        await _voiceEngine!.stopRecording();
      }
      emit(state.copyWith(isRecording: false));
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  double computeRMSAmplitude(Uint8List pcm) {
    if (pcm.isEmpty) return 0.0;
    double sumSquares = 0;
    for (int i = 0; i < pcm.length; i += 2) {
      int sample = pcm.buffer.asByteData().getInt16(i, Endian.little);
      sumSquares += sample * sample;
    }
    return (sqrt(sumSquares / (pcm.length / 2)) / 32768.0).clamp(0.0, 1.0);
  }

  static Future<Uint8List?> convertCameraImageToJpeg(CameraImage image) async {
    // Conversion logic remains the same as provided previously
    try {
      imglib.Image? img;
      if (image.format.group == ImageFormatGroup.bgra8888) {
        img = imglib.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
          order: imglib.ChannelOrder.bgra,
        );
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        final int width = image.width;
        final int height = image.height;
        final Uint8List yPlane = image.planes[0].bytes;
        final Uint8List uPlane = image.planes[1].bytes;
        final Uint8List vPlane = image.planes[2].bytes;
        final int yRowStride = image.planes[0].bytesPerRow;
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

        img = imglib.Image(width: width, height: height);

        for (int h = 0; h < height; h++) {
          for (int w = 0; w < width; w++) {
            final int yIndex = h * yRowStride + w;
            final int uvIndex =
                (h ~/ 2) * uvRowStride + (w ~/ 2) * uvPixelStride;

            if (yIndex >= yPlane.length ||
                uvIndex >= uPlane.length ||
                uvIndex >= vPlane.length)
              continue;

            final int Y = yPlane[yIndex];
            final int U = uPlane[uvIndex];
            final int V = vPlane[uvIndex];

            int r = (Y + (V - 128) * 1.402).round().clamp(0, 255);
            int g = (Y - (U - 128) * 0.344136 - (V - 128) * 0.714136)
                .round()
                .clamp(0, 255);
            int b = (Y + (U - 128) * 1.772).round().clamp(0, 255);

            img.setPixelRgba(w, h, r, g, b, 255);
          }
        }
      } else {
        return null;
      }
      return Uint8List.fromList(imglib.encodeJpg(img, quality: 80));
    } catch (e) {
      return null;
    }
  }

  static Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) await Permission.camera.request();
  }

  static Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return (await Permission.microphone.request()).isGranted;
  }
}

Uint8List _amplifyAudio(
    Uint8List audioData, {
      double amplificationFactor = 2.0,
    }) {
  final ByteData byteData = audioData.buffer.asByteData();
  final Uint8List amplifiedData = Uint8List(audioData.length);
  final ByteData amplifiedByteData = amplifiedData.buffer.asByteData();

  for (int i = 0; i < audioData.length; i += 2) {
    int sample = byteData.getInt16(i, Endian.little);
    int amplifiedSample = (sample * amplificationFactor).round();
    amplifiedSample = amplifiedSample.clamp(-32768, 32767);
    amplifiedByteData.setInt16(i, amplifiedSample, Endian.little);
  }
  return amplifiedData;
}