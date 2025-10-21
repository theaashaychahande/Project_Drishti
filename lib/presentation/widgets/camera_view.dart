import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:vision_guide/services/camera_service.dart';
import 'package:vision_guide/services/object_detector_service.dart';
import 'package:vision_guide/services/ocr_service.dart';
import 'package:vision_guide/services/tts_service.dart';
import 'package:vision_guide/services/vibration_service.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  List<DetectedObject> _detectedObjects = [];
  String _detectedText = '';
  Timer? _speechTimer;
  DateTime _lastSpeechTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startObjectDetection();
  }

  void _startObjectDetection() {
    CameraService.cameraImageStream.listen((CameraImage image) {
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      print('Processing image: ${image.width}x${image.height}');

      final BytesBuilder bytesBuilder = BytesBuilder();
      for (final Plane plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final bytes = bytesBuilder.toBytes();

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow:
              image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0,
        ),
      );

      print('Calling object detection...');
      final objects = await ObjectDetectorService.detectObjects(inputImage);
      print('Objects detected: ${objects.length}');

      final text = await OcrService.recognizeText(inputImage);
      print('Text detected: ${text.isNotEmpty ? "YES" : "NO"}');

      if (mounted) {
        setState(() {
          _detectedObjects =
              ObjectDetectorService.filterImportantObjects(objects);
          _detectedText = OcrService.filterImportantText(text);
        });

        // Debug: Print what we found
        if (_detectedObjects.isNotEmpty) {
          print('FILTERED OBJECTS:');
          for (var obj in _detectedObjects) {
            print(
                ' - ${obj.labels.map((e) => '${e.text} (${(e.confidence * 100).toStringAsFixed(1)}%)').toList()}');
          }
        }

        _announceDetections();
      }
    } catch (e) {
      print('Error processing image: $e');
    }
  }

  void _announceDetections() {
    final now = DateTime.now();
    // Only speak every 4 seconds to avoid spam
    if (now.difference(_lastSpeechTime).inSeconds < 4) return;

    String speech = '';
    List<String> objectAlerts = [];

    // Process objects
    for (final object in _detectedObjects.take(2)) {
      if (object.labels.isNotEmpty) {
        final label = object.labels.first.text;
        final confidence = object.labels.first.confidence;

        // Only announce high confidence detections
        if (confidence > 0.5) {
          final distance = ObjectDetectorService.estimateDistance(
            object.boundingBox,
            Size(
              CameraService.controller.value.previewSize!.height,
              CameraService.controller.value.previewSize!.width,
            ),
          );

          objectAlerts.add('$label $distance');

          // Vibrate for close objects
          if (distance == 'very close' || distance == 'close') {
            VibrationService.vibrateWarning();
          }
        }
      }
    }

    // Add object alerts to speech
    if (objectAlerts.isNotEmpty) {
      speech += 'Detected: ${objectAlerts.join(', ')}. ';
    }

    // Announce important text
    if (_detectedText.isNotEmpty) {
      speech += 'Sign: $_detectedText.';
    }

    if (speech.isNotEmpty) {
      _lastSpeechTime = now;
      TtsService.speak(speech);
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    CameraService.stopImageStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(CameraService.controller),

        // Object detection overlays
        ..._detectedObjects.map((object) {
          return CustomPaint(
            painter: ObjectPainter(
              object: object,
              imageSize: Size(
                CameraService.controller.value.previewSize!.height,
                CameraService.controller.value.previewSize!.width,
              ),
            ),
          );
        }).toList(),

        // Detection info panel
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objects: ${_detectedObjects.length}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (_detectedText.isNotEmpty)
                  Text(
                    'Text: $_detectedText',
                    style: TextStyle(color: Colors.yellow, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),

        // SIMPLE TEST BUTTON - FIXED VERSION
        Positioned(
          bottom: 100,
          right: 10,
          child: ElevatedButton(
            onPressed: () {
              // Test 1: Check if voice works
              TtsService.speak("Test voice is working!");

              // Test 2: Check if we can draw boxes - USE CORRECT CONSTRUCTOR
              setState(() {
                _detectedText = "TEST MODE ACTIVE";
                _detectedObjects = [
                  DetectedObject(
                    boundingBox: Rect.fromLTWH(100, 150, 250, 350),
                    labels: [],
                    trackingId: 1, // ADD THIS REQUIRED PARAMETER
                  )
                ];
              });
            },
            child: Text('TEST BOX'),
          ),
        ),
      ],
    );
  }
}

class ObjectPainter extends CustomPainter {
  final DetectedObject object;
  final Size imageSize;

  ObjectPainter({required this.object, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Thicker line

    try {
      // Convert bounding box coordinates to screen coordinates
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      final Rect scaledRect = Rect.fromLTRB(
        object.boundingBox.left * scaleX,
        object.boundingBox.top * scaleY,
        object.boundingBox.right * scaleX,
        object.boundingBox.bottom * scaleY,
      );

      // Draw the bounding box
      canvas.drawRect(scaledRect, paint);

      // Draw label if available, otherwise draw generic label
      String labelText = 'OBJECT';
      if (object.labels.isNotEmpty) {
        final label = object.labels.first;
        labelText =
            '${label.text} ${(label.confidence * 100).toStringAsFixed(0)}%';
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.red,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - 20));
    } catch (e) {
      print('Error in ObjectPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
