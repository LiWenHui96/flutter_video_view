import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'controls/video_view_controls.dart';
import 'local/video_view_localizations.dart';
import 'notifier/controls_notifier.dart';
import 'utils/util_brightness.dart';
import 'video_view_config.dart';
import 'widgets/animated_play_pause.dart';
import 'widgets/base_state.dart';

/// @Describe: The view of video.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class VideoView extends StatefulWidget {
  // ignore: public_member_api_docs
  const VideoView({Key? key, required this.controller}) : super(key: key);

  /// The controller of [VideoView].
  ///
  /// Initialize [VideoPlayerController] and other functions.
  final VideoViewController controller;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends BaseState<VideoView> {
  late ControlsNotifier _notifier;

  bool _isFullScreen = false;

  @override
  void initState() {
    _notifier = ControlsNotifier();
    controller.addListener(listener);

    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();

    /// Reset screen brightness.
    ScreenBrightnessUtil.resetScreenBrightness();

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
        Navigator.of(context, rootNavigator: config.useRootNavigator).pop();
        _notifier.isLock = false;
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

        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: config.backgroundColor,
            body: child,
          ),
        );
      },
    );

    await controller.enterFullScreen();
    if (!mounted) {
      return;
    }
    await Navigator.of(context, rootNavigator: config.useRootNavigator)
        .push(route);

    _isFullScreen = false;
    _notifier.isLock = false;
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
        ChangeNotifierProvider<ControlsNotifier>.value(value: _notifier),
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
        if (controller.videoInitState == VideoInitState.success)
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
        SafeArea(
          top: false,
          bottom: false,
          child: config.showControls
              ? const VideoViewControls()
              : const SizedBox.shrink(),
        ),
        _buildPlaceholderWidget(),
      ],
    );
  }

  Widget _buildPlaceholderWidget() {
    final Map<VideoInitState, Widget> map =
        config.placeholderBuilder ?? <VideoInitState, Widget>{};

    if (controller.videoInitState == VideoInitState.none) {
      return map[VideoInitState.none] ??
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedPlayPause(
                isPlaying: value.isPlaying,
                size: 24,
                onPressed: _initialize,
              ),
            ),
          );
    } else if (controller.videoInitState == VideoInitState.initializing) {
      return map[VideoInitState.initializing] ??
          const CircularProgressIndicator();
    } else if (controller.videoInitState == VideoInitState.fail) {
      return map[VideoInitState.fail] ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(local.loadFailed, style: defaultStyle),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _initialize,
                child: Text(local.retry, style: defaultStyle),
              ),
            ],
          );
    }

    return const SizedBox.shrink();
  }

  bool get isControllerFullScreen => controller.isFullScreen;

  Future<void> _initialize() async => controller.initialize();

  TextStyle get defaultStyle => TextStyle(
        fontSize: config.defaultTextSize,
        color: config.foregroundColor,
      );

  VideoViewLocalizations get local => VideoViewLocalizations.of(context);

  VideoPlayerValue get value => controller.videoPlayerController.value;

  VideoViewConfig get config => controller.videoViewConfig;

  VideoViewController get controller => widget.controller;
}

