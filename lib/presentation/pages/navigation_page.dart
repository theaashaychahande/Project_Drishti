import 'package:flutter/material.dart';
import 'package:vision_guide/services/camera_service.dart';
import 'package:vision_guide/services/tts_service.dart';
import 'package:vision_guide/services/vibration_service.dart';
import 'package:vision_guide/presentation/widgets/camera_view.dart';
import 'package:vision_guide/services/object_detector_service.dart';
import 'package:vision_guide/services/ocr_service.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  bool _isLoading = true;
  String _status = "Initializing camera...";

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize TTS
      await TtsService.initialize();
      await TtsService.speak("Initializing camera. Please wait.");

      // Initialize REAL camera
      final cameraInitialized = await CameraService.initializeCamera();

      if (cameraInitialized && CameraService.isInitialized) {
        setState(() {
          _isLoading = false;
          _status = "Camera ready. Point at your surroundings.";
        });
        await TtsService.speak(
            "Camera ready. Point your phone forward to detect obstacles.");
      } else {
        setState(() {
          _status = "Camera permission denied";
        });
        await TtsService.speak(
            "Camera permission denied. Please enable camera access.");
      }
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
      await TtsService.speak("Error initializing camera.");
    }
  }

  @override
  void dispose() {
    CameraService.dispose();
    ObjectDetectorService.dispose(); // ADD THIS
    OcrService.dispose(); // ADD THIS
    TtsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Go back to home screen',
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Vision Guide - Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Camera preview or loading
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 20),
                          Text(
                            _status,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : CameraView(), // REAL CAMERA PREVIEW
            ),

            // Status bar
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Semantics(
                    button: true,
                    label: 'Test voice feedback',
                    child: ElevatedButton(
                      onPressed: () {
                        TtsService.speak(
                            "Voice feedback working. Camera is active.");
                      },
                      child: Text('TEST VOICE'),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Test vibration alert',
                    child: ElevatedButton(
                      onPressed: () {
                        VibrationService.vibrateWarning();
                      },
                      child: Text('TEST VIBRATION'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
