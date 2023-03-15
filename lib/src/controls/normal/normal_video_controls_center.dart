import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/base_controls.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

/// @Describe: Center action bar
///
/// @Author: LiWeNHuI
/// @Date: 2023/3/3

class ControlsCenter extends StatelessWidget {
  /// Center action bar
  const ControlsCenter({Key? key, required this.onHideControls})
      : super(key: key);

  /// Used to hide controllers.
  final VoidCallback onHideControls;

  @override
  Widget build(BuildContext context) {
    final VideoController controller = VideoController.of(context);
    final VideoValue value = controller.value;
    final VideoConfig config = controller.config;

    AnimatedLockButton _lockButton() {
      return AnimatedLockButton(
        isLock: value.isLock,
        canShowLock: config.showLock,
        backgroundColor: config.tooltipBackgroundColor,
        duration: defaultDuration,
        color: config.foregroundColor,
        onPressed: () {
          controller.setLock(!value.isLock);
          onHideControls.call();
        },
      );
    }

    Widget _actions(List<Widget>? list) {
      list ??= <Widget>[_lockButton()];

      final List<Widget> children = list.map((Widget child) {
        if (child is AnimatedLockButton) {
          return child;
        }

        return Container(
          padding:
              child is IconButton ? EdgeInsets.zero : const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: config.tooltipBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      }).toList();

      return Column(mainAxisSize: MainAxisSize.min, children: children);
    }

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _actions(
          config.centerLeftActionsBuilder
              ?.call(context, value.isFullScreen, value.isLock, _lockButton()),
        ),
        const Spacer(),
        _actions(
          config.centerRightActionsBuilder
              ?.call(context, value.isFullScreen, value.isLock, _lockButton()),
        ),
      ],
    );

    child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(top: false, bottom: false, child: child),
    );

    return AbsorbPointer(absorbing: !value.isVisible, child: child);
  }
}
