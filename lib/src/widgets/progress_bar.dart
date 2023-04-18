import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/controls/news/news_controls.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:video_player/video_player.dart';

import 'base_state.dart';

/// @Describe: Progress bar.
///
/// @Author: LiWeNHuI
/// @Date: 2023/4/3

class VideoProgressBar extends StatefulWidget {
  /// Progress bar.
  VideoProgressBar({
    Key? key,
    VideoProgressBarColors? colors,
    required this.value,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  })  : colors = colors ?? VideoProgressBarColors(),
        super(key: key);

  /// The color of the progress bar.
  final VideoProgressBarColors colors;

  /// Information about video related data.
  final VideoValue value;

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
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends BaseState<VideoProgressBar> {
  @override
  Widget build(BuildContext context) {
    final Widget child = Center(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: CustomPaint(
          painter:
              ProgressBarPainter(value: widget.value, colors: widget.colors),
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

  double _seekToRelative(Offset globalPosition) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(globalPosition).dx / box.size.width;
  }
}

/// Progress bar of [NewsControls].
class NewsVideoProgressBar extends StatefulWidget {
  /// Progress bar of [NewsControls].
  NewsVideoProgressBar({
    Key? key,
    VideoProgressBarColors? colors,
    required this.value,
  })  : colors = colors ?? VideoProgressBarColors(),
        super(key: key);

  /// The color of the progress bar.
  final VideoProgressBarColors colors;

  /// Information about video related data.
  final VideoValue value;

  @override
  State<NewsVideoProgressBar> createState() => _NewsVideoProgressBarState();
}

class _NewsVideoProgressBarState extends BaseState<NewsVideoProgressBar> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 2,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: CustomPaint(
          painter: ProgressBarPainter(
            value: widget.value,
            colors: widget.colors,
            isPoints: false,
          ),
        ),
      ),
    );
  }
}

/// Painter for the progress bar.
class ProgressBarPainter extends CustomPainter {
  /// Progress bar and aiming point.
  ProgressBarPainter({
    required this.value,
    required this.colors,
    this.isPoints = true,
  });

  /// Data related to the video.
  final VideoValue value;

  /// Color
  final VideoProgressBarColors colors;

  /// Whether to draw aiming points.
  final bool isPoints;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, halfHeight),
          Offset(playedPart, halfHeight + height),
        ),
        radius,
      ),
      Paint()..color = colors.playedColor,
    );

    if (isPoints) {
      canvas
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
    }

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

  ///
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
