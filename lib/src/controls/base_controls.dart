import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/inside.dart';
import 'package:flutter_video_view/src/local/video_view_localizations.dart';
import 'package:flutter_video_view/src/notifier/controls_notifier.dart';
import 'package:flutter_video_view/src/notifier/video_view_notifier.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:flutter_video_view/src/video_view_controller.dart';

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

  /// The height of the action bar.
  final double barHeight = 48;

  /// Manipulate the default hide time of the widget.
  final Duration defaultHideDuration = const Duration(milliseconds: 300);

  @override
  void didChangeDependencies() {
    final VideoViewController? oldController = _videoViewController;
    _videoViewController = VideoViewController.of(context);
    _videoPlayerController = videoViewController.videoPlayerController;
    _videoViewConfig = videoViewController.viewConfig;
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
    _videoPlayerController.addListener(_updateState);
    _updateState();

    initialize();
  }

  void _dispose() {
    _videoPlayerController.removeListener(_updateState);

    destruction();
  }

  void _updateState() {
    setState(() => _videoPlayerValue = _videoPlayerController.value);

    /// When the initialization is unsuccessful and the video playback error
    /// occurs, and the controller is in the displayed state, the controller
    /// is hidden.
    if (controlsNotifier.isVisible &&
        !videoPlayerValue.isInitialized &&
        videoPlayerValue.hasError) {
      controlsNotifier.isVisible = false;
    }
  }

  /// Initialization methods that can be used externally.
  @protected
  Future<void> initialize() async {}

  /// Destruction methods that can be used externally.
  @protected
  Future<void> destruction() async {}

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
          if (videoPlayerValue.position >= videoPlayerValue.duration) {
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
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  // ignore: public_member_api_docs
  bool get canUse =>
      !(controlsNotifier.isLock && !videoPlayerValue.isInitialized);

  // ignore: public_member_api_docs
  VideoViewLocalizations get local => VideoViewLocalizations.of(context);

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
