import 'package:flutter/material.dart';

/// @Describe: Full screen button.
///
/// @Author: LiWeNHuI
/// @Date: 2023/4/3

class AnimatedFullscreen extends StatelessWidget {
  /// Full screen button.
  const AnimatedFullscreen({
    Key? key,
    required this.isFullscreen,
    required this.duration,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  /// Whether it is full screen.
  final bool isFullscreen;

  /// The duration of the whole orchestrated animation.
  final Duration duration;

  /// The color to use when drawing the icon.
  final Color color;

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
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
