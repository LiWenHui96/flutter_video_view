import 'package:flutter/material.dart';

import 'video_view_controller.dart';

/// @Describe: Widgets and notifiers used within the plugin.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/15

// ignore: public_member_api_docs
class VideoViewControllerInherited extends InheritedWidget {
  // ignore: public_member_api_docs
  const VideoViewControllerInherited({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  // ignore: public_member_api_docs
  final VideoViewController controller;

  @override
  bool updateShouldNotify(covariant VideoViewControllerInherited oldWidget) =>
      controller != oldWidget.controller;
}

// ignore: public_member_api_docs
abstract class BaseState<T extends StatefulWidget> extends State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

// ignore: public_member_api_docs
abstract class BaseNotifier extends ChangeNotifier {
  bool _isInitializing = false;

  /// Whether initializing.
  bool get isInitializing => _isInitializing;

  set isInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

  /// After preventing the page from being destroyed, the asynchronous task is
  /// completed, resulting in an error.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}

/// Calculate hours, minutes and seconds through Duration.
String formatDuration(Duration position) {
  final int ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  final int minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final String minutesString = minutes.toString().padLeft(2, '0');
  final String secondsString = seconds.toString().padLeft(2, '0');

  return '${hours == 0 ? '' : '$hours:'}$minutesString:$secondsString';
}
