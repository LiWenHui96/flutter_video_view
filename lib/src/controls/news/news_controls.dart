import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/base_controls.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

import 'news_controls_bottom.dart';
import 'news_controls_top.dart';

/// @Describe: The controls of video.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/15

class NewsControls extends StatefulWidget {
  /// The controls of video.
  ///
  /// Information class, embedded class video controller.
  const NewsControls({Key? key}) : super(key: key);

  @override
  State<NewsControls> createState() => _NewsControlsState();
}

class _NewsControlsState extends BaseVideoControls<NewsControls> {
  @override
  Widget build(BuildContext context) {
    if (value.isFinish) {
      return buildFinishWidget();
    }

    if (value.isMaxPreviewTime) {
      return buildMaxPreviewWidget();
    }

    Widget child = Column(
      children: <Widget>[
        _buildTopControls(),
        Expanded(child: _buildLongPress()),
        if (value.status.isSuccess) _buildBottomControls(),
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
        if (!value.isVisible && !value.isFullScreen && value.status.isSuccess)
          _buildBottomProgressBar(),
      ],
    );

    child = GestureDetector(
      onTap: showOrHide,
      onDoubleTap: playOrPause,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    return Stack(children: <Widget>[tooltipWidget(), child]);
  }

  /// Top action bar
  Widget _buildTopControls() {
    return NewsControlsTop(
      backButton: kBackButton(),
      defaultStyle: defaultStyle,
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
    return NewsControlsBottom(
      onPlayOrPause: playOrPause,
      onMute: onMute,
      onFullScreen: onFullScreen,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );
  }

  Widget _buildBottomProgressBar() {
    return Positioned(
      bottom: .5,
      child: NewsVideoProgressBar(
        colors: config.videoProgressBarColors,
        value: value,
      ),
    );
  }

  @override
  Widget tooltipWidget({
    Widget? child,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? margin,
  }) {
    if (value.isDragProgress) {
      child = Text(
        '${formatDuration(value.dragDuration)} / ${formatDuration(value.duration)}',
        style: defaultStyle,
      );
    }

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
    }

    return super.tooltipWidget(
      child: child,
      alignment: Alignment.bottomCenter,
      margin: const EdgeInsets.only(bottom: 24),
    );
  }
}
