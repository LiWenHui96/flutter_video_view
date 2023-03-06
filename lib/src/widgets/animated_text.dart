import 'package:flutter/material.dart';

import 'base_state.dart';

/// @Describe: Revolving door.
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/3

class AnimatedText extends StatefulWidget {
  /// Text with scrolling animation.
  const AnimatedText({Key? key, required this.child})
      : assert(child is Text, 'Must be Text.'),
        super(key: key);

  /// Child
  final Widget child;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends BaseState<AnimatedText> {
  final ScrollController controller = ScrollController();
  final Duration stayDuration = const Duration(seconds: 1);

  @override
  void initState() {
    _animation();

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );
  }

  Future<void> _animation() async {
    await Future<void>.delayed(Duration.zero);

    while (true) {
      await Future<void>.delayed(stayDuration);
      if (controller.positions.isNotEmpty) {
        controller.jumpTo(0);
      }

      await Future<void>.delayed(stayDuration);
      if (controller.positions.isNotEmpty) {
        final double maxScrollExtent = controller.position.maxScrollExtent;
        final int seconds = (maxScrollExtent / 40).ceil();

        if (maxScrollExtent > 0 && seconds > 0) {
          await controller.animateTo(
            maxScrollExtent,
            duration: Duration(seconds: seconds),
            curve: Curves.easeIn,
          );
        }
      }
    }
  }
}
