import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/base_controls.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

/// @Describe: Bottom action bar
///
/// @Author: LiWeNHuI
/// @Date: 2023/4/3

class NewsControlsBottom extends StatelessWidget {
  /// Bottom action bar
  const NewsControlsBottom({
    Key? key,
    required this.onPlayOrPause,
    required this.onMute,
    required this.onFullScreen,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  }) : super(key: key);

  /// Play or pause video.
  final VoidCallback? onPlayOrPause;

  /// Mute the video.
  final VoidCallback? onMute;

  /// Enable/disable full screen mode.
  final VoidCallback? onFullScreen;

  /// The callback event before dragging the progress bar to adjust the
  /// progress.
  final GestureDragStartCallback onDragStart;

  /// The callback event during dragging the progress bar to adjust the
  /// progress.
  final ValueChanged<double> onDragUpdate;

  /// The callback event after dragging the progress bar to adjust the progress.
  final GestureDragEndCallback onDragEnd;

  /// Click on the progress bar to change the progress of the video.
  final ValueChanged<double> onTapUp;

  @override
  Widget build(BuildContext context) {
    final VideoController controller = VideoController.of(context);
    final VideoValue value = controller.value;
    final VideoConfig config = controller.config;

    final VideoTextPosition textPosition =
        config.onTextPosition?.call(context, value.isFullScreen) ??
            VideoTextPosition.ltl;

    final Widget a = AnimatedPlayPause(
      isPlaying: value.isPlaying,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onPlayOrPause,
    );

    final Widget b = _buildProgress(
      context,
      value: value,
      config: config,
      textPosition: textPosition,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );

    final Widget c = _buildMuteButton(value, config);

    final Widget d = _buildFullScreenButton(value, config);

    Widget? child = config.bottomBuilder?.call(
      context,
      value.isFullScreen,
      a,
      b,
      c,
      const SizedBox.shrink(),
      d,
    );

    child = SafeArea(
      top: false,
      bottom: value.isPortrait && value.isFullScreen,
      child: child ??
          Row(
            children: <Widget>[const SizedBox(width: 8), Expanded(child: b), d],
          ),
    );

    child = Container(
      padding: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: config.controlsBackgroundColor,
        ),
      ),
      child: child,
    );

    return AbsorbPointer(absorbing: !value.isVisible, child: child);
  }

  Widget _buildMuteButton(VideoValue value, VideoConfig config) {
    return AnimatedMute(
      isMute: value.volume == 0,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onMute,
    );
  }

  Widget _buildFullScreenButton(VideoValue value, VideoConfig config) {
    return AnimatedFullscreen(
      isFullscreen: value.isFullScreen,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onFullScreen,
    );
  }

  Widget _buildProgress(
    BuildContext context, {
    required VideoValue value,
    required VideoConfig config,
    required VideoTextPosition textPosition,
    required GestureDragStartCallback onDragStart,
    required ValueChanged<double> onDragUpdate,
    required GestureDragEndCallback onDragEnd,
    required ValueChanged<double> onTapUp,
  }) {
    final SizedBox divider = SizedBox(
      width: config.onProgressBarGap?.call(context, value.isFullScreen) ?? 10,
    );

    final Widget position = _buildPosition(value, config);

    final Widget duration = _buildDuration(value, config, textPosition);

    final Widget progress = _buildProgressBar(
      value,
      config,
      onDragStart,
      onDragUpdate,
      onDragEnd,
      onTapUp,
    );

    List<Widget>? children;

    if (textPosition == VideoTextPosition.ltl) {
      children = <Widget>[position, duration, divider, progress];
    } else if (textPosition == VideoTextPosition.rtr) {
      children = <Widget>[progress, divider, position, duration];
    } else if (textPosition == VideoTextPosition.ltr) {
      children = <Widget>[position, divider, progress, divider, duration];
    }

    return Row(children: children ?? <Widget>[]);
  }

  Widget _buildPosition(VideoValue value, VideoConfig config) {
    return Text(formatDuration(value.position), style: config.defaultStyle);
  }

  Widget _buildDuration(
    VideoValue value,
    VideoConfig config,
    VideoTextPosition textPosition,
  ) {
    String text = formatDuration(value.duration);

    if (textPosition == VideoTextPosition.ltl ||
        textPosition == VideoTextPosition.rtr) {
      text = '/$text';
    }

    return Text(text, style: config.defaultStyle);
  }

  Widget _buildProgressBar(
    VideoValue value,
    VideoConfig config,
    GestureDragStartCallback onDragStart,
    ValueChanged<double> onDragUpdate,
    GestureDragEndCallback onDragEnd,
    ValueChanged<double> onTapUp,
  ) {
    final Widget child = VideoProgressBar(
      colors: config.videoProgressBarColors,
      value: value,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );

    return Expanded(child: SizedBox(height: 24, child: child));
  }
}
