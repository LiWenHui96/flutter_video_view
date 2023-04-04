import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

import 'utils/utils.dart';
import 'video_view_localizations.dart';

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

  /// The current volume.
  double? _lastVolume;

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
    if (startTimer) {
      resetSeconds();
    } else {
      _currentSeconds = hideSeconds + 1;
    }

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

  /// Mute or not.
  void onMute() {
    if (canUse) {
      if (value.volume == 0) {
        controller.setVolume(_lastVolume ?? .5);
      } else {
        _lastVolume = value.volume;
        controller.setVolume(0);
      }

      showOrHide(visible: true);
    }
  }

  /// Fullscreen or not.
  void onFullScreen() {
    if (canUse) {
      _currentSeconds = 0;
      controller.setFullScreen(!value.isFullScreen);
    }
  }

  /// Start [hideTimer].
  @protected
  void startHideTimer() {
    hideTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (timer.isActive && value.isVisible) {
        if (_currentSeconds == hideSeconds) {
          controller.setVisible(false);
          resetSeconds();
        } else if (_currentSeconds < hideSeconds) {
          _currentSeconds++;
        }
      }
    });
  }

  /// Reset seconds.
  void resetSeconds() {
    _currentSeconds = 0;
  }

  /// PlayButton
  @protected
  Widget buildPlayButtonWidget() {
    if (!value.status.isSuccess ||
        value.isDragProgress ||
        value.isVerticalDrag ||
        value.isLock) {
      return const SizedBox.shrink();
    }

    final Widget child = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.35),
        shape: BoxShape.circle,
      ),
      child: AnimatedPlayPause(
        isPlaying: value.isPlaying,
        color: config.foregroundColor,
        onPressed: playOrPause,
      ),
    );

    return Center(
      child: config.centerPlayButtonBuilder?.call(playOrPause) ?? child,
    );
  }

  /// A widget that shows when playback is complete.
  @protected
  Widget buildFinishWidget() {
    Widget child = Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.85),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: playOrPause,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );

    child = Container(
      color: config.tooltipBackgroundColor,
      child: SafeArea(
        top: value.isPortrait && value.isFullScreen,
        bottom: false,
        child: Stack(children: <Widget>[kBackButton(), child]),
      ),
    );

    return config.finishBuilder?.call(context, value.isFullScreen) ?? child;
  }

  /// A Widget that is shown when the maximum preview duration is reached.
  @protected
  Widget buildMaxPreviewWidget() {
    final Widget child = Container(
      alignment: Alignment.topLeft,
      color: Colors.black,
      child: SafeArea(
        top: value.isPortrait && value.isFullScreen,
        bottom: false,
        child: kBackButton(),
      ),
    );

    return config.maxPreviewTimeBuilder?.call(context, value.isFullScreen) ??
        child;
  }

  /// Called when a long press gesture with a primary button has been
  /// recognized.
  @protected
  void onLongPressStart(LongPressStartDetails details) {
    if (canUse &&
        config.canLongPress &&
        value.isPlaying &&
        value.playbackSpeed < controller.maxPlaybackSpeed) {
      showOrHide(visible: false);

      controller
        ..setMaxPlaybackSpeed(true)
        ..setPlaybackSpeed();
    }
  }

  /// A pointer that has triggered a long-press with a primary button has
  /// stopped contacting the screen.
  @protected
  void onLongPressEnd(LongPressEndDetails details) {
    if (value.isMaxPlaybackSpeed) {
      controller
        ..setMaxPlaybackSpeed(false)
        ..setPlaybackSpeed(speed: 1);
    }
  }

  /// A pointer has contacted the screen with a primary button and has begun to
  /// move vertically.
  @protected
  Future<void> onVerticalDragStart(DragStartDetails details) async {
    if (canUse && config.canChangeVolumeOrBrightness) {
      controller
        ..setVerticalDrag(true)
        ..setVerticalDragType(
          details.globalPosition.dx < totalWidth / 2
              ? VerticalDragType.brightness
              : VerticalDragType.volume,
        );

      double currentValue = 0;
      if (value.verticalDragType == VerticalDragType.brightness) {
        currentValue = await ScreenBrightnessUtil.current;
      } else if (value.verticalDragType == VerticalDragType.volume) {
        currentValue = await VolumeUtil.current;
      }
      controller.setVerticalDragValue(currentValue);
    }
  }

  /// A pointer that is in contact with the screen with a primary button and
  /// moving vertically has moved in the vertical direction.
  @protected
  Future<void> onVerticalDragUpdate(DragUpdateDetails details) async {
    if (canUse && value.isVerticalDrag) {
      controller.setVerticalDragValue(
        value.verticalDragValue - (details.delta.dy / totalHeight),
      );

      if (value.verticalDragType == VerticalDragType.brightness) {
        await ScreenBrightnessUtil.setScreenBrightness(value.verticalDragValue);
      } else if (value.verticalDragType == VerticalDragType.volume) {
        await VolumeUtil.setVolume(value.verticalDragValue);
      }
    }
  }

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving vertically is no longer in contact with the screen and
  /// was moving at a specific velocity when it stopped contacting the screen.
  @protected
  void onVerticalDragEnd(DragEndDetails details) {
    if (value.isVerticalDrag) {
      controller.setVerticalDrag(false);
    }
  }

  /// A pointer has contacted the screen with a primary button and has begun to
  /// move horizontally.
  @protected
  void onHorizontalDragStart(DragStartDetails details) {
    if (canUse && config.canChangeProgress) {
      showOrHide(visible: true, startTimer: false);

      controller
        ..setDragProgress(true)
        ..setDragDuration(value.position);
    }
  }

  /// A pointer that is in contact with the screen with a primary button and
  /// moving horizontally has moved in the horizontal direction.
  @protected
  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (canUse && value.isDragProgress) {
      final double relative = details.delta.dx / totalWidth;
      controller.setDragDuration(
        value.dragDuration + value.dragTotalDuration * relative,
      );
    }
  }

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving horizontally is no longer in contact with the screen and
  /// was moving at a specific velocity when it stopped contacting the screen.
  @protected
  void onHorizontalDragEnd(DragEndDetails details) {
    if (value.isDragProgress) {
      showOrHide(visible: true);

      controller
        ..setDragProgress(false)
        ..seekTo(value.dragDuration);
    }
  }

  /// The callback event before dragging the progress bar to adjust the
  /// progress.
  @protected
  void onDragStart(DragStartDetails details) {
    if (canUse) {
      controller.setDragProgress(true);
      showOrHide(visible: true, startTimer: false);
    }
  }

  /// The callback event during dragging the progress bar to adjust the
  /// progress.
  @protected
  void onDragUpdate(double relative) {
    if (canUse && value.isDragProgress) {
      controller.setDragDuration(value.duration * relative);
    }
  }

  /// The callback event after dragging the progress bar to adjust the progress.
  @protected
  void onDragEnd(DragEndDetails details) {
    if (value.isDragProgress) {
      controller
        ..setDragProgress(false)
        ..seekTo(value.dragDuration);
      showOrHide(visible: true);
    }
  }

  /// Click on the progress bar to change the progress of the video.
  void onTapUp(double relative) {
    if (canUse) {
      controller
        ..setDragDuration(value.duration * relative)
        ..seekTo(value.dragDuration);
    }
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

  /// The horizontal extent of this size.
  double get totalWidth =>
      (context.size?.width ?? MediaQuery.of(context).size.width).ceilToDouble();

  /// The vertical extent of this size.
  double get totalHeight =>
      (context.size?.height ?? MediaQuery.of(context).size.height)
          .ceilToDouble();

  /// Whether the operation can be performed.
  bool get canUse =>
      !value.isLock && value.isInitialized && value.status.isSuccess;

  /// The style of all text.
  TextStyle get defaultStyle =>
      TextStyle(fontSize: config.textSize, color: config.foregroundColor);

  /// Time to hide the controller.
  int get hideSeconds => config.hideControlsTimer.inSeconds;

  // ignore: public_member_api_docs
  VideoLocalizations get local => VideoLocalizations.of(context);

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
