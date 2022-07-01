import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:flutter_video_view/src/widgets/base_state.dart';

/// @Describe: Base for VideoViewControls.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

abstract class BaseVideoViewControls<T extends StatefulWidget>
    extends BaseState<T> {
  VideoViewController? _videoViewController;
  late VideoViewValue _videoViewValue;
  late VideoViewConfig _videoViewConfig;

  /// Timer
  Timer? hideTimer;

  /// Manipulate the default hide time of the widget.
  final Duration defaultDuration = const Duration(milliseconds: 300);

  @override
  void didChangeDependencies() {
    final VideoViewController? oldController = _videoViewController;
    _videoViewController = VideoViewController.of(context);
    _videoViewValue = videoViewController.value;
    _videoViewConfig = videoViewValue.videoViewConfig;

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
    _videoViewController?.addListener(_updateState);

    initialize();
  }

  void _dispose() {
    _videoViewController?.removeListener(_updateState);
  }

  void _updateState() {
    setState(() => _videoViewValue = videoViewController.value);

    SystemChrome.setSystemUIChangeCallback(
        (bool systemOverlaysAreVisible) async {
      if (!systemOverlaysAreVisible && videoViewValue.isFullScreen) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: videoViewConfig.systemOverlaysEnterFullScreen ??
              <SystemUiOverlay>[],
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
    hideTimer?.cancel();

    videoViewController.setVisible(
      isVisible: visible ?? !videoViewValue.isVisible,
    );
    if (videoViewValue.isVisible && startTimer) {
      startHideTimer();
    }
  }

  /// Play or pause video.
  @protected
  void playOrPause() {
    if (canUse) {
      if (videoViewValue.isPlaying) {
        showOrHide(visible: true, startTimer: false);
        videoViewController.pause();
      } else {
        showOrHide(visible: true);
        if (videoViewValue.position >= videoViewValue.duration) {
          videoViewController.seekTo(Duration.zero);
        }
        videoViewController.play();
      }
    }
  }

  /// Start [hideTimer].
  @protected
  void startHideTimer() {
    hideTimer = Timer(
      videoViewConfig.hideControlsTimer,
      () => videoViewController.setVisible(isVisible: false),
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
      !videoViewValue.isLock &&
      videoViewValue.isInitialized &&
      videoViewValue.videoInitState == VideoInitState.success;

  /// The style of all text.
  TextStyle get defaultStyle => TextStyle(
        fontSize: videoViewConfig.defaultTextSize,
        color: videoViewConfig.foregroundColor,
      );

  // ignore: public_member_api_docs
  VideoViewController get videoViewController => _videoViewController!;

  // ignore: public_member_api_docs
  VideoViewValue get videoViewValue => _videoViewValue;

  // ignore: public_member_api_docs
  VideoViewConfig get videoViewConfig => _videoViewConfig;
}
