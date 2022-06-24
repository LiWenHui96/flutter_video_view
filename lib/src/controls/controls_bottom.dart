import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/inside.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:video_player/video_player.dart';

import 'base_controls.dart';

/// @Describe: Bottom action bar
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

class ControlsBottom extends StatefulWidget {
  /// Externally provided
  const ControlsBottom({Key? key}) : super(key: key);

  @override
  State<ControlsBottom> createState() => _ControlsBottomState();
}

class _ControlsBottomState extends BaseVideoViewControls<ControlsBottom> {
  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      children: <Widget>[
        _AnimatedPlayPause(
          onPressed: playOrPause,
          isPlaying: videoPlayerValue.isPlaying,
        ),
        Expanded(
          child: _VideoPosition(
            textPosition: videoViewConfig.textPosition
                    ?.call(videoViewController.isFullScreen) ??
                VideoTextPosition.ltl,
            color: videoViewConfig.foregroundColor,
          ),
        ),
        _AnimatedFullscreen(
          onPressed: () {
            if (canUse) {
              videoViewController.toggleFullScreen();
              controlsNotifier.isLock = false;

              Timer? timer;
              timer = Timer(const Duration(milliseconds: 300), () {
                showOrHide(visible: true);
                timer?.cancel();
              });
            }
          },
          isFullscreen: videoViewController.isFullScreen,
        ),
      ],
    );

    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: bottomBarHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: videoViewConfig.controlsBackgroundColor,
        ),
      ),
      child: child,
    );
  }

  double get height => barHeight + bottomBarHeight;

  double get bottomBarHeight => videoViewController.isFullScreen
      ? videoViewController.isPortrait
          ? MediaQueryData.fromWindow(window).padding.bottom
          : 12
      : 0;
}

class _AnimatedPlayPause extends StatefulWidget {
  const _AnimatedPlayPause({
    Key? key,
    required this.isPlaying,
    this.size,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  final bool isPlaying;
  final double? size;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<_AnimatedPlayPause> createState() => _AnimatedPlayPauseState();
}

class _AnimatedPlayPauseState extends BaseState<_AnimatedPlayPause>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    value: widget.isPlaying ? 1 : 0,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(_AnimatedPlayPause oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        color: widget.color,
        size: widget.size,
        icon: AnimatedIcons.play_pause,
        progress: _animationController,
      ),
      onPressed: widget.onPressed,
    );
  }
}

class _AnimatedFullscreen extends StatelessWidget {
  const _AnimatedFullscreen({
    Key? key,
    required this.isFullscreen,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  final bool isFullscreen;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
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

class _VideoPosition extends StatefulWidget {
  const _VideoPosition({
    Key? key,
    required this.textPosition,
    required this.color,
  }) : super(key: key);

  final VideoTextPosition textPosition;
  final Color color;

  @override
  State<_VideoPosition> createState() => _VideoPositionState();
}

class _VideoPositionState extends BaseVideoViewControls<_VideoPosition> {
  @override
  Widget build(BuildContext context) {
    return Row(children: _buildChildren());
  }

  List<Widget> _buildChildren() {
    switch (widget.textPosition) {
      case VideoTextPosition.ltl:
        return <Widget>[
          _buildPosition(),
          _buildDuration(),
          divider,
          _buildProgress(),
        ];
      case VideoTextPosition.rtr:
        return <Widget>[
          _buildProgress(),
          divider,
          _buildPosition(),
          _buildDuration(),
        ];
      case VideoTextPosition.ltr:
        return <Widget>[
          _buildPosition(),
          divider,
          _buildProgress(),
          divider,
          _buildDuration(),
        ];
      case VideoTextPosition.none:
        return <Widget>[];
    }
  }

  SizedBox get divider => const SizedBox(width: 10);

  Widget _buildPosition() {
    return Text(
      formatDuration(videoPlayerValue.position),
      style: TextStyle(fontSize: 14, color: widget.color),
    );
  }

  Widget _buildDuration() {
    String text = formatDuration(videoPlayerValue.duration);

    if (widget.textPosition == VideoTextPosition.ltl ||
        widget.textPosition == VideoTextPosition.rtr) {
      text = '/$text';
    }

    return Text(text, style: TextStyle(fontSize: 14, color: widget.color));
  }

  Widget _buildProgress() {
    return Expanded(child: _VideoProgressBar());
  }
}

class _VideoProgressBar extends StatefulWidget {
  _VideoProgressBar({
    Key? key,
    VideoViewProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  })  : colors = colors ?? VideoViewProgressColors(),
        super(key: key);

  final VideoViewProgressColors colors;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragUpdate;

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends BaseVideoViewControls<_VideoProgressBar> {
  void _seekToRelativePosition(Offset globalPosition) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    controlsNotifier.setDragDuration(
      videoPlayerValue.duration * relative,
      videoPlayerValue.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Center(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            value: videoPlayerValue,
            colors: widget.colors,
            isDrag: controlsNotifier.isDragProgress,
            dragPosition: controlsNotifier.dragDuration.inMilliseconds,
          ),
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (canUse) {
          controlsNotifier.isDragProgress = true;
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (canUse && controlsNotifier.isDragProgress) {
          showOrHide(visible: true, startTimer: false);
          _seekToRelativePosition(details.globalPosition);
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (controlsNotifier.isDragProgress) {
          controlsNotifier.isDragProgress = false;
          showOrHide(visible: true);
          videoViewController.seekTo(controlsNotifier.dragDuration);
        }
      },
      onTapUp: (TapUpDetails details) {
        if (canUse) {
          _seekToRelativePosition(details.globalPosition);
          videoViewController.seekTo(controlsNotifier.dragDuration);
        }
      },
      child: child,
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    this.isDrag = false,
    this.dragPosition = 0,
  });

  VideoPlayerValue value;
  VideoViewProgressColors colors;
  bool isDrag;
  int dragPosition;

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
      colors.backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }
    final double playedPartPercent =
        (isDrag ? dragPosition : value.position.inMilliseconds) /
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
        colors.playedPaint,
      )
      ..drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (isDrag ? 3 : 2),
        colors.handlePaint,
      )
      ..drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (isDrag ? 5 : 3),
        colors.handlePaintMore,
      );

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      final Offset a = Offset(start, halfHeight);
      final Offset b = Offset(end, halfHeight + height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromPoints(a, b), radius),
        colors.bufferedPaint,
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
