import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_config.dart';
import 'video_view.dart';
import 'video_view_localizations.dart';
import 'widgets/widgets.dart';

/// @Describe: The layout of the main body of the video.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/2

class VideoBody extends StatelessWidget {
  /// Views include [VideoPlayer], b, c, and so on.
  const VideoBody({Key? key, required this.constraints}) : super(key: key);

  /// Immutable layout constraints for [RenderBox] layout.
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final VideoController controller = VideoController.of(context);
    final VideoValue value = controller.value;
    final VideoConfig config = controller.config;

    final Widget placeholderChild = _buildPlaceholderWidget(
      context,
      value.status,
      config.defaultStyle,
      onPressed: () async =>
          controller.initialize().then((_) => controller.play()),
    );

    final Widget? overlay = config.overlay?.call(value);

    return Container(
      alignment: Alignment.center,
      constraints: constraints,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (value.status.isSuccess)
            InteractiveViewer(
              maxScale: config.maxScale,
              minScale: config.minScale,
              panEnabled: config.panEnabled,
              scaleEnabled: config.scaleEnabled,
              child: AspectRatio(
                aspectRatio: value.aspectRatio,
                child: VideoPlayer(controller.videoPlayerController),
              ),
            ),
          if (overlay != null) overlay,
          if (config.showControls?.call(context, value.isFullScreen) ?? true)
            config.controlsType.child,
          config.placeholderBuilder?.call(value) ?? placeholderChild,
        ],
      ),
    );
  }

  Widget _buildPlaceholderWidget(
    BuildContext context,
    VideoInitStatus status,
    TextStyle defaultStyle, {
    VoidCallback? onPressed,
  }) {
    if (status.isNone) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.85),
          shape: BoxShape.circle,
        ),
        child: AnimatedPlayPause(isPlaying: false, onPressed: onPressed),
      );
    } else if (status.isLoading) {
      return const CircularProgressIndicator();
    } else if (status.isFail) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(VideoLocalizations.of(context).retry, style: defaultStyle),
      );
    }

    return const SizedBox.shrink();
  }
}
