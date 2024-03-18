import 'package:flutter/material.dart';

import 'base_state.dart';

/// @Describe: Play or Pause.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class AnimatedPlayPause extends StatefulWidget {
  const AnimatedPlayPause({
    Key? key,
    this.decoration,
    required this.isPlaying,
    this.duration,
    this.size,
    this.color,
    this.onPressed,
  }) : super(key: key);

  /// The decoration to paint behind the [AnimatedPlayPause].
  ///
  /// Use the [color] property to specify a simple solid color.
  ///
  /// The [AnimatedPlayPause] is not clipped to the decoration. To clip a child
  /// to the shape of a particular [ShapeDecoration], consider using a
  /// [ClipPath] widget.
  final Decoration? decoration;

  /// Whether it is playing.
  final bool isPlaying;

  /// The length of time this animation should last.
  final Duration? duration;

  /// The size of [AnimatedIcon].
  final double? size;

  /// The color of [AnimatedIcon].
  final Color? color;

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  @override
  State<AnimatedPlayPause> createState() => _AnimatedPlayPauseState();
}

class _AnimatedPlayPauseState extends BaseState<AnimatedPlayPause>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    value: widget.isPlaying ? 1 : 0,
    duration: widget.duration ?? const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(AnimatedPlayPause oldWidget) {
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
    final Widget child = IconButton(
      icon: AnimatedIcon(
        color: widget.color,
        size: widget.size,
        icon: AnimatedIcons.play_pause,
        progress: _animationController,
      ),
      onPressed: widget.onPressed,
    );

    return Container(decoration: widget.decoration, child: child);
  }
}
