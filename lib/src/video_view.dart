import 'dart:async';
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
import 'utils/util_brightness.dart';
import 'utils/util_event.dart';
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
  @override
  void initState() {
    EventBusUtil.onFullScreen().listen((bool isFullScreen) async {
      if (isFullScreen) {
        await _pushToFullScreen();
      } else {
        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: config.useRootNavigator).pop();
        await controller.exitFullScreen();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();

    /// Reset screen brightness.
    ScreenBrightnessUtil.resetScreenBrightness();

    super.dispose();
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
      width: config.width,
      height: height < contextHeight ? height + statusBarHeight : contextHeight,
      child: _buildWidget(),
    );
  }

  VideoViewControllerInherited _buildWidget() {
    final Widget child = ChangeNotifierProvider<VideoViewController>.value(
      value: controller,
      child:
          Consumer<VideoViewController>(builder: (_, __, ___) => _buildBody()),
    );

    return VideoViewControllerInherited(controller: controller, child: child);
  }

  Widget _buildBody() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (value.videoInitState == VideoInitState.success)
          InteractiveViewer(
            maxScale: config.maxScale,
            minScale: config.minScale,
            panEnabled: config.panEnabled,
            scaleEnabled: config.scaleEnabled,
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(controller.videoPlayerController),
            ),
          ),
        if (config.overlay != null) config.overlay!,
        if (!value.isFinish && value.isBuffering)
          config.bufferingPlaceholder ?? const CircularProgressIndicator(),
        SafeArea(
          top: value.isPortrait && value.isFullScreen,
          bottom: value.isPortrait && value.isFullScreen,
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

    if (value.videoInitState == VideoInitState.none) {
      return map[VideoInitState.none] ??
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedPlayPause(
                isPlaying: false,
                size: 24,
                onPressed: _initialize,
              ),
            ),
          );
    } else if (value.videoInitState == VideoInitState.initializing) {
      return map[VideoInitState.initializing] ??
          const CircularProgressIndicator();
    } else if (value.videoInitState == VideoInitState.fail) {
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

  bool get isControllerFullScreen => value.isFullScreen;

  Future<void> _initialize() async => controller.initialize();

  TextStyle get defaultStyle => TextStyle(
        fontSize: config.defaultTextSize,
        color: config.foregroundColor,
      );

  VideoViewLocalizations get local => VideoViewLocalizations.of(context);

  VideoViewValue get value => controller.value;

  VideoViewConfig get config => controller.config;

  VideoViewController get controller => widget.controller;
}

/// The controller of VideoView.
class VideoViewController extends VideoViewNotifier {
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
    this.videoViewConfig,
  }) : super(
          VideoPlayerController.asset(
            dataSource,
            package: package,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig,
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
    this.videoViewConfig,
  }) : super(
          VideoPlayerController.network(
            dataSource,
            formatHint: formatHint,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
            httpHeaders: httpHeaders ?? <String, String>{},
          ),
          videoViewConfig: videoViewConfig,
        );

  /// Constructs a [VideoViewController] playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  VideoViewController.file(
    File file, {
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.videoViewConfig,
  }) : super(
          VideoPlayerController.file(
            file,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig,
        );

  /// Constructs a [VideoViewController] playing a video from a contentUri.
  ///
  /// This will load the video from the input content-URI.
  /// This is supported on Android only.
  VideoViewController.contentUri(
    Uri contentUri, {
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.videoViewConfig,
  }) : super(
          VideoPlayerController.contentUri(
            contentUri,
            closedCaptionFile: closedCaptionFile,
            videoPlayerOptions: videoPlayerOptions,
          ),
          videoViewConfig: videoViewConfig,
        );

  // ignore: public_member_api_docs
  final Future<ClosedCaptionFile>? closedCaptionFile;

  /// Provide additional configuration options (optional). Like setting the
  /// audio mode to mix
  final VideoPlayerOptions? videoPlayerOptions;

  /// The config of [VideoView].
  final VideoViewConfig? videoViewConfig;

  // ignore: public_member_api_docs
  static VideoViewController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VideoViewControllerInherited>()!
      .controller;
}

/// Basic controller and added VideoPlayerController.
///
/// initialize, play, setLooping, pause, seekTo, setVolume
abstract class VideoViewNotifier extends ValueNotifier<VideoViewValue> {
  // ignore: public_member_api_docs
  VideoViewNotifier(
    this.videoPlayerController, {
    VideoViewConfig? videoViewConfig,
  }) : super(
          VideoViewValue(
            videoPlayerValue: VideoPlayerValue.uninitialized(),
            videoViewConfig: videoViewConfig ?? VideoViewConfig(),
          ),
        ) {
    _initialize();
  }

