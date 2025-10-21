import 'dart:ui';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectorService {
  static final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  static Future<List<DetectedObject>> detectObjects(
      InputImage inputImage) async {
    try {
      print('🔍 Starting object detection...');
      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);
      print('✅ Objects detected: ${objects.length}');

      for (var i = 0; i < objects.length; i++) {
        final obj = objects[i];
        if (obj.labels.isNotEmpty) {
          final label = obj.labels.first;
          print(
              '   Object $i: ${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%)');
        }
      }

      return objects;
    } catch (e) {
      print('❌ Error detecting objects: $e');
      return [];
    }
  }

  static void dispose() {
    _objectDetector.close();
  }

  // Filter for important objects we care about
  static List<DetectedObject> filterImportantObjects(
      List<DetectedObject> objects) {
    final filtered = objects.where((object) {
      if (object.labels.isEmpty) return false;

      final label = object.labels.first.text.toLowerCase();
      final confidence = object.labels.first.confidence;

      // Only return objects with good confidence
      final isImportant = (label.contains('person') ||
              label.contains('car') ||
              label.contains('vehicle') ||
              label.contains('truck') ||
              label.contains('bicycle')) &&
          confidence > 0.3;

      if (isImportant) {
        print(
            '🎯 IMPORTANT: $label (${(confidence * 100).toStringAsFixed(1)}%)');
      }

      return isImportant;
    }).toList();

    print(
        '📊 Filtered ${objects.length} objects down to ${filtered.length} important ones');
    return filtered;
  }

  // Get distance estimation based on bounding box size
  static String estimateDistance(Rect boundingBox, Size imageSize) {
    final boxArea = boundingBox.width * boundingBox.height;
    final imageArea = imageSize.width * imageSize.height;
    final coverage = boxArea / imageArea;

    if (coverage > 0.3) return 'very close';
    if (coverage > 0.15) return 'close';
    if (coverage > 0.05) return 'medium distance';
    return 'far';
  }
}
