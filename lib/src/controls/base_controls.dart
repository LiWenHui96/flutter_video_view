import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/src/notifier/controls_notifier.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:flutter_video_view/src/widgets/base_state.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/// @Describe: Base for VideoViewControls.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

abstract class BaseVideoViewControls<T extends StatefulWidget>
    extends BaseState<T> {
  VideoViewController? _videoViewController;
  late VideoPlayerController _videoPlayerController;
  late VideoPlayerValue _videoPlayerValue;
  late VideoViewConfig _videoViewConfig;
  late ControlsNotifier _controlsNotifier;

  /// Timer
  Timer? hideTimer;

  /// The current playback position.
  Duration currentDuration = Duration.zero;

  /// The total duration of the video.
  Duration totalDuration = Duration.zero;

  /// The maximum interval for adjusting the duration.
  Duration dragDuration = Duration.zero;

  /// The height of the action bar.
  final double barHeight = 48;

  /// Manipulate the default hide time of the widget.
  final Duration defaultHideDuration = const Duration(milliseconds: 300);

  @override
  void didChangeDependencies() {
    final VideoViewController? oldController = _videoViewController;
    _videoViewController = VideoViewController.of(context);
    _videoPlayerController = videoViewController.videoPlayerController;
    _videoViewConfig = videoViewController.videoViewConfig;
    _controlsNotifier = context.watch<ControlsNotifier>();

    if (oldController != _videoViewController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    hideTimer?.cancel();

    _dispose();
    super.dispose();
  }

  void _initialize() {
    /// Update data.
    _updateState();
    _videoPlayerController.addListener(_updateState);

    initialize();
  }

  void _dispose() {
    _videoPlayerController.removeListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _videoPlayerValue = _videoPlayerController.value;
      if (!videoPlayerValue.hasError) {
        currentDuration = videoPlayerValue.position;
        totalDuration = videoPlayerValue.duration;
        dragDuration = _setDragDuration(totalDuration);
      }
    });

    SystemChrome.setSystemUIChangeCallback(
        (bool systemOverlaysAreVisible) async {
      if (!systemOverlaysAreVisible && videoViewController.isFullScreen) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: videoViewConfig.systemOverlaysEnterFullScreen ??
              <SystemUiOverlay>[],
        );
      }
    });

    /// When the initialization is unsuccessful and the video playback error
    /// occurs, and the controller is in the displayed state, the controller
    /// is hidden.
    if (controlsNotifier.isVisible &&
        !videoPlayerValue.isInitialized &&
        videoPlayerValue.hasError) {
      controlsNotifier.isVisible = false;
    }
  }

  /// Set the sliding time interval.
  Duration _setDragDuration(Duration duration) {
    if (duration < const Duration(minutes: 1)) {
      return const Duration(seconds: 10);
    } else if (duration < const Duration(minutes: 10)) {
      return const Duration(minutes: 1);
    } else if (duration < const Duration(minutes: 30)) {
      return const Duration(minutes: 5);
    } else if (duration < const Duration(hours: 1)) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 15);
    }
  }

  /// Initialization methods that can be used externally.
  @protected
  Future<void> initialize() async {}

  /// Change the state of the controller so that it can be shown or hidden.
  @protected
  void showOrHide({bool? visible, bool startTimer = true}) {
    hideTimer?.cancel();

    controlsNotifier.isVisible = visible ?? !controlsNotifier.isVisible;
    if (controlsNotifier.isVisible && startTimer) {
      startHideTimer();
    }
  }

  /// Play or pause video.
  @protected
  void playOrPause() {
    if (canUse) {
      if (videoPlayerValue.isPlaying) {
        showOrHide(visible: true, startTimer: false);
        videoViewController.pause();
      } else {
        showOrHide(visible: true);

        if (videoPlayerValue.isInitialized) {
          if (currentDuration >= totalDuration) {
            videoViewController.seekTo(Duration.zero);
          }
          videoViewController.play();
        } else {
          videoViewController
              .initialize()
              .then((_) => videoViewController.play());
        }
      }
    }
  }

  /// Start [hideTimer].
  @protected
  void startHideTimer() {
    hideTimer = Timer(
      videoViewConfig.hideControlsTimer,
      () => controlsNotifier.isVisible = false,
    );
  }

  /// External package for volume and brightness, etc.
  @protected
  Widget tipWidget({Widget? child}) {
    if (child == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: videoViewConfig.tipBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  /// Whether the operation can be performed.
  bool get canUse =>
      !controlsNotifier.isLock &&
      videoPlayerValue.isInitialized &&
      videoViewController.videoInitState == VideoInitState.success;

  // ignore: public_member_api_docs
  VideoViewController get videoViewController => _videoViewController!;

  // ignore: public_member_api_docs
  VideoPlayerController get videoPlayerController => _videoPlayerController;

  // ignore: public_member_api_docs
  VideoPlayerValue get videoPlayerValue => _videoPlayerValue;

  // ignore: public_member_api_docs
  VideoViewConfig get videoViewConfig => _videoViewConfig;

  // ignore: public_member_api_docs
  ControlsNotifier get controlsNotifier => _controlsNotifier;
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