  /// The controller of video.
  final VideoPlayerController videoPlayerController;

  Timer? _timer;
  bool _isDisposed = false;

  /// Whether to initialize for the first time. If the initialization process
  /// fails for the first time, it will enter the infinite retry stage after
  /// re initialization.
  bool isFirstInit = true;

  /// Whether wakelock has been opened before it is opened.
  bool _beforeEnableWakelock = false;

  Future<void> _initialize() async {
    await setLooping(looping: config.looping);
    await setVolume(config.volume);
    await seekTo(config.startAt);

    _beforeEnableWakelock = await Wakelock.enabled;
    if (config.allowedScreenSleep && !_beforeEnableWakelock) {
      await Wakelock.enable();
    }

    if ((config.autoInitialize || config.autoPlay) && !value.isInitialized) {
      await initialize();
    }

    if (config.fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  /// Initialize the controller.
  Future<void> initialize() async {
    value = value.copyWith(videoInitState: VideoInitState.initializing);

    /// This is the process of video initialization to obtain the relevant
    /// status.
    try {
      await videoPlayerController.initialize();
      value = value.copyWith(
        videoInitState: videoPlayerController.value.isInitialized
            ? VideoInitState.success
            : VideoInitState.fail,
        duration: videoPlayerController.value.duration,
      );
    } catch (e) {
      value = value.copyWith(videoInitState: VideoInitState.fail);
    }

    if (value.videoInitState == VideoInitState.fail) {
      isFirstInit ? isFirstInit = false : await initialize();
    }

    if (value.videoInitState == VideoInitState.success) {
      isFirstInit = false;

      /// Update [VideoPlayerValue].
      value = value.copyWith(
        videoPlayerValue: videoPlayerController.value,
        aspectRatio:
            config.aspectRatio ?? videoPlayerController.value.aspectRatio,
      );

      /// After initialization, obtain the aspect ratio and the direction of
      /// video in full screen mode.
      if (config.autoPlay) {
        await play();
      }
    }
  }

  /// Sets whether or not the video should loop after playing once.
  Future<void> setLooping({bool looping = false}) async {
    await videoPlayerController.setLooping(looping);
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Starts playing the video.
  Future<void> play() async {
    if (value.isInitialized) {
      /// When there is an error in playing the video, it will be adjusted to
      /// the corresponding progress during initialization.
      if (value.position > Duration.zero) {
        await seekTo(value.position);
      }

      await videoPlayerController.play();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        if (_isDisposed) {
          _timer?.cancel();
          return;
        }
        value = value.copyWith(videoPlayerValue: videoPlayerController.value);

        if (value.hasError || (value.isFinish && !value.isPlaying)) {
          _timer?.cancel();
          if (value.isMaxSpeed) {
            await setPlaybackSpeed(speed: 1);
          }

          value = value.copyWith(
            isMaxSpeed: false,
            isVerticalDrag: false,
            verticalDragValue: 0,
            isDragProgress: false,
            dragDuration: Duration.zero,
          );
        }

        if (!value.hasError) {
          value =
              value.copyWith(position: videoPlayerController.value.position);
        } else {
          await initialize().then((_) => play());
        }
      });
    }
  }

  /// Pauses the video.
  Future<void> pause() async {
    if (value.isInitialized) {
      _timer?.cancel();
      await videoPlayerController.pause();
      if (_isDisposed) {
        return;
      }
      value = value.copyWith(videoPlayerValue: videoPlayerController.value);
    }
  }

  /// Sets the video's current timestamp to be at [moment].
  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(
      videoPlayerValue: videoPlayerController.value,
      position: videoPlayerController.value.position,
    );
  }

