import 'package:flutter/material.dart';

/// @Describe: Lock button.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/3

class AnimatedLockButton extends StatelessWidget {
  /// Lock button.
  const AnimatedLockButton({
    Key? key,
    required this.isLock,
    required this.canShowLock,
    required this.backgroundColor,
    required this.duration,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  /// Whether it is locked.
  final bool isLock;

  /// Whether to display [AnimatedLockButton].
  final bool canShowLock;

  /// The color of the background frame of [AnimatedLockButton].
  final Color backgroundColor;

  /// The duration of the animation.
  final Duration duration;

  /// The color of the button.
  final Color color;

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget child = IconButton(
      icon: AnimatedCrossFade(
        duration: duration,
        crossFadeState:
            isLock ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        firstChild: Icon(Icons.lock_outline, color: color),
        secondChild: Icon(Icons.lock_open_outlined, color: color),
      ),
      onPressed: onPressed,
    );

    child = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );

    return Visibility(visible: canShowLock, child: child);
  }
}
