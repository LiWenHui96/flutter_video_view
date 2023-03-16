import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

/// @Describe: Base for VideoControls.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/2

abstract class BaseVideoControls<T extends StatefulWidget>
    extends BaseState<T> {
  VideoController? _controller;
  late VideoValue _value;
  late VideoConfig _config;

  /// Timer
  Timer? hideTimer;

  /// Whether the loading is successful.
  bool _isSuccess = false;

  /// The current number of seconds.
  int _currentSeconds = 0;

  @override
  void didChangeDependencies() {
    final VideoController? oldController = _controller;
    _controller = VideoController.of(context);
    _value = controller.value;
    _config = value.config;

    if (oldController != _controller) {
      _dispose();
      _didChangeDependencies();
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    hideTimer = null;
    _dispose();

    super.dispose();
  }

  void _didChangeDependencies() {
    /// Update data.
    _updateState();
    _controller?.addListener(_updateState);

    initialize();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
  }

  void _updateState() {
    setState(() => _value = controller.value);

    if (value.status.isSuccess && !_isSuccess) {
      _isSuccess = true;
      startHideTimer();
    }

    SystemChrome.setSystemUIChangeCallback((_) async {
      if (!_ && value.isFullScreen) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: <SystemUiOverlay>[],
        );
      }
    });
  }

  /// Initialization methods that can be used externally.
  @protected
  Future<void> initialize() async {}

  /// Change the state of the controller so that it can be shown or hidden.
  @protected
  void showOrHide({bool? visible, bool startTimer = true}) {
    controller.setVisible(visible ?? !value.isVisible);
  }

  /// Play or pause video.
  @protected
  void playOrPause() {
    if (canUse) {
      if (value.isPlaying) {
        showOrHide(visible: true, startTimer: false);
        controller.pause();
      } else {
        showOrHide(visible: true);
        if (value.position >= value.duration) {
          controller.seekTo(Duration.zero);
        }
        controller.play();
      }
    }
  }

  /// Start [hideTimer].
  @protected
  void startHideTimer() {
    hideTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (timer.isActive && value.isVisible) {
        final int hideSeconds = config.hideControlsTimer.inSeconds;

        if (_currentSeconds == hideSeconds) {
          controller.setVisible(false);
          _currentSeconds = 0;
        } else {
          _currentSeconds++;
        }
      }
    });
  }

  /// Reset seconds.
  void resetSeconds() {
    _currentSeconds = 0;
  }

  /// External package for volume and brightness, etc.
  @protected
  Widget tooltipWidget({
    Widget? child,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? margin,
  }) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: alignment ?? Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: config.tooltipBackgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        margin: margin,
        child: child,
      ),
    );
  }

  /// Back Button.
  @protected
  Widget kBackButton() {
    return IconButton(
      iconSize: config.iconSize,
      color: config.foregroundColor,
      onPressed: () async => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_ios),
    );
  }

  /// Whether the operation can be performed.
  bool get canUse =>
      !value.isLock && value.isInitialized && value.status.isSuccess;

  /// The style of all text.
  TextStyle get defaultStyle =>
      TextStyle(fontSize: config.textSize, color: config.foregroundColor);

  // ignore: public_member_api_docs
  VideoController get controller => _controller!;

  // ignore: public_member_api_docs
  VideoValue get value => _value;

  // ignore: public_member_api_docs
  VideoConfig get config => _config;
}

/// Manipulate the default hide time of the widget.
const Duration defaultDuration = Duration(milliseconds: 300);

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
