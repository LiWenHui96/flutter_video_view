import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/utils/util_brightness.dart';
import 'package:flutter_video_view/src/utils/util_volume.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/video_view_localizations.dart';
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
            if (!videoViewValue.isLock) const ControlsTop(),
            const Spacer(),
            if (!videoViewValue.isLock) const ControlsBottom(),
          ],
        ),
        if (videoViewValue.isFullScreen) const ControlsCenter(),
      ],
    );

    child = AbsorbPointer(
      absorbing: !videoViewValue.isVisible,
      child: AnimatedOpacity(
        opacity: videoViewValue.isVisible ? 1.0 : .0,
        duration: defaultDuration,
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

    if (videoViewValue.isFinish) {
      return videoViewConfig.finishBuilder
              ?.call(context, videoViewValue.isFullScreen) ??
          Container(
            color: videoViewConfig.tipBackgroundColor,
            child: SafeArea(
              top: videoViewValue.isPortrait && videoViewValue.isFullScreen,
              bottom: false,
              child: Stack(
                children: <Widget>[
                  if (videoViewConfig.canBack && Navigator.canPop(context))
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
    if (videoViewValue.isPlaying || videoViewConfig.autoPlay) {
      startHideTimer();
    }

    if (videoViewConfig.showControlsOnInitialize) {
      Future<void>.delayed(defaultDuration, () => showOrHide(visible: true));
    }
  }

  @override
  Widget tipWidget({Widget? child}) {
    if (videoViewValue.isMaxSpeed) {
      child = _MaxSpeedPlay(
        size: videoViewConfig.defaultIconSize,
        style: defaultStyle,
      );
    }
    if (videoViewValue.isVerticalDrag) {
      child = _ViewProgressIndicator(
        value: videoViewValue.verticalDragValue,
        verticalDragType: videoViewValue.verticalDragType,
        size: videoViewConfig.defaultIconSize,
        color: foregroundColor,
      );
    }
    if (videoViewValue.isDragProgress) {
      child = Text(
        '${formatDuration(videoViewValue.dragDuration)} / ${formatDuration(videoViewValue.duration)}',
        style: defaultStyle,
      );
    }
    return super.tipWidget(child: child);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (videoViewConfig.canLongPress &&
        canUse &&
        videoViewValue.isPlaying &&
        videoViewValue.playbackSpeed < videoViewController.maxSpeed) {
      videoViewController.setMaxSpeed(isMaxSpeed: true);
      videoViewController.setPlaybackSpeed();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (videoViewValue.isMaxSpeed) {
      videoViewController.setMaxSpeed(isMaxSpeed: false);
      videoViewController.setPlaybackSpeed(speed: 1);
    }
  }

  Future<void> _onVerticalDragStart(DragStartDetails details) async {
    if (videoViewConfig.canChangeVolumeOrBrightness && canUse) {
      videoViewController.setVerticalDrag(isVerticalDrag: true);
      videoViewController.setVerticalDragType(
        verticalDragType: details.globalPosition.dx < totalWidth / 2
            ? VerticalDragType.brightness
            : VerticalDragType.volume,
      );

      double currentValue = 0;
      if (videoViewValue.verticalDragType == VerticalDragType.brightness) {
        currentValue = await ScreenBrightnessUtil.current;
      } else if (videoViewValue.verticalDragType == VerticalDragType.volume) {
        currentValue = await VolumeUtil.current;
      }
      videoViewController.setVerticalDragValue(verticalDragValue: currentValue);
    }
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (canUse && videoViewValue.isVerticalDrag) {
      videoViewController.setVerticalDragValue(
        verticalDragValue:
            videoViewValue.verticalDragValue - (details.delta.dy / totalHeight),
      );
      if (videoViewValue.verticalDragType == VerticalDragType.brightness) {
        await ScreenBrightnessUtil.setScreenBrightness(
          videoViewValue.verticalDragValue,
        );
      } else if (videoViewValue.verticalDragType == VerticalDragType.volume) {
        await VolumeUtil.setVolume(videoViewValue.verticalDragValue);
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (videoViewValue.isVerticalDrag) {
      videoViewController.setVerticalDrag(isVerticalDrag: false);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (videoViewConfig.canChangeProgress && canUse) {
      videoViewController.setDragProgress(isDragProgress: true);
      videoViewController.setDragDuration(videoViewValue.position);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (canUse && videoViewValue.isDragProgress) {
      final double relative = details.delta.dx / totalWidth;
      videoViewController.setDragDuration(
        videoViewValue.dragDuration +
            videoViewValue.dragTotalDuration * relative,
      );
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (videoViewValue.isDragProgress) {
      videoViewController.setDragProgress(isDragProgress: false);
      videoViewController.seekTo(videoViewValue.dragDuration);
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
  const _MaxSpeedPlay({Key? key, required this.size, required this.style})
      : super(key: key);

  /// The size of the icon.
  final double size;

  /// The color of the icon.
  final TextStyle style;

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
        Text(local.speedPlay, style: widget.style),
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

  VideoLocalizations get local => VideoLocalizations.of(context);
}

class _ViewProgressIndicator extends StatelessWidget {
  // ignore: public_member_api_docs
  const _ViewProgressIndicator({
    Key? key,
    required this.value,
    required this.verticalDragType,
    required this.color,
    required this.size,
  }) : super(key: key);

  /// If non-null, the value of this progress indicator.
  final double value;

  /// Is it volume or brightness.
  final VerticalDragType? verticalDragType;

  /// The color of the icon.
  final Color color;

  /// The size of the icon.
  final double size;

  /// The height of this progress indicator.
  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon,
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
  Widget get icon {
    if (verticalDragType == null) {
      return const SizedBox.shrink();
    }

    final List<IconData> list = verticalDragType == VerticalDragType.brightness
        ? brightnessIcons
        : volumeIcons;
    if (value <= 0) {
      return Icon(list[0], size: size, color: color);
    } else if (value < .5) {
      return Icon(list[1], size: size, color: color);
    } else {
      return Icon(list[2], size: size, color: color);
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