  /// Sets the audio volume of video.
  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Sets the playback speed of video.
  ///
  /// Defaults to maximum speed.
  Future<void> setPlaybackSpeed({double? speed}) async {
    await videoPlayerController.setPlaybackSpeed(speed ?? maxSpeed);
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Set the explicit and implicit of the controller.
  void setVisible({required bool isVisible}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(isVisible: isVisible);
  }

  /// Sets whether the controller is locked.
  void setLock({required bool isLock}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(isLock: isLock);
  }

  /// Set whether to turn on the maximum speed playback.
  void setMaxSpeed({required bool isMaxSpeed}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(isMaxSpeed: isMaxSpeed);
  }

  /// Set whether to display the adjustment progress of brightness or volume.
  void setVerticalDrag({required bool isVerticalDrag}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(isVerticalDrag: isVerticalDrag);
  }

  /// Sets the type of adjustment.
  void setVerticalDragType({VerticalDragType? verticalDragType}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(verticalDragType: verticalDragType);
  }

  /// Sets the current value (brightness or volume).
  void setVerticalDragValue({required double verticalDragValue}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(verticalDragValue: verticalDragValue);
  }

  /// Set whether the progress can be adjusted.
  void setDragProgress({required bool isDragProgress}) {
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(isDragProgress: isDragProgress);
  }

  /// Sets the duration of the slide.
  void setDragDuration(Duration duration) {
    if (duration < Duration.zero) {
      duration = Duration.zero;
    } else if (duration > value.duration) {
      duration = value.duration;
    }
    if (_isDisposed) {
      return;
    }
    value = value.copyWith(dragDuration: duration);
  }

  /// Maximum playback speed.
  double get maxSpeed =>
      defaultTargetPlatform == TargetPlatform.iOS ? 2.0 : 3.0;

  /// Set whether the screen is full.
  void setFullScreen({required bool isFullScreen, bool isFire = true}) {
    if (_isDisposed) {
      return;
    }
    if (value.isFullScreen != isFullScreen) {
      value = value.copyWith(isFullScreen: isFullScreen);
      if (isFire) {
        EventBusUtil.fireFullScreen(isFullScreen: value.isFullScreen);
      }
    }
  }

  /// Enter full-screen mode.
  @protected
  Future<void> enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: config.systemOverlaysEnterFullScreen ?? <SystemUiOverlay>[],
    );
    await SystemChrome.setPreferredOrientations(value.orientations);
  }

  /// Exit full-screen mode.
  @protected
  Future<void> exitFullScreen() async {
    setFullScreen(isFullScreen: false, isFire: false);
    setLock(isLock: false);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: config.systemOverlaysExitFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      config.deviceOrientationsExitFullScreen,
    );
  }

  Future<void> _fullScreenListener() async {
    if (value.isPlaying && !value.isFullScreen) {
      setFullScreen(isFullScreen: true);
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    if (!_beforeEnableWakelock) {
      Wakelock.disable();
    }
    videoPlayerController.dispose();
    _timer?.cancel();
    _isDisposed = true;

    super.dispose();
  }

  /// Config.
  VideoViewConfig get config => value.videoViewConfig;
}

/// The duration, current position, buffering state, error state and settings
/// of a [VideoPlayerController].
///
/// The isVisible, isLock, isMaxSpeed, isVerticalDrag, verticalDragType,
/// currentVerticalDragValue, isDragProgress, dragDuration of a
/// [VideoViewControls].
class VideoViewValue {
  /// Constructs a video with the given values. Only [videoPlayerValue] is
  /// required. The rest will initialize with default values when unset.
  VideoViewValue({
    required this.videoPlayerValue,
    required this.videoViewConfig,
    this.videoInitState = VideoInitState.none,
    this.aspectRatio = 1.0,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isFullScreen = false,
    this.isVisible = false,
    this.isLock = false,
    this.isMaxSpeed = false,
    this.isVerticalDrag = false,
    this.verticalDragType,
    this.verticalDragValue = 0,
    this.isDragProgress = false,
    this.dragDuration = Duration.zero,
  });

  /// The duration, current position, buffering state, error state and settings
  /// of a [VideoPlayerController].
  final VideoPlayerValue videoPlayerValue;

  /// The config of [VideoView].
  final VideoViewConfig videoViewConfig;

  /// The current initialization state of the video.
  VideoInitState videoInitState;

  /// The parameters set by the developer are preferred.
  final double aspectRatio;

  /// The total duration of the video.
  ///
  /// The duration is [Duration.zero] if the video hasn't been initialized.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// Whether it is full screen mode.
  final bool isFullScreen;

  /// Show or hide [VideoViewControls].
  final bool isVisible;

  /// Whether to lock the controller
  final bool isLock;

  /// Whether to play video at the maximum rate.
  final bool isMaxSpeed;

  /// Whether to display the adjustment progress of brightness or volume.
  final bool isVerticalDrag;

  /// Adjust brightness or volume.
  final VerticalDragType? verticalDragType;

