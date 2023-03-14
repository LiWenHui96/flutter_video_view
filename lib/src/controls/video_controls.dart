import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/utils/utils.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/video_view_localizations.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

import 'base_controls.dart';
import 'controls_bottom.dart';
import 'controls_center.dart';
import 'controls_top.dart';

/// @Describe: The controls of video.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/2

class VideoControls extends StatefulWidget {
  // ignore: public_member_api_docs
  const VideoControls({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoControlsState();
}

class _VideoControlsState extends BaseVideoControls<VideoControls> {
  double? _lastVolume;

  @override
  Widget build(BuildContext context) {
    if (config.showBuffering && !value.isFinish && value.isBuffering) {
      return config.bufferingBuilder ?? const CircularProgressIndicator();
    }

    if (value.isFinish) {
      return _buildFinishWidget();
    }

    Widget child = Column(
      children: <Widget>[
        if (!value.isLock) _buildTopControls(),
        Expanded(child: _buildLongPress()),
        if (!value.isLock && value.status.isSuccess) _buildBottomControls(),
      ],
    );

    child = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        if (value.isFullScreen)
          ControlsCenter(onHideControls: () => showOrHide(visible: true)),
        if (config.showCenterPlay && !value.isPlaying && !value.isBuffering)
          _buildPlayButtonWidget(),
      ],
    );

    child = AnimatedOpacity(
      opacity: value.isVisible ? 1 : .0,
      duration: defaultDuration,
      child: child,
    );

    child = GestureDetector(
      onTap: showOrHide,
      onDoubleTap: playOrPause,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    return Stack(children: <Widget>[tooltipWidget(), child]);
  }

  /// PlayButton
  Widget _buildPlayButtonWidget() {
    if (!value.status.isSuccess ||
        value.isDragProgress ||
        value.isVerticalDrag ||
        value.isLock) {
      return const SizedBox.shrink();
    }

    return Center(
      child: config.centerPlayButton != null
          ? GestureDetector(onTap: playOrPause, child: config.centerPlayButton)
          : Container(
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
            ),
    );
  }

  /// A widget that shows when playback is complete.
  Widget _buildFinishWidget() {
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

  /// Top action bar
  Widget _buildTopControls() {
    return ControlsTop(backButton: kBackButton(), defaultStyle: defaultStyle);
  }

  /// Function area for long press operation.
  Widget _buildLongPress() {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
    );
  }

  /// Bottom action bar
  Widget _buildBottomControls() {
    return ControlsBottom(
      onPlayOrPause: playOrPause,
      onMute: () {
        if (canUse) {
          if (value.volume == 0) {
            controller.setVolume(_lastVolume ?? .5);
          } else {
            _lastVolume = value.volume;
            controller.setVolume(0);
          }

          showOrHide(visible: true);
        }
      },
      onFullScreen: () {
        if (canUse) {
          controller.setFullScreen(!value.isFullScreen);

          Future<void>.delayed(
            defaultDuration,
            () => showOrHide(visible: true),
          );
        }
      },
      onDragStart: (DragStartDetails details) {
        if (canUse) {
          controller.setDragProgress(true);
        }
      },
      onDragUpdate: (double relative) {
        if (canUse && value.isDragProgress) {
          controller.setDragDuration(value.duration * relative);
          showOrHide(visible: true, startTimer: false);
        }
      },
      onDragEnd: (DragEndDetails details) {
        if (value.isDragProgress) {
          controller
            ..setDragProgress(false)
            ..seekTo(value.dragDuration);
          showOrHide(visible: true);
        }
      },
      onTapUp: (double relative) {
        if (canUse) {
          controller
            ..setDragDuration(value.duration * relative)
            ..seekTo(value.dragDuration);
        }
      },
    );
  }

  @override
  Future<void> initialize() async {
    if (config.showControlsOnInitialize) {
      Future<void>.delayed(
        defaultDuration,
        () => showOrHide(visible: true, startTimer: false),
      );
    }
  }

  @override
  Widget tooltipWidget({
    Widget? child,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? margin,
  }) {
    if (value.isMaxPlaybackSpeed) {
      final Icon icon = Icon(
        Icons.play_arrow_rounded,
        size: config.iconSize,
        color: config.foregroundColor,
      );

      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...List<Icon>.filled(3, icon).toList(),
          const SizedBox(width: 3),
          Text(local.speedPlay, style: defaultStyle),
        ],
      );

      return super.tooltipWidget(
        child: child,
        alignment: Alignment.topCenter,
        margin: const EdgeInsets.only(top: 8),
      );
    }

    if (value.isVerticalDrag) {
      child = _ViewProgressIndicator(
        value: value.verticalDragValue,
        verticalDragType: value.verticalDragType,
        size: config.iconSize,
        color: config.foregroundColor,
      );
    }

    if (value.isDragProgress) {
      child = Text(
        '${formatDuration(value.dragDuration)} / ${formatDuration(value.duration)}',
        style: defaultStyle,
      );
    }

    return super
        .tooltipWidget(child: child, alignment: alignment, margin: margin);
  }

  void _onLongPressStart(LongPressStartDetails details) {
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

  void _onLongPressEnd(LongPressEndDetails details) {
    if (value.isMaxPlaybackSpeed) {
      controller
        ..setMaxPlaybackSpeed(false)
        ..setPlaybackSpeed(speed: 1);
    }
  }

  Future<void> _onVerticalDragStart(DragStartDetails details) async {
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

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
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

  void _onVerticalDragEnd(DragEndDetails details) {
    if (value.isVerticalDrag) {
      controller.setVerticalDrag(false);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (canUse && config.canChangeProgress) {
      controller
        ..setDragProgress(true)
        ..setDragDuration(value.position);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (canUse && value.isDragProgress) {
      final double relative = details.delta.dx / totalWidth;
      controller.setDragDuration(
        value.dragDuration + value.dragTotalDuration * relative,
      );
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (value.isDragProgress) {
      controller
        ..setDragProgress(false)
        ..seekTo(value.dragDuration);
    }
  }

  double get totalWidth =>
      (context.size?.width ?? MediaQuery.of(context).size.width).ceilToDouble();

  double get totalHeight =>
      (context.size?.height ?? MediaQuery.of(context).size.height)
          .ceilToDouble();

  // ignore: public_member_api_docs
  VideoLocalizations get local => VideoLocalizations.of(context);
}

class _ViewProgressIndicator extends StatelessWidget {
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
