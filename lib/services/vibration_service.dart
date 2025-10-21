import 'package:vibration/vibration.dart';

class VibrationService {
  static Future<void> vibrateWarning() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }
  }

  static Future<void> vibrateDanger() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }
  }

  static Future<void> vibratePulse() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 100);
    }
  }
}
