import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data'; // Add this
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_voice_engine/flutter_voice_engine.dart';
import 'package:image/image.dart' as imglib;
import 'package:permission_handler/permission_handler.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      error: error, // Allow setting error to null
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
  SessionCubit() : super(SessionState()) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    _genAI = GoogleGenAI(apiKey: apiKey!);
    print('Initialized Gemini AI with API key: ${apiKey.substring(0, 10)}...');
  }

  FlutterVoiceEngine? _voiceEngine;
  late final GoogleGenAI _genAI;
  LiveSession? _geminiSession;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  CameraImage? _latestCameraImage;
  StreamSubscription<dynamic>? _voiceEngineSubscription;
  Timer? _imageSendTimer;

  bool _isGeminiConnected = false;
  bool _isConnecting = false; // Flag to prevent connection spam

  CameraController? get cameraController => _cameraController;

  @override
  Future<void> close() async {
    print('Closing Session Cubit');
    await stopSession(); // Use stopSession for a clean shutdown
    super.close();
  }

  Future<void> startSession() async {
    print('Starting session in idle mode');

    await requestMicrophonePermission();
    await requestCameraPermission();

    try {
      // Only initialize camera for idle mode, not voice engine or websocket
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

  // New method for starting online mode
  Future<void> startOnlineMode() async {
    if (state.mode != SessionMode.idle) return;

    print('Starting online mode with Gemini Live API');
    emit(state.copyWith(mode: SessionMode.online, connecting: true));

    try {
      // Reinitialize camera with yuv420 format for Gemini Live compatibility
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

  // New method for starting offline mode
  Future<void> startOfflineMode() async {
    if (state.mode != SessionMode.idle) return;

    print('Starting offline mode');
    emit(state.copyWith(mode: SessionMode.offline));

    // Ensure camera is using nv21 format for MLKit compatibility
    await _initCameraForOfflineMode();
  }

  // New method for canceling current mode and returning to idle
  Future<void> cancelCurrentMode() async {
    print('Canceling current mode: ${state.mode}');

    switch (state.mode) {
      case SessionMode.online:
        await _stopOnlineMode();
        break;
      case SessionMode.offline:
        await _stopOfflineMode();
        break;
      case SessionMode.idle:
      // Already idle, nothing to do
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

    // Reinitialize camera to nv21 format for idle/offline compatibility
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

    // Stop recording and playback, but keep the voice engine alive
    await stopRecording();
    await _voiceEngine?.stopPlayback();

    // Close the Gemini Live session
    await _geminiSession?.close();
    _isGeminiConnected = false;
    _isConnecting = false;
  }

  Future<void> _stopOfflineMode() async {
    print('Stopping offline mode');
    // Any cleanup needed for offline mode
  }

  Future<void> stopSession() async {
    print('Stopping session');
    _imageSendTimer?.cancel();
    _imageSendTimer = null;
    _playbackStopTimer?.cancel();
    _playbackStopTimer = null;
    _latestCameraImage = null;

    // Stop recording and playback
    await stopRecording();
    await _voiceEngine?.stopPlayback();

    // Only shutdown the voice engine on complete session stop
    if (_voiceEngine?.isInitialized ?? false) {
      if (Platform.isAndroid) {
        await _voiceEngine?.shutdownAll();
      } else {
        await _voiceEngine?.shutdownBot();
      }
      _voiceEngine = null;
    }

    if (_cameraController != null) {
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();
      _cameraController = null;
    }

    await _geminiSession?.close();
    _isGeminiConnected = false;
    _isConnecting = false;

    emit(SessionState()); // Reset to the initial state
  }

  Future<void> _initVoiceEngine() async {
    print('Initializing VoiceEngine');
    try {
      if (_voiceEngine != null && _voiceEngine!.isInitialized) {
        print('VoiceEngine already initialized, reusing.');
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
      print('VoiceEngine initialized');
    } catch (e, stackTrace) {
      print('VoiceEngine initialization failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _connectToGeminiLive() async {
    if (_isConnecting || _isGeminiConnected) {
      print(
        'Gemini Live connection attempt ignored: already connecting or connected.',
      );
      return;
    }

    if (state.mode != SessionMode.online) {
      print('Gemini Live connection ignored: not in online mode.');
      return;
    }

    print('Connecting to Gemini Live API...');
    print('Using model: gemini-2.0-flash-live-001');
    print('Response modalities: [AUDIO]');
    _isConnecting = true;
    emit(state.copyWith(connecting: true, isError: false, error: null));

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          config: GenerationConfig(
            responseModalities: [Modality.AUDIO], // We want audio responses
            temperature: 0.8,
            topK: 40,
            topP: 0.95,
          ),
          systemInstruction: Content(
            parts: [
              Part(
                text:
                "You are an AI assistant for visually impaired users. "
                    "Describe what you see in the camera images clearly and concisely. "
                    "Provide helpful information about the environment, objects, text, and people. "
                    "Keep responses brief but informative. "
                    "If you see text, read it aloud. "
                    "If you see people, describe what they're doing. "
                    "Be helpful and encouraging. "
                    "Wait for the user to finish speaking before responding. "
                    "Do not respond continuously - wait for new input.",
              ),
            ],
          ),
          callbacks: LiveCallbacks(
            onOpen: () {
              print('Gemini Live session opened successfully');
              _isGeminiConnected = true;
              _isConnecting = false;
              _startRecordingAndImageStreaming();
            },
            onMessage: _handleGeminiLiveMessage,
            onError: (error, stack) {
              print('Gemini Live error: $error');
              print('Stack trace: $stack');
              _isGeminiConnected = false;
              _isConnecting = false;
              _imageSendTimer?.cancel();
              _imageSendTimer = null;

              String errorMessage = 'Gemini Live error: $error';
              if (error.toString().contains('1007')) {
                errorMessage =
                'API key invalid or insufficient permissions. Please check your Gemini API key.';
              } else if (error.toString().contains('precondition')) {
                errorMessage =
                'Connection precondition failed. Please check API key and model access.';
              }

              emit(
                state.copyWith(
                  isError: true,
                  error: errorMessage,
                  mode: SessionMode.idle,
                  connecting: false,
                  isStreamingImages: false,
                ),
              );
              _stopAllStreams();
            },
            onClose: (code, reason) {
              print('Gemini Live disconnected: $code, $reason');
              _isGeminiConnected = false;
              _isConnecting = false;
              _imageSendTimer?.cancel();
              _imageSendTimer = null;
              if (state.mode == SessionMode.online) {
                emit(
                  state.copyWith(
                    mode: SessionMode.idle,
                    isRecording: false,
                    isError: true,
                    error: 'Gemini Live disconnected. Returning to idle mode.',
                    connecting: false,
                    isStreamingImages: false,
                  ),
                );
              }
              _stopAllStreams();
            },
          ),
        ),
      );

      _geminiSession = session;
      print('Gemini Live connection attempt successful.');
    } catch (e, stackTrace) {
      print('Gemini Live connection failed: $e\n$stackTrace');
      _isConnecting = false;
      emit(
        state.copyWith(
          error: 'Gemini Live connection failed: $e',
          isError: true,
          mode: SessionMode.idle,
          connecting: false,
        ),
      );
    }
  }

  Future<void> _startRecordingAndImageStreaming() async {
    print('Starting recording and image streaming...');

    // Add a small delay to ensure connection is fully established
    await Future.delayed(const Duration(milliseconds: 500));

    await startRecording();
    print('Audio ready, initializing image streaming...');

    // Ensure camera is streaming before starting image timer
    await _ensureCameraStreamingForOnlineMode();

    // Add another delay before starting image streaming
    await Future.delayed(const Duration(milliseconds: 1000));
    _startImageSendTimer(); // Start sending images from existing camera

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
      print('Received Gemini Live message');

      // Handle text responses (though we're primarily using audio)
      if (message.text != null) {
        print('Received text: ${message.text}');
      }

      // Handle audio responses - Audio comes through realtimeInput or modelTurn parts
      if (message.serverContent?.modelTurn?.parts != null) {
        for (final part in message.serverContent!.modelTurn!.parts!) {
          if (part.inlineData != null &&
              part.inlineData!.mimeType.startsWith('audio/')) {
            print(
              'Received audio data: ${part.inlineData!.data.length} chars (base64)',
            );

            // Decode base64 audio data
            final audioData = base64Decode(part.inlineData!.data);
            final amplitude = computeRMSAmplitude(audioData);
            emit(
              state.copyWith(
                isBotSpeaking: true,
                visualizerAmplitude: amplitude,
              ),
            );

            try {
              // Amplify audio data by a factor
              final Uint8List amplifiedAudio = _amplifyAudio(
                audioData,
                amplificationFactor: 12.0,
              );
              _voiceEngine?.playAudioChunk(amplifiedAudio);
            } catch (e, stackTrace) {
              print('Playback error: $e\n$stackTrace');
              emit(state.copyWith(error: 'Playback error: $e', isError: true));
            }
          }
        }
      }

      // When the model's turn is complete, add delay before stopping playback
      if (message.serverContent?.turnComplete ?? false) {
        print('Gemini turn complete - scheduling playback stop with delay');
        _schedulePlaybackStop();
      }

      // Handle generation complete
      if (message.serverContent?.generationComplete ?? false) {
        print(
          'Gemini generation complete - scheduling playback stop with delay',
        );
        _schedulePlaybackStop();
      }
    } catch (e, stackTrace) {
      print('Gemini Live message error: $e\n$stackTrace');
      emit(
        state.copyWith(error: 'Gemini Live message error: $e', isError: true),
      );
    }
  }

  Timer? _playbackStopTimer;

  void _schedulePlaybackStop() {
    // Cancel any existing timer
    _playbackStopTimer?.cancel();

    // Schedule playback stop with a delay to ensure all audio is played
    _playbackStopTimer = Timer(const Duration(milliseconds: 1000), () {
      print('Stopping playback after delay');
      _voiceEngine?.stopPlayback();
      emit(state.copyWith(isBotSpeaking: false, visualizerAmplitude: 0.0));
      _playbackStopTimer = null;
    });
  }

  Future<void> _stopAllStreams() async {
    _imageSendTimer?.cancel();
    _imageSendTimer = null;
    _playbackStopTimer?.cancel();
    _playbackStopTimer = null;
    _latestCameraImage = null;
    await stopRecording();
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController?.stopImageStream();
    }
    emit(
      state.copyWith(
        isRecording: false,
        isCameraActive: state.isCameraActive,
        showCameraPreview: state.showCameraPreview,
        isStreamingImages: false,
        connecting: false,
        isBotSpeaking: false,
      ),
    );
  }

  Future<void> _initCamera() async {
    print('Initializing Camera for idle mode (nv21 format)');
    await _initCameraWithFormat(ImageFormatGroup.nv21);
  }

  Future<void> _initCameraForOnlineMode() async {
    print('Initializing Camera for online mode (yuv420 format for WebSocket)');
    await _initCameraWithFormat(
      Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
  }

  Future<void> _initCameraForOfflineMode() async {
    print('Initializing Camera for offline mode (nv21 format for MLKit)');
    await _initCameraWithFormat(
      Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
  }

  Future<void> _initCameraWithFormat(ImageFormatGroup format) async {
    print('Initializing Camera with format: $format');
    emit(
      state.copyWith(isInitializingCamera: true, error: null, isError: false),
    );
    try {
      // Always dispose and reinitialize to ensure correct format
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController?.dispose();
        _cameraController = null;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception("No cameras available on this device.");
      }

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
      print('Camera initialized with format $format. Starting image stream...');

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
    } catch (e, stackTrace) {
      print('Camera initialization failed: $e\n$stackTrace');
      emit(
        state.copyWith(
          isInitializingCamera: false,
          isCameraActive: false,
          showCameraPreview: false,
          isStreamingImages: false,
          error: 'Camera initialization failed: $e',
          isError: true,
        ),
      );
      await _cameraController?.dispose();
      _cameraController = null;
    }
  }

  Future<void> _ensureCameraStreamingForOnlineMode() async {
    print('Ensuring camera is streaming for online mode...');

    // Always reinitialize camera for online mode to ensure yuv420 format
    print('Reinitializing camera with yuv420 format for online mode...');
    await _initCameraForOnlineMode();
  }

  void _startImageSendTimer() {
    _imageSendTimer?.cancel();
    print('Starting image send timer...');
    _imageSendTimer = Timer.periodic(const Duration(milliseconds: 3000), (
        // Reduced frequency to 3 seconds
        timer,
        ) async {
      if (_latestCameraImage != null &&
          _geminiSession != null &&
          _isGeminiConnected) {
        try {
          print('Sending image to Gemini Live...');
          final Uint8List? jpegBytes = await compute(
            convertCameraImageToJpeg,
            _latestCameraImage!,
          );

          if (jpegBytes != null) {
            final String base64Image = base64Encode(jpegBytes);

            // Send image using realtimeInput like in Python server (not clientContent)
            _geminiSession!.sendMessage(
              LiveClientMessage(
                realtimeInput: LiveClientRealtimeInput(
                  video: Blob(mimeType: 'image/jpeg', data: base64Image),
                ),
              ),
            );
            print('Image sent successfully (${jpegBytes.length} bytes)');
          } else {
            print('Failed to convert camera image to JPEG');
          }
        } catch (e, stackTrace) {
          print("Error processing/sending timed picture: $e\n$stackTrace");
        }
      } else {
        print(
          'Cannot send image: latestCameraImage=${_latestCameraImage != null}, geminiSession=${_geminiSession != null}, geminiConnected=$_isGeminiConnected',
        );
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          print("Camera not active for timed image send. Stopping timer.");
          timer.cancel();
          _imageSendTimer = null;
          emit(state.copyWith(isStreamingImages: false));
        }
      }
    });
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      print("Switch camera failed: Less than 2 cameras available.");
      emit(state.copyWith(error: 'Only one camera found.', isError: true));
      Future.delayed(
        const Duration(seconds: 2),
            () => emit(state.copyWith(isError: false, error: null)),
      );
      return;
    }
    if (state.isInitializingCamera) {
      print("Already switching camera.");
      return;
    }

    emit(state.copyWith(isInitializingCamera: true, showCameraPreview: false));

    try {
      final CameraDescription currentCamera = _cameraController!.description;
      final CameraDescription newCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection != currentCamera.lensDirection,
      );

      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();
      _cameraController = null;
      _latestCameraImage = null;

      // Choose format based on current mode
      ImageFormatGroup desiredFormat;
      if (state.mode == SessionMode.online) {
        // Online mode uses yuv420 for WebSocket compatibility
        desiredFormat = Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888;
      } else {
        // Idle and offline modes use nv21 for MLKit compatibility
        desiredFormat = Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888;
      }

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: desiredFormat,
      );

      await _cameraController!.initialize();
      print('Camera switched and initialized. Starting image stream...');

      await _cameraController!.startImageStream((CameraImage image) {
        _latestCameraImage = image;
      });

      emit(
        state.copyWith(
          isInitializingCamera: false,
          isCameraActive: true,
          showCameraPreview: true,
          isStreamingImages: true,
        ),
      );
    } catch (e, stackTrace) {
      print('Error switching camera: $e\n$stackTrace');
      emit(
        state.copyWith(
          error: 'Error switching camera: $e',
          isError: true,
          isInitializingCamera: false,
        ),
      );
    }
  }

  // The corrected startRecording() function

  // Add these print statements to your startRecording() function

  Future<void> startRecording() async {
    print("--- START RECORDING CALLED ---");
    try {
      if (!(_voiceEngine?.isInitialized ?? false)) {
        print("Voice engine not ready, initializing...");
        await _initVoiceEngine();
      }

      emit(state.copyWith(isRecording: true));
      print("--- STATE EMITTED: isRecording is now true ---");

      _voiceEngineSubscription?.cancel();
      _voiceEngineSubscription = _voiceEngine!.audioChunkStream.listen(
            (audioData) {
          print(
            "--- AUDIO CHUNK RECEIVED! Length: ${audioData.length}, isRecording state: ${state.isRecording} ---",
          );

          if (_geminiSession != null &&
              _isGeminiConnected &&
              state.isRecording) {
            // Send audio directly to Gemini Live using realtimeInput like in Python server
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
        onError: (error, stackTrace) {
          print('!!! Recording stream ERROR: $error\n$stackTrace');
          emit(state.copyWith(error: 'Recording error: $error', isError: true));
        },
        onDone: () {
          print("--- Recording stream is DONE. ---");
        },
      );

      print("Now calling _voiceEngine.startRecording()...");
      await _voiceEngine!.startRecording();
      print("--- Call to _voiceEngine.startRecording() is COMPLETE. ---");
    } catch (e, stackTrace) {
      print('!!! FAILED to start recording: $e\n$stackTrace');
      emit(
        state.copyWith(error: 'Failed to start recording: $e', isError: true),
      );
    }
  }

  Future<void> stopRecording() async {
    print('Stopping recording');
    try {
      _voiceEngineSubscription?.cancel();
      _voiceEngineSubscription = null;
      if (_voiceEngine?.isRecording ?? false) {
        await _voiceEngine!.stopRecording();
      }
      emit(state.copyWith(isRecording: false));
    } catch (e, stackTrace) {
      print('Error stopping recording: $e\n$stackTrace');
      emit(
        state.copyWith(error: 'Error stopping recording: $e', isError: true),
      );
    }
  }

  double computeRMSAmplitude(Uint8List pcm, {int bytesPerSample = 2}) {
    if (pcm.isEmpty) return 0.0;
    int sampleCount = pcm.length ~/ bytesPerSample;
    if (sampleCount == 0) return 0.0;
    double sumSquares = 0;
    for (int i = 0; i < pcm.length; i += bytesPerSample) {
      int sample = pcm.buffer.asByteData().getInt16(i, Endian.little);
      sumSquares += sample * sample;
    }
    double rms = sqrt(sumSquares / sampleCount) / 32768.0;
    return rms.clamp(0.0, 1.0);
  }

  static Future<Uint8List?> convertCameraImageToJpeg(
      CameraImage cameraImage,
      ) async {
    try {
      imglib.Image? img;
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        img = imglib.Image.fromBytes(
          width: cameraImage.width,
          height: cameraImage.height,
          bytes: cameraImage.planes[0].bytes.buffer,
          order: imglib.ChannelOrder.bgra,
        );
      } else if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final int width = cameraImage.width;
        final int height = cameraImage.height;
        final Uint8List yPlane = cameraImage.planes[0].bytes;
        final Uint8List uPlane = cameraImage.planes[1].bytes;
        final Uint8List vPlane = cameraImage.planes[2].bytes;
        final int yRowStride = cameraImage.planes[0].bytesPerRow;
        final int uvRowStride = cameraImage.planes[1].bytesPerRow;
        final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

        img = imglib.Image(width: width, height: height);

        for (int h = 0; h < height; h++) {
          for (int w = 0; w < width; w++) {
            final int yIndex = h * yRowStride + w;
            final int uvIndex =
                (h ~/ 2) * uvRowStride + (w ~/ 2) * uvPixelStride;

            if (yIndex >= yPlane.length ||
                uvIndex >= uPlane.length ||
                uvIndex >= vPlane.length) {
              continue;
            }
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
    } catch (e, stackTrace) {
      print('Error converting CameraImage to JPEG: $e\n$stackTrace');
      return null;
    }
  }

  static Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Camera permission denied');
      }
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    final requestStatus = await Permission.microphone.request();
    return requestStatus.isGranted;
  }

  // New method to get current camera image for offline analysis
  CameraImage? getCurrentCameraImage() {
    return _latestCameraImage;
  }

  // Method to test API key validity
  Future<bool> testApiKey() async {
    try {
      print('Testing API key validity...');
      final testSession = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          config: GenerationConfig(
            responseModalities: [Modality.TEXT], // Use text for quick test
          ),
          callbacks: LiveCallbacks(
            onOpen: () => print('API key test: Connection successful'),
            onMessage: (message) => print('API key test: Received message'),
            onError: (error, stack) => print('API key test: Error - $error'),
            onClose: (code, reason) =>
                print('API key test: Closed - $code, $reason'),
          ),
        ),
      );
      await testSession.close();
      print('API key test: SUCCESS');
      return true;
    } catch (e) {
      print('API key test: FAILED - $e');
      return false;
    }
  }

  // Method to update the Gemini API key if needed
  void updateGeminiApiKey(String apiKey) {
    if (apiKey.isEmpty) return;
    // Note: This would require reinitializing the GoogleGenAI instance
    // For simplicity, we'll just log this - in practice you'd want to restart the session
    print('API key update requested - session restart required');
  }
}

//
//
//
//
//
//
//
//
//
//
//

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
    // Clamp to prevent distortion
    amplifiedSample = amplifiedSample.clamp(-32768, 32767);
    amplifiedByteData.setInt16(i, amplifiedSample, Endian.little);
  }

  return amplifiedData;
}