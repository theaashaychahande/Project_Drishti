import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<String> recognizeText(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error recognizing text: $e');
      return '';
    }
  }

  static void dispose() {
    _textRecognizer.close();
  }

  // Filter important text (signs, labels)
  static String filterImportantText(String fullText) {
    if (fullText.isEmpty) return '';

    final lines = fullText.split('\n');
    final importantLines = lines.where((line) {
      final cleanLine = line.trim().toLowerCase();
      return cleanLine.contains('stop') ||
          cleanLine.contains('walk') ||
          cleanLine.contains('exit') ||
          cleanLine.contains('entrance') ||
          cleanLine.contains('danger') ||
          cleanLine.contains('warning') ||
          cleanLine.contains('caution') ||
          cleanLine.length <= 25; // Short texts are likely signs
    }).toList();

    return importantLines.join(', ');
  }
}
