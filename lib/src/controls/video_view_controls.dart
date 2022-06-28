import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/local/video_view_localizations.dart';
import 'package:flutter_video_view/src/utils/util_brightness.dart';
import 'package:flutter_video_view/src/utils/util_volume.dart';
import 'package:flutter_video_view/src/widgets/base_state.dart';

import 'base_controls.dart';
import 'controls_bottom.dart';
import 'controls_center.dart';
import 'controls_top.dart';

/// @Describe: The controls of video.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/23

class VideoViewControls extends StatefulWidget {
  // ignore: public_member_api_docs
  const VideoViewControls({Key? key}) : super(key: key);

  @override
  State<VideoViewControls> createState() => _VideoViewControlsState();
}

class _VideoViewControlsState extends BaseVideoViewControls<VideoViewControls> {
  @override
  Widget build(BuildContext context) {
    Widget child = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            if (!controlsNotifier.isLock) const ControlsTop(),
            const Spacer(),
            if (!controlsNotifier.isLock) const ControlsBottom(),
          ],
        ),
        if (videoPlayerValue.isBuffering)
          videoViewConfig.bufferingPlaceholder ??
              const CircularProgressIndicator(),
        if (videoViewController.isFullScreen) const ControlsCenter(),
      ],
    );

    child = AbsorbPointer(
      absorbing: !controlsNotifier.isVisible,
      child: AnimatedOpacity(
        opacity: controlsNotifier.isVisible ? 1.0 : .0,
        duration: defaultHideDuration,
        child: child,
      ),
    );

    child = GestureDetector(
      onTap: showOrHide,
      onDoubleTap: playOrPause,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    if (!videoPlayerValue.isLooping &&
        totalDuration != Duration.zero &&
        currentDuration >= totalDuration) {
      return videoViewConfig.finishBuilder
              ?.call(context, videoViewController.isFullScreen) ??
          Container(
            color: videoViewConfig.tipBackgroundColor,
            child: Stack(
              children: <Widget>[
                if (Navigator.canPop(context))
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    color: foregroundColor,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () async => Navigator.maybePop(context),
                  ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        onPressed: playOrPause,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[tipWidget(), child],
    );
  }

  @override
  Future<void> initialize() async {
    if (videoPlayerValue.isPlaying || videoViewConfig.autoPlay) {
      startHideTimer();
    }

    if (videoViewConfig.showControlsOnInitialize) {
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        () => showOrHide(visible: true),
      );
    }
  }

  @override
  Widget tipWidget({Widget? child}) {
    if (controlsNotifier.isMaxSpeed) {
      child = _MaxSpeedPlay(
        size: videoViewConfig.defaultIconSize,
        color: foregroundColor,
      );
    }
    if (controlsNotifier.isVerticalDrag) {
      child = _ViewProgressIndicator(
        value: controlsNotifier.currentValue,
        isDragLeft: controlsNotifier.isVerticalDragLeft,
        size: videoViewConfig.defaultIconSize,
        color: foregroundColor,
      );
    }
    if (controlsNotifier.isDragProgress) {
      child = Text(
        '${formatDuration(controlsNotifier.dragDuration)} / ${formatDuration(totalDuration)}',
        style: TextStyle(
          fontSize: videoViewConfig.defaultTextSize,
          color: foregroundColor,
        ),
      );
    }
    return super.tipWidget(child: child);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (videoViewConfig.canLongPress &&
        canUse &&
        videoPlayerValue.isPlaying &&
        videoPlayerValue.playbackSpeed < videoViewController.maxSpeed) {
      controlsNotifier.isMaxSpeed = true;
      videoViewController.setPlaybackSpeed();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (controlsNotifier.isMaxSpeed) {
      controlsNotifier.isMaxSpeed = false;
      videoViewController.setPlaybackSpeed(speed: 1);
    }
  }

  Future<void> _onVerticalDragStart(DragStartDetails details) async {
    if (videoViewConfig.canChangeVolumeOrBrightness && canUse) {
      controlsNotifier.isVerticalDragLeft =
          details.globalPosition.dx < totalWidth / 2;
      controlsNotifier.currentValue = controlsNotifier.isVerticalDragLeft
          ? await ScreenBrightnessUtil.current
          : await VolumeUtil.current;
      controlsNotifier.isVerticalDrag = true;
    }
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (canUse && controlsNotifier.isVerticalDrag) {
      controlsNotifier.currentValue =
          controlsNotifier.currentValue - (details.delta.dy / totalHeight);
      controlsNotifier.isVerticalDragLeft
          ? await ScreenBrightnessUtil.setScreenBrightness(
              controlsNotifier.currentValue,
            )
          : VolumeUtil.setVolume(controlsNotifier.currentValue);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (controlsNotifier.isVerticalDrag) {
      controlsNotifier.isVerticalDrag = false;
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (videoViewConfig.canChangeProgress && canUse) {
      controlsNotifier.isDragProgress = true;
      controlsNotifier.dragDuration = videoPlayerValue.position;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (canUse && controlsNotifier.isDragProgress) {
      final double relative = details.delta.dx / totalWidth;
      controlsNotifier.setDragDuration(
        controlsNotifier.dragDuration + dragDuration * relative,
        totalDuration,
      );
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (controlsNotifier.isDragProgress) {
      controlsNotifier.isDragProgress = false;
      videoViewController.seekTo(controlsNotifier.dragDuration);
    }
  }

  double get totalWidth =>
      (context.size?.width ?? MediaQuery.of(context).size.width).ceilToDouble();

  double get totalHeight =>
      (context.size?.height ?? MediaQuery.of(context).size.height)
          .ceilToDouble();

  Color get foregroundColor => videoViewConfig.foregroundColor;
}

class _MaxSpeedPlay extends StatefulWidget {
  // ignore: public_member_api_docs
  const _MaxSpeedPlay({Key? key, required this.size, required this.color})
      : super(key: key);

  /// The size of the icon.
  final double size;

  /// The color of the icon.
  final Color color;

  @override
  State<_MaxSpeedPlay> createState() => _MaxSpeedPlayState();
}

class _MaxSpeedPlayState extends BaseState<_MaxSpeedPlay>
    with SingleTickerProviderStateMixin {
  late Animation<int> animation;
  late AnimationController controller;

  int nowValue = 0;

  @override
  void initState() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    animation = IntTween(begin: 0, end: 2).animate(controller)
      ..addListener(() {
        setState(() => nowValue = animation.value);
      });
    controller.repeat();

    super.initState();
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        setIcon(nowValue + 2),
        setIcon(nowValue + 1),
        setIcon(nowValue),
        const SizedBox(width: 5),
        Text(local.speedPlay, style: TextStyle(color: widget.color)),
      ],
    );
  }

  Icon setIcon(int value) {
    Color color = Colors.white;
    if (value == 1) {
      color = Colors.white.withOpacity(.7);
    } else if (value == 2) {
      color = Colors.white.withOpacity(.3);
    }

    return Icon(Icons.play_arrow_rounded, size: widget.size, color: color);
  }

  VideoViewLocalizations get local => VideoViewLocalizations.of(context);
}

class _ViewProgressIndicator extends StatelessWidget {
  // ignore: public_member_api_docs
  const _ViewProgressIndicator({
    Key? key,
    required this.value,
    required this.isDragLeft,
    required this.color,
    required this.size,
    this.height = 6,
  }) : super(key: key);

  /// If non-null, the value of this progress indicator.
  final double value;

  /// Is it volume or brightness.
  final bool isDragLeft;

  /// The color of the icon.
  final Color color;

  /// The size of the icon.
  final double size;

  /// The height of this progress indicator.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: size, color: color),
        const SizedBox(width: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            width: height * 20,
            height: height,
            child: LinearProgressIndicator(
              value: value,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(.5),
              minHeight: height,
            ),
          ),
        ),
      ],
    );
  }

  /// Icon
  IconData get icon {
    final List<IconData> list = isDragLeft ? brightnessIcons : volumeIcons;
    if (value <= 0) {
      return list[0];
    } else if (value < .5) {
      return list[1];
    } else {
      return list[2];
    }
  }

  /// Icon for volume.
  List<IconData> get volumeIcons => <IconData>[
        Icons.volume_mute_rounded,
        Icons.volume_down_rounded,
        Icons.volume_up_rounded,
      ];

  /// Icon for brightness.
  List<IconData> get brightnessIcons => <IconData>[
        Icons.brightness_low_rounded,
        Icons.brightness_medium_rounded,
        Icons.brightness_high_rounded,
      ];
}
