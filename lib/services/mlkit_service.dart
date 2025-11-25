import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitService {
  late FlutterTts _flutterTts;
  late ObjectDetector _objectDetector;
  late ImageLabeler _imageLabeler;
  late TextRecognizer _textRecognizer;

  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize TTS
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Initialize MLKit detectors
    // 1. Object Detector
    final objectDetectorOptions = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectDetectorOptions);

    // 2. Image Labeler
    final imageLabelerOptions = ImageLabelerOptions(confidenceThreshold: 0.1);
    _imageLabeler = ImageLabeler(options: imageLabelerOptions);

    // 3. Text Recognizer
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    _isInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    _isInitialized = false;
    await _objectDetector.close();
    await _imageLabeler.close();
    await _textRecognizer.close();
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    // Wait for any existing speech to complete first
    while (_isSpeaking) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    _isSpeaking = true;

    try {
      // Stop any current speech before starting new one
      await _flutterTts.stop();
      await Future.delayed(Duration(milliseconds: 300)); // Longer pause

      print('TTS Speaking: "$text"');

      // Create a completer to wait for speech completion
      final completer = Completer<void>();

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        print('TTS Completed: "$text"');
        _isSpeaking = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Set error handler
      _flutterTts.setErrorHandler((message) {
        print('TTS Error: $message for text "$text"');
        _isSpeaking = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Start speaking
      await _flutterTts.speak(text);

      // Wait for completion or timeout
      try {
        await completer.future.timeout(
          Duration(seconds: 15),
        ); // Longer timeout for longer text
      } catch (e) {
        print('TTS timeout for text: "$text"');
        _isSpeaking = false;
      }

      // Small pause after completion
      await Future.delayed(Duration(milliseconds: 500)); // Longer pause
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isInitialized) return;
    _isSpeaking = false;
    await _flutterTts.stop();
  }

  Future<void> performOfflineAnalysis(
      CameraImage cameraImage,
      CameraDescription cameraDescription,
      ) async {
    if (!_isInitialized) await initialize();

    try {
      print('=== STARTING OFFLINE ANALYSIS ===');
      await speak("Let me see what's in front of you.");

      // Convert camera image to InputImage for MLKit using the reliable method
      final inputImage = _convertCameraImageToInputImage(
        cameraImage,
        cameraDescription,
      );

      if (inputImage == null) {
        print('Failed to convert camera image to InputImage');
        await speak("Sorry, I'm having trouble processing the image.");
        return;
      }

      print('Successfully converted image, starting detection...');

      // 1. Object Detection
      print('=== OBJECT DETECTION PHASE ===');
      await _performObjectDetection(inputImage);

      // 2. Scene Labeling
      print('=== IMAGE LABELING PHASE ===');
      await _performImageLabeling(inputImage);

      // 3. OCR (Text Recognition)
      print('=== TEXT RECOGNITION PHASE ===');
      await _performTextRecognition(inputImage);
      print('=== TEXT RECOGNITION COMPLETED ===');

      print('=== ANALYSIS COMPLETE ===');
      await speak(
        "That's what I can see. Swipe down again if you'd like me to look again.",
      );
      print('=== FINAL TTS COMPLETED ===');
    } catch (e, stackTrace) {
      print('Error in offline analysis: $e');
      print('Stack trace: $stackTrace');
      await speak("Sorry, I encountered an issue while analyzing the image.");
    }
  }

  Future<void> _performObjectDetection(InputImage inputImage) async {
    try {
      print('Starting object detection...');
      final List<DetectedObject> objects = await _objectDetector.processImage(
        inputImage,
      );

      print('Objects found: ${objects.length}');

      if (objects.isEmpty) {
        await speak("I don't see any specific objects here.");
        return;
      }

      String resultsText = 'Objects found: ${objects.length}\n\n';
      List<String> objectLabels = [];

      for (final object in objects) {
        resultsText +=
        'Object: trackingId: ${object.trackingId} - ${object.labels.map((e) => '${e.text}(${e.confidence.toStringAsFixed(2)})')}\n\n';

        for (Label label in object.labels) {
          print('  - ${label.text}: ${label.confidence.toStringAsFixed(2)}');
          if (label.confidence > 0.1) {
            // Very low threshold to catch anything
            objectLabels.add(label.text);
          }
        }
      }

      print(resultsText);

      if (objectLabels.isNotEmpty) {
        final uniqueLabels = objectLabels.toSet().toList();
        final objectsText = uniqueLabels.take(5).join(", ");
        print('Speaking object results: $objectsText');
        await speak("I can see $objectsText.");
      } else {
        print('Objects detected but confidence too low');
        await speak("I can see some objects but I'm not sure what they are.");
      }
    } catch (e) {
      print('Object detection error: $e');
      await speak("I'm having trouble identifying objects right now.");
    }
  }

  Future<void> _performImageLabeling(InputImage inputImage) async {
    try {
      print('Starting image labeling...');
      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      print('Labels found: ${labels.length}');

      if (labels.isEmpty) {
        await speak("The overall scene is unclear to me.");
        return;
      }

      String resultsText = 'Labels found: ${labels.length}\n\n';
      List<String> sceneLabels = [];

      for (final label in labels) {
        resultsText +=
        'Label: ${label.label}, Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
        print('  - ${label.label}: ${label.confidence.toStringAsFixed(2)}');

        if (label.confidence > 0.1) {
          // Very low threshold to catch anything
          sceneLabels.add(label.label);
        }
      }

      print(resultsText);

      if (sceneLabels.isNotEmpty) {
        final sceneText = sceneLabels.take(3).join(", ");
        print('Speaking scene results: $sceneText');
        await speak("This looks like $sceneText.");
      } else {
        print('Scene labels detected but confidence too low');
        await speak(
          "I can see the general scene but can't identify it clearly.",
        );
      }
    } catch (e) {
      print('Image labeling error: $e');
      await speak("I'm having trouble understanding the scene right now.");
    }
  }

  Future<void> _performTextRecognition(InputImage inputImage) async {
    try {
      print('Starting text recognition...');
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      print('Recognized text length: ${recognizedText.text.length}');
      print('Raw recognized text: "${recognizedText.text}"');

      if (recognizedText.text.isEmpty) {
        await speak("I don't see any text in this image.");
        return;
      }

      final cleanText = recognizedText.text.replaceAll('\n', ' ').trim();
      print('Clean text: "$cleanText"');

      if (cleanText.isNotEmpty) {
        print('Speaking text results: "$cleanText"');
        await speak("I can read: $cleanText");
      } else {
        await speak("I don't see any readable text here.");
      }
    } catch (e) {
      print('Text recognition error: $e');
      await speak("I'm having trouble reading any text right now.");
    }
  }

  // Official image conversion based on MLKit CameraView example
  InputImage? _convertCameraImageToInputImage(
      CameraImage image,
      CameraDescription cameraDescription,
      ) {
    try {
      print('Converting camera image:');
      print('- Format: ${image.format.group}');
      print('- Raw format: ${image.format.raw}');
      print('- Size: ${image.width}x${image.height}');
      print('- Planes: ${image.planes.length}');
      print('- Camera: ${cameraDescription.lensDirection}');
      print('- Sensor orientation: ${cameraDescription.sensorOrientation}');

      // Get image rotation (from official example)
      final sensorOrientation = cameraDescription.sensorOrientation;
      InputImageRotation? rotation;

      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        // For Android, we need device orientation compensation
        // Using portrait up as default since most usage is in portrait
        var rotationCompensation = 0; // DeviceOrientation.portraitUp

        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          // front-facing
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          // back-facing
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
        print('Rotation compensation: $rotationCompensation');
      }

      if (rotation == null) {
        print('Could not determine rotation');
        return null;
      }

      print('Final rotation: $rotation');

      // Get image format (from official example)
      final format = InputImageFormatValue.fromRawValue(image.format.raw);

      // Validate format depending on platform (from official example)
      if (format == null ||
          (Platform.isAndroid && format != InputImageFormat.nv21) ||
          (Platform.isIOS && format != InputImageFormat.bgra8888)) {
        print(
          'Unsupported format: $format for platform: ${Platform.operatingSystem}',
        );
        return null;
      }

      // Since format is constrained to nv21 or bgra8888, both only have one plane (from official example)
      if (image.planes.length != 1) {
        print('Expected 1 plane, got ${image.planes.length}');
        return null;
      }

      final plane = image.planes.first;
      print(
        'Using plane with ${plane.bytes.length} bytes, ${plane.bytesPerRow} bytes per row',
      );

      // Compose InputImage using bytes (from official example)
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation, // used only in Android
          format: format, // used only in iOS
          bytesPerRow: plane.bytesPerRow, // used only in iOS
        ),
      );

      print('Successfully created InputImage with official method');
      return inputImage;
    } catch (e, stackTrace) {
      print('Error converting camera image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}