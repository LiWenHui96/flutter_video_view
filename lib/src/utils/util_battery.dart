import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

/// @Describe: Battery
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/24

class BatteryUtil {
  // ignore: public_member_api_docs
  factory BatteryUtil() => _singleton;

  BatteryUtil._() {
    _battery = Battery();
  }

  late Battery _battery;

  static BatteryUtil? _instance;

  static final BatteryUtil _singleton = _instance ??= BatteryUtil._();

  /// Get the current battery information.
  static Future<void> getBattery({
    required Color foregroundColor,
    required Function(int batteryLevel, Color batteryColor) onBatteryCallback,
  }) async {
    final int current = await _singleton._battery.batteryLevel;

    Color batteryColor = foregroundColor;
    if (await _singleton._battery.isInBatterySaveMode) {
      batteryColor = Colors.orange.withOpacity(.8);
    } else {
      final BatteryState batteryState = await _singleton._battery.batteryState;
      switch (batteryState) {
        case BatteryState.full:
        case BatteryState.discharging:
        case BatteryState.unknown:
          batteryColor = foregroundColor.withOpacity(.4);
          break;
        case BatteryState.charging:
          batteryColor = Colors.green.withOpacity(.8);
          break;
      }
    }

    onBatteryCallback.call(current, batteryColor);
  }
}
