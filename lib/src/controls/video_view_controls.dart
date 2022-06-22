import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/inside.dart';
import 'package:flutter_video_view/src/local/video_view_localizations.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import 'base_controls.dart';
import 'controls_bottom.dart';
import 'controls_center.dart';
import 'controls_top.dart';

/// @Describe: The controls of video.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

class VideoViewControls extends StatefulWidget {
  /// Externally provided
  const VideoViewControls({Key? key}) : super(key: key);

  @override
  State<VideoViewControls> createState() => _VideoViewControlsState();
}

class _VideoViewControlsState extends BaseVideoViewControls<VideoViewControls> {
  ScreenBrightness screenBrightness = ScreenBrightness();
  VolumeController volumeController = VolumeController();

  @override
  Widget build(BuildContext context) {
    Widget child = Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            if (!controlsNotifier.isLock) const ControlsTop(),
            const Spacer(),
            if (!controlsNotifier.isLock) const ControlsBottom(),
          ],
        ),
        if (videoViewController.isFullScreen)
          const Center(child: ControlsCenter()),
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
      Timer? timer;
      timer = Timer(const Duration(milliseconds: 300), () {
        controlsNotifier.isVisible = true;
        timer?.cancel();
      });
    }
  }

  @override
  Widget tipWidget({Widget? child}) {
    if (controlsNotifier.isMaxSpeed) {
      child = _MaxSpeedPlay(color: foregroundColor, local: local);
    }
    if (controlsNotifier.isVerticalDrag) {
      child = _ProgressIndicator(
        value: controlsNotifier.currentValue,
        isDragLeft: controlsNotifier.isVerticalDragLeft,
        color: foregroundColor,
      );
    }
    if (controlsNotifier.isDragProgress) {
      child = Text(
        '${formatDuration(controlsNotifier.dragDuration)} / ${formatDuration(videoPlayerValue.duration)}',
        style: TextStyle(fontSize: 14, color: foregroundColor),
      );
    }
    return super.tipWidget(child: child);
  }

  @override
  Future<void> destruction() async {
    await screenBrightness.resetScreenBrightness();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (canUse && videoPlayerValue.isPlaying) {
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
    if (canUse) {
      controlsNotifier.isVerticalDragLeft =
          details.globalPosition.dx < totalWidth / 2;
      controlsNotifier.currentValue = handleValue(
        controlsNotifier.isVerticalDragLeft
            ? await screenBrightness.current
            : await volumeController.getVolume(),
      );
      controlsNotifier.isVerticalDrag = true;
    }
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (canUse && controlsNotifier.isVerticalDrag) {
      controlsNotifier.currentValue = handleValue(
        controlsNotifier.currentValue - (details.delta.dy / totalHeight),
      );
      controlsNotifier.isVerticalDragLeft
          ? await screenBrightness
              .setScreenBrightness(controlsNotifier.currentValue)
          : volumeController.setVolume(
              controlsNotifier.currentValue,
              showSystemUI: false,
            );
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (controlsNotifier.isVerticalDrag) {
      controlsNotifier.isVerticalDrag = false;
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (canUse) {
      controlsNotifier.isDragProgress = true;
      controlsNotifier.dragDuration = videoPlayerValue.position;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (canUse && controlsNotifier.isDragProgress) {
      final double relative = details.delta.dx / totalWidth;
      final Duration duration = const Duration(minutes: 10) * relative;
      controlsNotifier.setDragDuration(
        controlsNotifier.dragDuration + duration,
        videoPlayerValue.duration,
      );
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (controlsNotifier.isDragProgress) {
      controlsNotifier.isDragProgress = false;
      videoViewController.seekTo(controlsNotifier.dragDuration);
    }
  }

  double handleValue(double value) {
    if (value > 1) {
      return 1;
    } else if (value.isNegative) {
      return 0;
    } else {
      return value;
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
  const _MaxSpeedPlay({
    Key? key,
    this.size = 16,
    required this.color,
    required this.local,
  }) : super(key: key);

  final double size;
  final Color color;
  final VideoViewLocalizations local;

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
        Text(widget.local.speedPlay, style: TextStyle(color: widget.color)),
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
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    Key? key,
    required this.value,
    required this.isDragLeft,
    required this.color,
    this.size = 16,
    this.height = 6,
  }) : super(key: key);

  final double value;

  final bool isDragLeft;
  final Color color;
  final double size;
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

  IconData get icon {
    final List<IconData> list = isDragLeft ? brightnessIcons : volumeIcons;
    if (value == 0) {
      return list[0];
    } else if (value > 0 && value < .5) {
      return list[1];
    } else {
      return list[2];
    }
  }

  List<IconData> get volumeIcons => <IconData>[
        Icons.volume_mute_rounded,
        Icons.volume_down_rounded,
        Icons.volume_up_rounded,
      ];

  List<IconData> get brightnessIcons => <IconData>[
        Icons.brightness_low_rounded,
        Icons.brightness_medium_rounded,
        Icons.brightness_high_rounded,
      ];
}
