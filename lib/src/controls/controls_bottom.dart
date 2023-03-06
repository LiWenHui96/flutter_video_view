import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';
import 'package:video_player/video_player.dart';

import 'base_controls.dart';

/// @Describe: Bottom action bar
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/5

class ControlsBottom extends StatefulWidget {
  // ignore: public_member_api_docs
  const ControlsBottom({Key? key}) : super(key: key);

  @override
  State<ControlsBottom> createState() => _ControlsBottomState();
}

class _ControlsBottomState extends BaseVideoControls<ControlsBottom> {
  double? _lastVolume;

  @override
  Widget build(BuildContext context) {
    final Widget a = AnimatedPlayPause(
      isPlaying: value.isPlaying,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: playOrPause,
    );

    final Widget b = _buildProgressBar();

    final Widget c = _buildMuteButton();

    final Widget d = _buildFullScreenButton();

    Widget? child =
        config.bottomBuilder?.call(context, value.isFullScreen, a, b, c, d);

    child = SafeArea(
      top: false,
      bottom: value.isPortrait && value.isFullScreen,
      child: child ?? Row(children: <Widget>[a, Expanded(child: b), d]),
    );

    return Container(
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
  }

  Widget _buildMuteButton() {
    return _AnimatedMute(
      isMute: value.volume == 0,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: () {
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
    );
  }

  Widget _buildFullScreenButton() {
    return _AnimatedFullscreen(
      isFullscreen: value.isFullScreen,
      duration: defaultDuration,
      color: config.foregroundColor,
      onPressed: () {
        if (canUse) {
          controller.setFullScreen(!value.isFullScreen);

          Future<void>.delayed(
            defaultDuration,
            () => showOrHide(visible: true),
          );
        }
      },
    );
  }

  Widget _buildProgressBar() {
    return Row(children: _buildChildren());
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

  SizedBox get divider =>
      SizedBox(width: config.progressBarGap?.call(value.isFullScreen) ?? 10);

  Widget _buildPosition() {
    return Text(formatDuration(value.position), style: defaultStyle);
  }

  Widget _buildDuration() {
    String text = formatDuration(value.duration);

    if (textPosition == VideoTextPosition.ltl ||
        textPosition == VideoTextPosition.rtr) {
      text = '/$text';
    }

    return Text(text, style: defaultStyle);
  }

  Widget _buildProgress() {
    final Widget child = _VideoProgressBar(
      colors: config.videoViewProgressColors,
      value: value,
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

    return Expanded(child: SizedBox(height: 24, child: child));
  }

  VideoTextPosition get textPosition =>
      config.textPosition?.call(value.isFullScreen) ?? VideoTextPosition.ltl;
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
