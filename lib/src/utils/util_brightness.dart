import 'package:screen_brightness/screen_brightness.dart';

/// @Describe: ScreenBrightness
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/24

class ScreenBrightnessUtil {
  factory ScreenBrightnessUtil() => _singleton;

  ScreenBrightnessUtil._() {
    _brightness = ScreenBrightness();
  }

  late ScreenBrightness _brightness;

  static ScreenBrightnessUtil? _instance;

  static final ScreenBrightnessUtil _singleton =
      _instance ??= ScreenBrightnessUtil._();

  /// Returns current screen brightness which is current screen brightness
  /// value.
  static Future<double> get current => _singleton._brightness.current;

  /// Set screen brightness with double value.
  static Future<void> setScreenBrightness(double brightness) async {
    if (brightness > 1) {
      brightness = 1;
    } else if (brightness < 0) {
      brightness = 0;
    }

    await _singleton._brightness.setScreenBrightness(brightness);
  }

  /// Reset screen brightness with (Android)-1 or (iOS)system brightness value.
  static Future<void> resetScreenBrightness() =>
      _singleton._brightness.resetScreenBrightness();
}