  /// Brightness value or volume value.
  final double verticalDragValue;

  /// Whether the progress is being adjusted.
  final bool isDragProgress;

  /// Adjusted progress value.
  final Duration dragDuration;

  /// Indicates whether or not the video has been loaded and is ready to play.
  bool get isInitialized => videoPlayerValue.isInitialized;

  /// True if the video is playing. False if it's paused.
  bool get isPlaying => videoPlayerValue.isPlaying;

  /// True if the video is looping.
  bool get isLooping => videoPlayerValue.isLooping;

  /// True if the video is finish.
  bool get isFinish =>
      !isLooping && duration != Duration.zero && position >= duration;

  /// True if the video is currently buffering.
  bool get isBuffering => videoPlayerValue.isBuffering;

  /// The current volume of the playback.
  double get volume => videoPlayerValue.volume;

  /// The current speed of the playback.
  double get playbackSpeed => videoPlayerValue.playbackSpeed;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => videoPlayerValue.hasError;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is `null`.
  String? get errorDescription => videoPlayerValue.errorDescription;

  /// The [size] of the currently loaded video.
  Size get size => videoPlayerValue.size;

  /// Degrees to rotate the video (clockwise) so it is displayed correctly.
  int get rotationCorrection => videoPlayerValue.rotationCorrection;

  /// The [Caption] that should be displayed based on the current [position].
  ///
  /// This field will never be null. If there is no caption for the current
  /// [position], this will be a [Caption.none] object.
  Caption get caption => videoPlayerValue.caption;

  /// The [Duration] that should be used to offset the current [position] to
  /// get the correct [Caption].
  ///
  /// Defaults to Duration.zero.
  Duration get captionOffset => videoPlayerValue.captionOffset;

  /// The currently buffered ranges.
  List<DurationRange> get buffered => videoPlayerValue.buffered;

  /// Whether it is portrait in full-screen.
  bool get isPortrait => orientations.any(
        (DeviceOrientation e) =>
            e == DeviceOrientation.portraitUp ||
            e == DeviceOrientation.portraitDown,
      );

  /// Device orientation after full screen.
  List<DeviceOrientation> get orientations {
    if (videoViewConfig.deviceOrientationsEnterFullScreen != null) {
      return videoViewConfig.deviceOrientationsEnterFullScreen!;
    } else if (size.width > size.height) {
      return <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    } else if (size.width < size.height) {
      return <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    } else {
      return DeviceOrientation.values;
    }
  }

  /// Sliding time interval.
  Duration get dragTotalDuration {
    if (duration < const Duration(minutes: 1)) {
      return const Duration(seconds: 10);
    } else if (duration < const Duration(minutes: 10)) {
      return const Duration(minutes: 1);
    } else if (duration < const Duration(minutes: 30)) {
      return const Duration(minutes: 5);
    } else if (duration < const Duration(hours: 1)) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 15);
    }
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWith].
  VideoViewValue copyWith({
    VideoPlayerValue? videoPlayerValue,
    VideoViewConfig? videoViewConfig,
    VideoInitState? videoInitState,
    double? aspectRatio,
    Duration? duration,
    Duration? position,
    bool? isFullScreen,
    bool? isVisible,
    bool? isLock,
    bool? isMaxSpeed,
    bool? isVerticalDrag,
    VerticalDragType? verticalDragType,
    double? verticalDragValue,
    bool? isDragProgress,
    Duration? dragDuration,
  }) {
    return VideoViewValue(
      videoPlayerValue: videoPlayerValue ?? this.videoPlayerValue,
      videoViewConfig: videoViewConfig ?? this.videoViewConfig,
      videoInitState: videoInitState ?? this.videoInitState,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isVisible: isVisible ?? this.isVisible,
      isLock: isLock ?? this.isLock,
      isMaxSpeed: isMaxSpeed ?? this.isMaxSpeed,
      isVerticalDrag: isVerticalDrag ?? this.isVerticalDrag,
      verticalDragType: verticalDragType ?? this.verticalDragType,
      verticalDragValue: verticalDragValue ?? this.verticalDragValue,
      isDragProgress: isDragProgress ?? this.isDragProgress,
      dragDuration: dragDuration ?? this.dragDuration,
    );
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

/// Vertical movement adjusts the volume or brightness.
enum VerticalDragType {
  // ignore: public_member_api_docs
  brightness,
  // ignore: public_member_api_docs
  volume,
}
