import 'package:event_bus/event_bus.dart';

/// @Describe: EventBus
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/30

class EventBusUtil {
  /// Factory mode
  factory EventBusUtil() => _singleton;

  EventBusUtil._() {
    _bus = EventBus();
  }

  late EventBus _bus;

  static EventBusUtil? _instance;

  static final EventBusUtil _singleton = _instance ??= EventBusUtil._();

  /// monitor
  static Stream<bool> onFullScreen() => _singleton._bus.on<bool>();

  /// trigger
  static void fireFullScreen({required bool isFullScreen}) =>
      _singleton._bus.fire(isFullScreen);
}
