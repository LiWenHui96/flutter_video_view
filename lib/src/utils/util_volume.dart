import 'package:volume_controller/volume_controller.dart';

/// @Describe: Volume
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/24

class VolumeUtil {
  // ignore: public_member_api_docs
  factory VolumeUtil() => _singleton;

  VolumeUtil._() {
    _volume = VolumeController();
  }

  late VolumeController _volume;

  static VolumeUtil? _instance;

  static final VolumeUtil _singleton = _instance ??= VolumeUtil._();

  /// This method get the current system volume.
  static Future<double> get current => _singleton._volume.getVolume();

  /// This method set the system volume between 0.0 to 1.0.
  static Future<void> setVolume(double volume) async {
    if (volume > 1) {
      volume = 1;
    } else if (volume < 0) {
      volume = 0;
    }

    _singleton._volume.setVolume(volume, showSystemUI: false);
  }
}
