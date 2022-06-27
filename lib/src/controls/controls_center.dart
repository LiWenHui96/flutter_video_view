import 'package:flutter/material.dart';

import 'base_controls.dart';

/// @Describe: Center action bar
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

class ControlsCenter extends StatefulWidget {
  // ignore: public_member_api_docs
  const ControlsCenter({Key? key}) : super(key: key);

  @override
  State<ControlsCenter> createState() => _ControlsCenterState();
}

class _ControlsCenterState extends BaseVideoViewControls<ControlsCenter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _actions(
            videoViewConfig.centerLeftActions?.call(
              context,
              videoViewController.isFullScreen,
              controlsNotifier.isLock,
              _lockButton(),
            ),
          ),
          const Spacer(),
          _actions(
            videoViewConfig.centerRightActions?.call(
              context,
              videoViewController.isFullScreen,
              controlsNotifier.isLock,
              _lockButton(),
            ),
          ),
        ],
      ),
    );
  }

  _AnimatedLockButton _lockButton() {
    return _AnimatedLockButton(
      isLock: controlsNotifier.isLock,
      canShowLock: canShowLock,
      backgroundColor: videoViewConfig.tipBackgroundColor,
      color: videoViewConfig.foregroundColor,
      onPressed: () {
        controlsNotifier.isLock = !controlsNotifier.isLock;
        showOrHide(visible: true);
      },
    );
  }

  Widget _actions(List<Widget>? oldList) {
    final List<Widget> children =
        (oldList ?? <Widget>[_lockButton()]).map((Widget child) {
      if (child is _AnimatedLockButton) {
        return child;
      }
      return Container(
        padding:
            child is IconButton ? EdgeInsets.zero : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: videoViewConfig.tipBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }).toList();

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  bool get canShowLock => videoViewConfig.canShowLock;
}

class _AnimatedLockButton extends StatelessWidget {
  const _AnimatedLockButton({
    Key? key,
    required this.isLock,
    required this.canShowLock,
    required this.backgroundColor,
    this.color = Colors.white,
    this.onPressed,
  }) : super(key: key);

  final bool isLock;
  final bool canShowLock;
  final Color backgroundColor;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget child = IconButton(
      icon: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
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
