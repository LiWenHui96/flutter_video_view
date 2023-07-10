import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/base_controls.dart';
import 'package:flutter_video_view/src/video_view.dart';

import 'normal_controls_bottom.dart';
import 'normal_controls_center.dart';
import 'normal_controls_top.dart';

/// @Describe: The controls of video.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/2

class NormalControls extends StatefulWidget {
  /// The controls of video.
  ///
  /// Base pattern.
  const NormalControls({Key? key}) : super(key: key);

  @override
  State<NormalControls> createState() => _NormalControlsState();
}

class _NormalControlsState extends BaseVideoControls<NormalControls> {
  @override
  Widget build(BuildContext context) {
    if (value.isFinish) {
      return buildFinishWidget();
    }

    if (value.isMaxPreviewTime) {
      return _buildMaxPreviewWidget();
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
          NormalControlsCenter(onHideControls: () => showOrHide(visible: true)),
      ],
    );

    child = AnimatedOpacity(
      opacity: value.isVisible ? 1 : .0,
      duration: defaultDuration,
      child: child,
    );

    child = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        if (config.showCenterPlay && !value.isPlaying && !value.isBuffering)
          buildPlayButtonWidget(),
        if (config.showBuffering && !value.isFinish && value.isBuffering)
          config.bufferingBuilder ?? const CircularProgressIndicator(),
      ],
    );

    child = GestureDetector(
      onTap: showOrHide,
      onDoubleTap: playOrPause,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    return Stack(children: <Widget>[tooltipWidget(), child]);
  }

  Widget _buildMaxPreviewWidget() {
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

  /// Top action bar
  Widget _buildTopControls() {
    return NormalControlsTop(
      backButton: kBackButton(),
      defaultStyle: config.defaultStyle,
    );
  }

  /// Function area for long press operation.
  Widget _buildLongPress() {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
    );
  }

  /// Bottom action bar
  Widget _buildBottomControls() {
    return NormalControlsBottom(
      onPlayOrPause: playOrPause,
      onMute: onMute,
      onFullScreen: onFullScreen,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );
  }

  @override
  Future<void> initialize() async {
    if (config.showControlsOnInitialize) {
      Future<void>.delayed(defaultDuration, () => showOrHide(visible: true));
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
          Text(local.speedPlay, style: config.defaultStyle),
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
        style: config.defaultStyle,
      );
    }

    return super
        .tooltipWidget(child: child, alignment: alignment, margin: margin);
  }
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
