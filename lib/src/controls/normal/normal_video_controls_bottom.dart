import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/base_controls.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';
import 'package:video_player/video_player.dart';

/// @Describe: Bottom action bar
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/5

class ControlsBottom extends StatelessWidget {
  // ignore: public_member_api_docs
  const ControlsBottom({
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

  /// Start the progress adjustment operation.
  final GestureDragStartCallback onDragStart;

  /// Progress in adjustment.
  final ValueChanged<double> onDragUpdate;

  /// End the operation of progress adjustment.
  final GestureDragEndCallback onDragEnd;

  /// Click to adjust the video's progress.
  final ValueChanged<double> onTapUp;

  @override
  Widget build(BuildContext context) {
    final VideoController controller = VideoController.of(context);
    final VideoValue value = controller.value;
    final VideoConfig config = controller.config;

    final TextStyle style =
        TextStyle(fontSize: config.textSize, color: config.foregroundColor);
    final VideoTextPosition textPosition =
        config.onTextPosition?.call(value.isFullScreen) ??
            VideoTextPosition.ltl;

    final Widget a = AnimatedPlayPause(
      isPlaying: value.isPlaying,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onPlayOrPause,
    );

    final Widget b = _buildProgressBar(
      value,
      config,
      textPosition,
      style,
      onDragStart,
      onDragUpdate,
      onDragEnd,
      onTapUp,
    );

    final Widget c = _buildMuteButton(value, config);

    final Widget d = _buildFullScreenButton(value, config);

    Widget? child =
        config.bottomBuilder?.call(context, value.isFullScreen, a, b, c, d);

    child = SafeArea(
      top: false,
      bottom: value.isPortrait && value.isFullScreen,
      child: child ?? Row(children: <Widget>[a, Expanded(child: b), d]),
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
    return _AnimatedMute(
      isMute: value.volume == 0,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onMute,
    );
  }

  Widget _buildFullScreenButton(VideoValue value, VideoConfig config) {
    return _AnimatedFullscreen(
      isFullscreen: value.isFullScreen,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: onFullScreen,
    );
  }

  Widget _buildProgressBar(
    VideoValue value,
    VideoConfig config,
    VideoTextPosition textPosition,
    TextStyle style,
    GestureDragStartCallback onDragStart,
    ValueChanged<double> onDragUpdate,
    GestureDragEndCallback onDragEnd,
    ValueChanged<double> onTapUp,
  ) {
    final SizedBox divider = SizedBox(
      width: config.onProgressBarGap?.call(value.isFullScreen) ?? 10,
    );

    final Widget position = _buildPosition(value, config, style);

    final Widget duration = _buildDuration(value, config, textPosition, style);

    final Widget progress = _buildProgress(
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

  Widget _buildPosition(VideoValue value, VideoConfig config, TextStyle style) {
    return Text(formatDuration(value.position), style: style);
  }

  Widget _buildDuration(
    VideoValue value,
    VideoConfig config,
    VideoTextPosition textPosition,
    TextStyle style,
  ) {
    String text = formatDuration(value.duration);

    if (textPosition == VideoTextPosition.ltl ||
        textPosition == VideoTextPosition.rtr) {
      text = '/$text';
    }

    return Text(text, style: style);
  }

  Widget _buildProgress(
    VideoValue value,
    VideoConfig config,
    GestureDragStartCallback onDragStart,
    ValueChanged<double> onDragUpdate,
    GestureDragEndCallback onDragEnd,
    ValueChanged<double> onTapUp,
  ) {
    final Widget child = _VideoProgressBar(
      colors: config.videoViewProgressColors,
      value: value,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );

    return Expanded(child: SizedBox(height: 24, child: child));
  }
}

class _AnimatedMute extends StatelessWidget {
  const _AnimatedMute({
    Key? key,
    required this.isMute,
    required this.duration,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  final bool isMute;
  final Duration duration;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedCrossFade(
        duration: duration,
        crossFadeState:
            isMute ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        firstChild: Icon(Icons.volume_off_rounded, color: color),
        secondChild: Icon(Icons.volume_up_rounded, color: color),
      ),
      onPressed: onPressed,
    );
  }
}

class _AnimatedFullscreen extends StatelessWidget {
  const _AnimatedFullscreen({
    Key? key,
    required this.isFullscreen,
    required this.duration,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  final bool isFullscreen;
  final Duration duration;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedCrossFade(
        duration: duration,
        crossFadeState:
            isFullscreen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        firstChild: Icon(Icons.fullscreen_exit, color: color),
        secondChild: Icon(Icons.fullscreen, color: color),
      ),
      onPressed: onPressed,
    );
  }
}

class _VideoProgressBar extends StatefulWidget {
  _VideoProgressBar({
    Key? key,
    VideoViewProgressColors? colors,
    required this.value,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  })  : colors = colors ?? VideoViewProgressColors(),
        super(key: key);

  final VideoViewProgressColors colors;
  final VideoValue value;
  final GestureDragStartCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final ValueChanged<double> onTapUp;

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends BaseState<_VideoProgressBar> {
  double _seekToRelative(Offset globalPosition) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(globalPosition).dx / box.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Center(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: CustomPaint(
          painter:
              _ProgressBarPainter(value: widget.value, colors: widget.colors),
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: widget.onDragStart,
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        widget.onDragUpdate.call(_seekToRelative(details.globalPosition));
      },
      onHorizontalDragEnd: widget.onDragEnd,
      onTapUp: (TapUpDetails details) {
        widget.onTapUp.call(_seekToRelative(details.globalPosition));
      },
      child: child,
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({required this.value, required this.colors});

  final VideoValue value;
  final VideoViewProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double height = 2;
    const Radius radius = Radius.circular(4);

    final double halfHeight = size.height / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, halfHeight),
          Offset(size.width, halfHeight + height),
        ),
        radius,
      ),
      Paint()..color = colors.backgroundColor,
    );
    if (!value.isInitialized) {
      return;
    }
    final double playedPartPercent =
        (value.isDragProgress ? value.dragDuration : value.position)
                .inMilliseconds /
            value.duration.inMilliseconds;
    final double playedPart = handleValue(playedPartPercent) * size.width;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(0, halfHeight),
            Offset(playedPart, halfHeight + height),
          ),
          radius,
        ),
        Paint()..color = colors.playedColor,
      )
      ..drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (value.isDragProgress ? 3 : 2),
        Paint()..color = colors.handleColor,
      )
      ..drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (value.isDragProgress ? 5 : 3),
        Paint()..color = colors.handleMoreColor,
      );

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      final Offset a = Offset(start, halfHeight);
      final Offset b = Offset(end, halfHeight + height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromPoints(a, b), radius),
        Paint()..color = colors.bufferedColor,
      );
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
}