/// The controller of VideoView.
class VideoViewController extends _VideoViewNotifier {
  /// Constructs a [VideoViewController] playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not
  /// be null. The [package] argument must be non-null when the asset comes from
  /// a package and null otherwise.
  VideoViewController.assets(
    String dataSource, {
    String? package,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    VideoViewConfig? videoViewConfig,
  }) : super(
          VideoPlayerController.asset(
            dataSource,
            package: package,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig ?? VideoViewConfig(),
        );

  /// Constructs a [VideoViewController] playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not
  /// be null.
  /// **Android only**: The [formatHint] option allows the caller to override
  /// the video format detection code.
  /// [httpHeaders] option allows to specify HTTP headers
  /// for the request to the [dataSource].
  VideoViewController.network(
    String dataSource, {
    VideoFormat? formatHint,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    Map<String, String>? httpHeaders,
    VideoViewConfig? videoViewConfig,
  }) : super(
          VideoPlayerController.network(
            dataSource,
            formatHint: formatHint,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
            httpHeaders: httpHeaders ?? <String, String>{},
          ),
          videoViewConfig: videoViewConfig ?? VideoViewConfig(),
        );

  /// Constructs a [VideoViewController] playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  VideoViewController.file(
    File file, {
    this.closedCaptionFile,
    this.videoPlayerOptions,
    VideoViewConfig? videoViewConfig,
  }) : super(
          VideoPlayerController.file(
            file,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig ?? VideoViewConfig(),
        );

  /// Constructs a [VideoViewController] playing a video from a contentUri.
  ///
  /// This will load the video from the input content-URI.
  /// This is supported on Android only.
  VideoViewController.contentUri(
    Uri contentUri, {
    this.closedCaptionFile,
    this.videoPlayerOptions,
    VideoViewConfig? videoViewConfig,
  }) : super(
          VideoPlayerController.contentUri(
            contentUri,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig ?? VideoViewConfig(),
        );

  // ignore: public_member_api_docs
  final Future<ClosedCaptionFile>? closedCaptionFile;

  /// Provide additional configuration options (optional). Like setting the
  /// audio mode to mix
  final VideoPlayerOptions? videoPlayerOptions;

  // ignore: public_member_api_docs
  static VideoViewController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VideoViewControllerInherited>()!
      .controller;
}

/// Basic controller and added VideoPlayerController.
///
/// initialize, play, setLooping, pause, seekTo, setVolume
abstract class _VideoViewNotifier extends ChangeNotifier {
  _VideoViewNotifier(
    this.videoPlayerController, {
    required this.videoViewConfig,
  }) {
    _initialize();
  }

  /// The controller of video.
  final VideoPlayerController videoPlayerController;

  /// The config of VideoView.
  final VideoViewConfig videoViewConfig;

  /// Whether to initialize for the first time. If the initialization process
  /// fails for the first time, it will enter the infinite retry stage after
  /// re initialization.
  bool isFirstInit = true;

  /// Whether wakelock has been opened before it is opened.
  bool _beforeEnableWakelock = false;

  VideoInitState _videoInitState = VideoInitState.none;

  /// The current initialization state of the video.
  VideoInitState get videoInitState => _videoInitState;

  set videoInitState(VideoInitState value) {
    _videoInitState = value;
    notifyListeners();
  }

  _VideoOrientation _videoOrientation = _VideoOrientation.other;

  /// Whether it is portrait in full screen state.
  bool get isPortrait => orientations.any(
        (DeviceOrientation e) =>
            e == DeviceOrientation.portraitUp ||
            e == DeviceOrientation.portraitDown,
      );

  /// Device orientation after full screen.
  List<DeviceOrientation> get orientations {
    switch (_videoOrientation) {
      case _VideoOrientation.custom:
        return videoViewConfig.deviceOrientationsEnterFullScreen!;
      case _VideoOrientation.landscape:
        return <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
      case _VideoOrientation.portrait:
        return <DeviceOrientation>[
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ];
      case _VideoOrientation.other:
        return DeviceOrientation.values;
    }
  }

  double _aspectRatio = 1;

  /// The aspectRatio of video.
  double get aspectRatio => _aspectRatio;

  bool _isFullScreen = false;

  /// Whether it is full screen mode.
  bool get isFullScreen => _isFullScreen;

  set isFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }

  Future<void> _initialize() async {
    await setLooping(looping: videoViewConfig.looping);
    await setVolume(1);
    await seekTo(videoViewConfig.startAt ?? Duration.zero);

    _beforeEnableWakelock = await Wakelock.enabled;
    if (videoViewConfig.allowedScreenSleep && !_beforeEnableWakelock) {
      await Wakelock.enable();
    }

    if ((videoViewConfig.autoInitialize || videoViewConfig.autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await initialize();
    }

    if (videoViewConfig.fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  bool get isPlaying => videoPlayerController.value.isPlaying;

  bool get isInitialized => videoPlayerController.value.isInitialized;

  bool get isLooping => videoPlayerController.value.isLooping;

  bool get isBuffering => videoPlayerController.value.isBuffering;

  bool get hasError => videoPlayerController.value.hasError;

  String? get errorDescription => videoPlayerController.value.errorDescription;

  double get playbackSpeed => videoPlayerController.value.playbackSpeed;

  /// Initialize the controller.
  Future<void> initialize() async {
    /// This is the process of video initialization to obtain the relevant
    /// status.
    try {
      videoInitState = VideoInitState.initializing;
      await videoPlayerController.initialize();
      videoInitState = videoPlayerController.value.isInitialized
          ? VideoInitState.success
          : VideoInitState.fail;
    } catch (e) {
      videoInitState = VideoInitState.fail;
    }

    if (videoInitState == VideoInitState.fail) {
      if (isFirstInit) {
        isFirstInit = false;
      } else {
        await initialize();
      }
    }

    /// After initialization, obtain the aspect ratio and the direction of
    /// video in full screen mode.
    final VideoPlayerValue value = videoPlayerController.value;
    if (value.isInitialized) {
      _aspectRatio = videoViewConfig.aspectRatio ?? value.aspectRatio;

      final double videoWidth = value.size.width;
      final double videoHeight = value.size.height;
      final bool isLandscapeVideo = videoWidth > videoHeight;
      final bool isPortraitVideo = videoWidth < videoHeight;

      if (videoViewConfig.deviceOrientationsEnterFullScreen != null) {
        /// Optional user preferred settings.
        _videoOrientation = _VideoOrientation.custom;
      } else if (isLandscapeVideo) {
        /// Video w > h means we force landscape.
        _videoOrientation = _VideoOrientation.landscape;
      } else if (isPortraitVideo) {
        /// Video h > w means we force portrait.
        _videoOrientation = _VideoOrientation.portrait;
      } else {
        /// Otherwise if h == w (square video).
        _videoOrientation = _VideoOrientation.other;
      }

      notifyListeners();

      if (videoViewConfig.autoPlay) {
        await play();
      }
    }
  }

  /// Sets whether or not the video should loop after playing once.
  Future<void> setLooping({bool looping = false}) async {
    await videoPlayerController.setLooping(looping);
  }

  /// Starts playing the video.
  Future<void> play() async {
    if (!videoPlayerController.value.isInitialized) {
      return;
    }
    await videoPlayerController.play();
  }

  /// Pauses the video.
  Future<void> pause() async {
    if (!videoPlayerController.value.isInitialized) {
      return;
    }
    await videoPlayerController.pause();
  }

  /// Sets the video's current timestamp to be at [moment].
  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  /// Sets the audio volume of video.
  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }

  /// Sets the playback speed of video.
  ///
  /// Defaults to maximum speed.
  Future<void> setPlaybackSpeed({double? speed}) async {
    await videoPlayerController.setPlaybackSpeed(speed ?? maxSpeed);
  }

  double get maxSpeed =>
      defaultTargetPlatform == TargetPlatform.iOS ? 2.0 : 3.0;

  /// Enter full-screen mode.
  @protected
  Future<void> enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays:
          videoViewConfig.systemOverlaysEnterFullScreen ?? <SystemUiOverlay>[],
    );
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Exit full-screen mode.
  @protected
  Future<void> exitFullScreen() async {
    isFullScreen = false;
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: videoViewConfig.systemOverlaysExitFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      videoViewConfig.deviceOrientationsExitFullScreen,
    );
  }

  /// Switch full-screen/non-full-screen mode.
  void toggleFullScreen() {
    isFullScreen = !isFullScreen;
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      isFullScreen = true;
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  @override
  void dispose() {
    if (!_beforeEnableWakelock) {
      Wakelock.disable();
    }
    videoPlayerController.dispose();

    super.dispose();
  }
}

// ignore: public_member_api_docs
typedef VideoViewRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  VideoViewControllerInherited controllerProvider,
);

// ignore: public_member_api_docs
class VideoViewControllerInherited extends InheritedWidget {
  // ignore: public_member_api_docs
  const VideoViewControllerInherited({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  // ignore: public_member_api_docs
  final VideoViewController controller;

  @override
  bool updateShouldNotify(covariant VideoViewControllerInherited oldWidget) =>
      controller != oldWidget.controller;
}

enum _VideoOrientation { custom, landscape, portrait, other }
