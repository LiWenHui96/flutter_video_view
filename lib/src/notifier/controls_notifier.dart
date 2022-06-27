import 'package:flutter/material.dart';

/// @Describe: The provider of a controls.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/23

class ControlsNotifier extends ChangeNotifier {
  bool _isVisible = false;

  /// Show or hide for VideoViewControls.
  bool get isVisible => _isVisible;

  set isVisible(bool value) {
    _isVisible = value;
    notifyListeners();
  }

  bool _isLock = false;

  /// Whether to lock the controller
  bool get isLock => _isLock;

  set isLock(bool value) {
    _isLock = value;
    notifyListeners();
  }

  bool _isMaxSpeed = false;

  /// Whether to play video at the maximum rate.
  bool get isMaxSpeed => _isMaxSpeed;

  set isMaxSpeed(bool value) {
    _isMaxSpeed = value;
    notifyListeners();
  }

  bool _isVerticalDragLeft = false;

  /// Whether to adjust brightness or volume.
  bool get isVerticalDragLeft => _isVerticalDragLeft;

  set isVerticalDragLeft(bool value) {
    _isVerticalDragLeft = value;
    notifyListeners();
  }

  bool _isVerticalDrag = false;

  /// Whether to display the adjustment progress of brightness or volume.
  bool get isVerticalDrag => _isVerticalDrag;

  set isVerticalDrag(bool value) {
    _isVerticalDrag = value;
    notifyListeners();
  }

  double _currentValue = 0;

  /// Brightness value or volume value.
  double get currentValue => _currentValue;

  set currentValue(double value) {
    _currentValue = value;
    notifyListeners();
  }

  bool _isDragProgress = false;

  /// Whether the progress is being adjusted.
  bool get isDragProgress => _isDragProgress;

  set isDragProgress(bool value) {
    _isDragProgress = value;
    notifyListeners();
  }

  Duration _dragDuration = Duration.zero;

  /// Adjusted progress value.
  Duration get dragDuration => _dragDuration;

  set dragDuration(Duration value) {
    _dragDuration = value;
    notifyListeners();
  }

  // ignore: public_member_api_docs
  void setDragDuration(Duration value, Duration totalDuration) {
    Duration duration = value;
    if (duration < Duration.zero) {
      duration = Duration.zero;
    } else if (duration > totalDuration) {
      duration = totalDuration;
    }
    dragDuration = duration;
  }
}
