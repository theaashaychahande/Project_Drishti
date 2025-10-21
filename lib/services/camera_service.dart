import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static late CameraController _controller;
  static bool _isInitialized = false;
  static StreamController<CameraImage>? _imageStreamController;

  static Future<bool> initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return false;
      }

      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();
      _isInitialized = true;

      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  static CameraController get controller {
    if (!_isInitialized) {
      throw Exception('Camera not initialized');
    }
    return _controller;
  }

  static bool get isInitialized => _isInitialized;

  static Stream<CameraImage> get cameraImageStream {
    if (!_isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_imageStreamController != null && !(_imageStreamController!.isClosed)) {
      return _imageStreamController!.stream;
    }

    _imageStreamController = StreamController<CameraImage>.broadcast();

    if (!_controller.value.isStreamingImages) {
      _controller.startImageStream((CameraImage image) {
        final controller = _imageStreamController;
        if (controller != null && !controller.isClosed) {
          controller.add(image);
        }
      });
    }

    return _imageStreamController!.stream;
  }

  static Future<void> stopImageStream() async {
    try {
      if (_controller.value.isStreamingImages) {
        await _controller.stopImageStream();
      }
    } catch (_) {}

    if (_imageStreamController != null) {
      await _imageStreamController!.close();
      _imageStreamController = null;
    }
  }

  static Future<void> dispose() async {
    if (_isInitialized) {
      await stopImageStream();
      await _controller.dispose();
      _isInitialized = false;
    }
  }
}
