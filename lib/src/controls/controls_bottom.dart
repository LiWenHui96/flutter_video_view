import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:flutter_video_view/src/widgets/animated_play_pause.dart';
import 'package:flutter_video_view/src/widgets/base_state.dart';
import 'package:video_player/video_player.dart';

import 'base_controls.dart';

/// @Describe: Bottom action bar
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

class ControlsBottom extends StatefulWidget {
  // ignore: public_member_api_docs
  const ControlsBottom({Key? key}) : super(key: key);

  @override
  State<ControlsBottom> createState() => _ControlsBottomState();
}

class _ControlsBottomState extends BaseVideoViewControls<ControlsBottom> {
  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      children: <Widget>[
        AnimatedPlayPause(
          onPressed: playOrPause,
          color: videoViewConfig.foregroundColor,
          isPlaying: videoPlayerValue.isPlaying,
        ),
        Expanded(child: Row(children: _buildChildren())),
        _AnimatedFullscreen(
          onPressed: () {
            if (canUse) {
              videoViewController.toggleFullScreen();
              controlsNotifier.isLock = false;

              Future<void>.delayed(
                const Duration(milliseconds: 300),
                () => showOrHide(visible: true),
              );
            }
          },
          isFullscreen: videoViewController.isFullScreen,
        ),
      ],
    );

    return Container(
      height: barHeight + bottomBarHeight,
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

  List<Widget> _buildChildren() {
    switch (textPosition) {
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
    return Text(formatDuration(currentDuration), style: defaultStyle);
  }

  Widget _buildDuration() {
    String text = formatDuration(totalDuration);

    if (textPosition == VideoTextPosition.ltl ||
        textPosition == VideoTextPosition.rtr) {
      text = '/$text';
    }

    return Text(text, style: defaultStyle);
  }

  Widget _buildProgress() {
    return Expanded(
      child: _VideoProgressBar(
        colors: videoViewConfig.videoViewProgressColors,
        currentDuration: currentDuration,
        totalDuration: totalDuration,
        value: videoPlayerValue,
        isDrag: controlsNotifier.isDragProgress,
        dragPosition: controlsNotifier.dragDuration,
        onDragStart: (DragStartDetails details) {
          if (canUse) {
            controlsNotifier.isDragProgress = true;
          }
        },
        onDragUpdate: (double relative) {
          if (canUse && controlsNotifier.isDragProgress) {
            showOrHide(visible: true, startTimer: false);
            controlsNotifier.setDragDuration(
              totalDuration * relative,
              totalDuration,
            );
          }
        },
        onDragEnd: (DragEndDetails details) {
          if (controlsNotifier.isDragProgress) {
            controlsNotifier.isDragProgress = false;
            showOrHide(visible: true);
            videoViewController.seekTo(controlsNotifier.dragDuration);
          }
        },
        onTapUp: (double relative) {
          if (canUse) {
            controlsNotifier.setDragDuration(
              totalDuration * relative,
              totalDuration,
            );
            videoViewController.seekTo(controlsNotifier.dragDuration);
          }
        },
      ),
    );
  }

  TextStyle get defaultStyle => TextStyle(
        fontSize: videoViewConfig.defaultTextSize,
        color: videoViewConfig.foregroundColor,
      );

  VideoTextPosition get textPosition =>
      videoViewConfig.textPosition?.call(videoViewController.isFullScreen) ??
      VideoTextPosition.ltl;

  double get bottomBarHeight => videoViewController.isFullScreen
      ? videoViewController.isPortrait
          ? MediaQueryData.fromWindow(window).padding.bottom
          : 12
      : 0;
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

class _VideoProgressBar extends StatefulWidget {
  _VideoProgressBar({
    Key? key,
    VideoViewProgressColors? colors,
    required this.currentDuration,
    required this.totalDuration,
    required this.value,
    required this.isDrag,
    required this.dragPosition,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  })  : colors = colors ?? VideoViewProgressColors(),
        super(key: key);

  final VideoViewProgressColors colors;
  final Duration currentDuration;
  final Duration totalDuration;
  final VideoPlayerValue value;
  final bool isDrag;
  final Duration dragPosition;
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
          painter: _ProgressBarPainter(
            currentDuration: widget.currentDuration,
            totalDuration: widget.totalDuration,
            value: widget.value,
            colors: widget.colors,
            isDrag: widget.isDrag,
            dragPosition: widget.dragPosition,
          ),
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
  _ProgressBarPainter({
    required this.currentDuration,
    required this.totalDuration,
    required this.value,
    required this.colors,
    this.isDrag = false,
    this.dragPosition = Duration.zero,
  });

  final Duration currentDuration;
  final Duration totalDuration;
  final VideoPlayerValue value;
  final VideoViewProgressColors colors;
  final bool isDrag;
  final Duration dragPosition;

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
        (isDrag ? dragPosition : currentDuration).inMilliseconds /
            totalDuration.inMilliseconds;
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
        height * (isDrag ? 3 : 2),
        Paint()..color = colors.handleColor,
      )
      ..drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (isDrag ? 5 : 3),
        Paint()..color = colors.handleMoreColor,
      );

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(totalDuration) * size.width;
      final double end = range.endFraction(totalDuration) * size.width;
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
