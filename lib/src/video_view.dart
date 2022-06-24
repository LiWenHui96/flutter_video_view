import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'controls/video_view_controls.dart';
import 'inside.dart';
import 'local/video_view_localizations.dart';
import 'notifier/controls_notifier.dart';
import 'video_view_config.dart';
import 'video_view_controller.dart';

/// @Describe: The view of video.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/15

class VideoView extends StatefulWidget {
  /// Externally provided
  const VideoView({Key? key, required this.controller}) : super(key: key);

  /// The controller of [VideoView].
  ///
  /// Internal functions such as initializing the controller.
  final VideoViewController controller;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends BaseState<VideoView> {
  bool _isFullScreen = false;

  @override
  void initState() {
    controller.addListener(listener);

    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(VideoView oldWidget) {
    if (oldWidget.controller != controller) {
      controller.addListener(listener);
    }

    super.didUpdateWidget(oldWidget);

    if (_isFullScreen != isControllerFullScreen) {
      controller.isFullScreen = _isFullScreen;
    }
  }

  Future<void> listener() async {
    if (value.isInitialized) {
      if (isControllerFullScreen && !_isFullScreen) {
        _isFullScreen = isControllerFullScreen;
        await _pushToFullScreen();
      } else if (_isFullScreen) {
        Navigator.of(
          context,
          rootNavigator: config.useRootNavigator,
        ).pop();
        _isFullScreen = false;
      }
    }
  }

  Future<void> _pushToFullScreen() async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final VideoViewControllerInherited child = _buildWidget();

        if (config.routePageBuilder == null) {
          return AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: config.backgroundColor,
              body: child,
            ),
          );
        }

        return config.routePageBuilder!(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );

    await controller.enterFullScreen();
    if (!mounted) {
      return;
    }
    await Navigator.of(
      context,
      rootNavigator: config.useRootNavigator,
    ).push(route);

    _isFullScreen = false;
    await controller.exitFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final double contextHeight = MediaQuery.of(context).size.height;
    final double height = config.height ?? contextHeight;
    final double statusBarHeight =
        config.canUseSafe ? MediaQueryData.fromWindow(window).padding.top : 0;

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(color: config.backgroundColor),
      constraints: BoxConstraints.expand(
        width: config.width,
        height:
            height < contextHeight ? height + statusBarHeight : contextHeight,
      ),
      child: _buildWidget(),
    );
  }

  VideoViewControllerInherited _buildWidget() {
    final Widget child = MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<VideoViewController>.value(value: controller),
        ChangeNotifierProvider<ControlsNotifier>(
          create: (_) => ControlsNotifier(),
        ),
      ],
      child:
          Consumer<VideoViewController>(builder: (_, __, ___) => _buildBody()),
    );

    return VideoViewControllerInherited(controller: controller, child: child);
  }

  Widget _buildBody() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (controller.isInitializing)
          config.placeholder ?? const CircularProgressIndicator(),
        if (value.isInitialized)
          InteractiveViewer(
            maxScale: config.maxScale,
            minScale: config.minScale,
            panEnabled: config.panEnabled,
            scaleEnabled: config.scaleEnabled,
            child: AspectRatio(
              aspectRatio: controller.aspectRatio,
              child: VideoPlayer(controller.videoPlayerController),
            ),
          ),
        if (config.overlay != null) config.overlay!,
        if (value.isBuffering)
          config.bufferingPlaceholder ?? const CircularProgressIndicator(),
        if (!controller.isInitializing &&
            !value.isInitialized &&
            value.hasError)
          Stack(
            children: <Widget>[
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  color: config.foregroundColor,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () async => Navigator.maybePop(context),
                ),
              Center(
                child: config.initFailBuilder?.call(
                      context,
                      _initialize,
                      local.loadFailed,
                      local.retry,
                    ) ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(local.loadFailed, style: defaultStyle),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _initialize,
                          child: Text(local.retry, style: defaultStyle),
                        ),
                      ],
                    ),
              )
            ],
          )
        else
          SafeArea(
            top: controller.isFullScreen,
            bottom: false,
            child: config.showControls
                ? const VideoViewControls()
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  bool get isControllerFullScreen => controller.isFullScreen;

  Future<void> _initialize() async => controller.initialize();

  TextStyle get defaultStyle => TextStyle(color: config.foregroundColor);

  VideoViewLocalizations get local => VideoViewLocalizations.of(context);

  VideoPlayerValue get value => controller.videoPlayerController.value;

  VideoViewConfig get config => controller.videoViewConfig;

  VideoViewController get controller => widget.controller;
}
