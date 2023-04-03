import 'package:flutter/material.dart';

/// @Describe: Mute button.
///
/// @Author: LiWeNHuI
/// @Date: 2023/4/3

class AnimatedMute extends StatelessWidget {
  /// Mute button.
  const AnimatedMute({
    Key? key,
    required this.isMute,
    required this.duration,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  /// Is the sound muted.
  final bool isMute;

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
            isMute ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        firstChild: Icon(Icons.volume_off_rounded, color: color),
        secondChild: Icon(Icons.volume_up_rounded, color: color),
      ),
      onPressed: onPressed,
    );
  }
}
