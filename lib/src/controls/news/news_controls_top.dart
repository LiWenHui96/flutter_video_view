import 'package:flutter/material.dart';
import 'package:flutter_video_view/src/video_config.dart';
import 'package:flutter_video_view/src/video_view.dart';
import 'package:flutter_video_view/src/widgets/widgets.dart';

/// @Describe: Top action bar
///
/// @Author: LiWeNHuI
/// @Date: 2023/4/3

class NewsControlsTop extends StatelessWidget {
  /// Top action bar
  const NewsControlsTop({
    Key? key,
    required this.backButton,
    required this.defaultStyle,
  }) : super(key: key);

  /// Back Button.
  final Widget backButton;

  /// The default text style for title.
  final TextStyle defaultStyle;

  @override
  Widget build(BuildContext context) {
    final VideoController controller = VideoController.of(context);
    final VideoValue value = controller.value;
    final VideoConfig config = controller.config;

    Widget child = Row(
      children: <Widget>[
        if (config.canBack && Navigator.canPop(context) && value.isFullScreen)
          backButton,
        if (config.title != null && value.isFullScreen && !value.isPortrait)
          Expanded(
            child: AnimatedText(
              child: Text(
                config.title ?? '',
                style: config.titleTextStyle ?? defaultStyle,
                maxLines: 1,
              ),
            ),
          )
        else
          const Spacer(),
        if (config.topActionsBuilder != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children:
                config.topActionsBuilder!.call(context, value.isFullScreen),
          ),
      ],
    );

    child = SafeArea(
      top: value.isPortrait && value.isFullScreen,
      bottom: false,
      child: child,
    );

    child = Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: config.controlsBackgroundColor,
        ),
      ),
      child: child,
    );

    return AbsorbPointer(absorbing: !value.isVisible, child: child);
  }
}
