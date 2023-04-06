import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'utils/utils.dart';
import 'video_body.dart';
import 'video_config.dart';
import 'widgets/widgets.dart';

/// @Describe: The view of video.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class VideoView extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const VideoView({Key? key, required this.controller}) : super(key: key);

  /// The controller of [VideoView].
  ///
  /// Initialize [VideoPlayerController] and other functions.
  final VideoController controller;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends BaseState<VideoView> {
  /// Monitor fullscreen status changes.
  StreamSubscription<bool>? _fullScreenListener;

  @override
  void initState() {
    _fullScreenListener = controller.fullScreenStream?.stream.listen(_listener);

    super.initState();
  }

  @override
  void dispose() {
    _fullScreenListener?.cancel();

    super.dispose();
  }

  @override
  void deactivate() {
    /// Reset screen brightness.
    ScreenBrightnessUtil.resetScreenBrightness();

    super.deactivate();
  }

  Future<void> _listener(bool isFullScreen) async {
    if (isFullScreen) {
      await _pushToFullScreen();
    } else {
      controller.exitFullScreen();
      Navigator.of(context, rootNavigator: config.useRootNavigator).pop();
    }
  }

  Future<void> _pushToFullScreen() async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final VideoControllerInherited child = _buildWidget();

        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: config.backgroundColor,
            body: Center(child: child),
          ),
        );
      },
    );

    controller.enterFullScreen();
    await Navigator.of(context, rootNavigator: config.useRootNavigator)
        .push(route);
    controller.exitFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);

    final double contextHeight = data.size.height;
    final double height = config.height ?? contextHeight;
    final double statusBarHeight = config.useSafe ? data.padding.top : 0;

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(color: config.backgroundColor),
      constraints: BoxConstraints.expand(
        width: config.width ?? data.size.width,
        height:
            height < contextHeight ? height + statusBarHeight : contextHeight,
      ),
      child: _buildWidget(),
    );
  }

  VideoControllerInherited _buildWidget() {
    return VideoControllerInherited(
      controller: controller,
      child: ChangeNotifierProvider<VideoController>.value(
        value: controller,
        child: Selector<VideoController, VideoValue>(
          builder: (_, __, ___) =>
              LayoutBuilder(builder: (_, __) => VideoBody(constraints: __)),
          selector: (_, __) => __.value,
        ),
      ),
    );
  }

  VideoConfig get config => controller.config;

  VideoController get controller => widget.controller;
}

/// The controller of VideoView.
/// Add VideoPlayerController.
///
/// initialize, play, setLooping, pause, seekTo, setVolume
class VideoController extends ValueNotifier<VideoValue> {
  /// Constructs a [VideoController] playing a video from an asset.
  VideoController({
    required this.videoPlayerController,
    VideoConfig? videoConfig,
  }) : super(
          VideoValue(
            videoPlayerValue: VideoPlayerValue.uninitialized(),
            config: videoConfig ?? VideoConfig(),
          ),
        ) {
    _initialize();
  }

  /// The controller of video.
  final VideoPlayerController videoPlayerController;

  bool _isDisposed = false;

  /// Whether to initialize for the first time. If the initialization process
  /// fails for the first time, it will enter the infinite retry stage after
  /// re initialization.
  bool isFirstInit = true;

  /// Whether wakelock has been opened before it is opened.
  bool _beforeEnableWakelock = false;

  // ignore: public_member_api_docs
  static VideoController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VideoControllerInherited>()!
      .controller;

  /// Carry out the initialization operation of the video.
  Future<void> _initialize() async {
    /// Enable monitoring in full screen state.
    fullScreenStream ??= StreamController<bool>.broadcast();

    /// The setting before initialization.
    ///
    /// [setLooping], [setVolume] etc.
    final List<Future<void>> futures = <Future<void>>[
      setLooping(config.looping),
      setVolume(config.volume),
    ];
    unawaited(Future.wait(futures));

    if ((config.autoInitialize || config.autoPlay) && !value.isInitialized) {
      await initialize();
    }

    if (value.status.isSuccess) {
      await seekTo(config.startAt);
    }

    _beforeEnableWakelock = await Wakelock.enabled;
    if (config.allowedScreenSleep && !_beforeEnableWakelock) {
      await Wakelock.enable();
    }

    if (config.fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  /// Initialize the controller.
  Future<void> initialize() async {
    if (value.status.isLoading || value.status.isSuccess) {
      return;
    }

    value = value.copyWith(status: VideoInitStatus.loading);

    /// This is the process of video initialization to obtain the relevant
    /// status.
    try {
      await videoPlayerController.initialize();
      value = value.copyWith(
        status: videoPlayerController.value.isInitialized
            ? VideoInitStatus.success
            : VideoInitStatus.fail,
        duration: videoPlayerController.value.duration,
      );
    } catch (e) {
      value = value.copyWith(status: VideoInitStatus.fail);
    }

    if (value.status.isFail) {
      isFirstInit ? isFirstInit = false : await initialize();
    }

    if (value.status.isSuccess) {
      isFirstInit = false;

      /// Update [VideoPlayerValue].
      ///
      /// After initialization, obtain the aspect ratio and the direction of
      /// video in full screen mode.
      value = value.copyWith(
        videoPlayerValue: videoPlayerController.value,
        aspectRatio:
            config.aspectRatio ?? videoPlayerController.value.aspectRatio,
      );

      if (config.autoPlay) {
        await play();
      }
    }
  }

  /// Starts playing the video.
  Future<void> play() async {
    if (_isDisposed) {
      return;
    }

    if (!value.isInitialized) {
      return;
    }

    /// When there is an error in playing the video, it will be adjusted to
    /// the corresponding progress during initialization.
    if (value.position > Duration.zero) {
      await seekTo(value.position);
    }

    await videoPlayerController.play();
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);

    videoPlayerController.addListener(_listener);
  }

  /// Pauses the video.
  Future<void> pause() async {
    if (_isDisposed) {
      return;
    }

    if (!value.isInitialized || !value.isPlaying) {
      return;
    }

    await videoPlayerController.pause();
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Sets whether or not the video should loop after playing once.
  Future<void> setLooping(bool looping) async {
    if (_isDisposed) {
      return;
    }

    await videoPlayerController.setLooping(looping);
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Sets the audio volume of video.
  Future<void> setVolume(double volume) async {
    if (_isDisposed) {
      return;
    }

    await videoPlayerController.setVolume(volume);
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Sets the video's current timestamp to be at [moment].
  Future<void> seekTo(Duration? moment) async {
    if (moment == null) {
      return;
    }

    if (_isDisposed) {
      return;
    }

    await videoPlayerController.seekTo(moment);
    value = value.copyWith(
      videoPlayerValue: videoPlayerController.value,
      position: videoPlayerController.value.position,
    );
  }

  /// Sets the playback speed of video.
  ///
  /// Defaults to maximum speed.
  Future<void> setPlaybackSpeed({double? speed}) async {
    if (_isDisposed) {
      return;
    }

    await videoPlayerController.setPlaybackSpeed(speed ?? maxPlaybackSpeed);
    value = value.copyWith(videoPlayerValue: videoPlayerController.value);
  }

  /// Set the explicit and implicit of the controller.
  void setVisible(bool isVisible) {
    if (_isDisposed) {
      return;
    }

    if (value.isVisible == isVisible) {
      return;
    }

    value = value.copyWith(isVisible: isVisible);
  }

  /// Sets whether the controller is locked.
  void setLock(bool isLock) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(isLock: isLock);
  }

  /// Set whether to turn on the maximum speed playback.
  void setMaxPlaybackSpeed(bool isMaxPlaybackSpeed) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(isMaxPlaybackSpeed: isMaxPlaybackSpeed);
  }

  /// Set whether to display the adjustment progress of brightness or volume.
  void setVerticalDrag(bool isVerticalDrag) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(isVerticalDrag: isVerticalDrag);
  }

  /// Sets the type of adjustment.
  void setVerticalDragType(VerticalDragType? verticalDragType) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(verticalDragType: verticalDragType);
  }

  /// Sets the current value (brightness or volume).
  void setVerticalDragValue(double verticalDragValue) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(verticalDragValue: verticalDragValue);
  }

  /// Set whether the progress can be adjusted.
  void setDragProgress(bool isDragProgress) {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(isDragProgress: isDragProgress);
  }

  /// Sets the duration of the slide.
  void setDragDuration(Duration duration) {
    if (_isDisposed) {
      return;
    }

    if (duration < Duration.zero) {
      duration = Duration.zero;
    } else if (duration > value.duration) {
      duration = value.duration;
    }
    value = value.copyWith(dragDuration: duration);
  }

  /// Monitor fullscreen status changes.
  StreamController<bool>? fullScreenStream;

  /// Set whether the screen is full.
  void setFullScreen(bool isFullScreen, {bool isFire = true}) {
    if (_isDisposed) {
      return;
    }

    if (value.isFullScreen != isFullScreen) {
      value = value.copyWith(isFullScreen: isFullScreen);
      if (isFire) {
        fullScreenStream?.add(value.isFullScreen);
      }
    }
  }

  /// Enter full-screen mode.
  @protected
  void enterFullScreen() {
    if (!config.allowedScreenSleep) {
      Wakelock.enable();
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: <SystemUiOverlay>[],
    );
    SystemChrome.setPreferredOrientations(value.orientations);
  }

  /// Exit full-screen mode.
  @protected
  void exitFullScreen() {
    Wakelock.disable();

    setFullScreen(false, isFire: false);
    setLock(false);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: config.systemOverlaysExitFullScreen,
    );
    SystemChrome.setPreferredOrientations(
      config.deviceOrientationsExitFullScreen,
    );
  }

  /// Monitoring of video playback.
  void _listener() {
    if (_isDisposed) {
      return;
    }

    value = value.copyWith(videoPlayerValue: videoPlayerController.value);

    if (value.hasError || (value.isFinish && !value.isPlaying)) {
      reset();
    }

    if (!value.hasError) {
      value = value.copyWith(position: videoPlayerController.value.position);
    }

    if (maxPreviewTime != null) {
      final int positionMicr = value.position.inMicroseconds;
      final int maxPreviewTimeMicr = maxPreviewTime!.inMicroseconds;

      if (positionMicr >= maxPreviewTimeMicr && !value.isMaxPreviewTime) {
        setFullScreen(false);

        value = value.copyWith(isMaxPreviewTime: true);
        pause();
        reset();
      } else if (positionMicr < maxPreviewTimeMicr && value.isMaxPreviewTime) {
        value = value.copyWith(isMaxPreviewTime: false);
        play();
      }
    }
  }

  /// Reset properties, including isMaxPlaybackSpeed, isVerticalDrag,
  /// verticalDragValue, isDragProgress, dragDuration, etc.
  void reset() {
    if (value.isMaxPlaybackSpeed) {
      setPlaybackSpeed(speed: 1);
    }

    value = value.copyWith(
      isMaxPlaybackSpeed: false,
      isVerticalDrag: false,
      verticalDragValue: 0,
      isDragProgress: false,
      dragDuration: Duration.zero,
    );
  }

  void _fullScreenListener() {
    if (value.isPlaying && !value.isFullScreen) {
      setFullScreen(true);
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  /// Maximum playback speed.
  double get maxPlaybackSpeed =>
      defaultTargetPlatform == TargetPlatform.iOS ? 2.0 : 3.0;

  /// Maximum preview duration.
  Duration? get maxPreviewTime => config.maxPreviewTime;

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    if (!_beforeEnableWakelock) {
      Wakelock.disable();
    }
    videoPlayerController
      ..removeListener(_listener)
      ..dispose();
    fullScreenStream?.close();
    _isDisposed = true;

    super.dispose();
  }

  /// Config.
  VideoConfig get config => value.config;
}

/// The duration, current position, buffering state, error state and settings
/// of a [VideoPlayerController].
///
/// The isVisible, isLock, isMaxSpeed, isVerticalDrag, verticalDragType,
/// currentVerticalDragValue, isDragProgress, dragDuration of a VideoControls.
class VideoValue {
  /// Constructs a video with the given values. Only [videoPlayerValue] is
  /// required. The rest will initialize with default values when unset.
  VideoValue({
    required this.videoPlayerValue,
    required this.config,
    this.status = VideoInitStatus.none,
    this.aspectRatio = 1.0,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isFullScreen = false,
    this.isVisible = false,
    this.isLock = false,
    this.isMaxPlaybackSpeed = false,
    this.isVerticalDrag = false,
    this.verticalDragType,
    this.verticalDragValue = 0,
    this.isDragProgress = false,
    this.dragDuration = Duration.zero,
    this.isMaxPreviewTime = false,
  });

  /// The duration, current position, buffering state, error state and settings
  /// of a [VideoPlayerController].
  final VideoPlayerValue videoPlayerValue;

  /// The config of [VideoView].
  final VideoConfig config;

  /// The current initialization status of the video.
  final VideoInitStatus status;

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

  /// Show or hide VideoControls.
  final bool isVisible;

  /// Whether to lock the controller
  final bool isLock;

  /// Whether to play video at the maximum rate.
  final bool isMaxPlaybackSpeed;

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

  /// Whether or not the maximum preview duration has been reached.
  final bool isMaxPreviewTime;

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
    if (config.deviceOrientationsEnterFullScreen != null) {
      return config.deviceOrientationsEnterFullScreen!;
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
  VideoValue copyWith({
    VideoPlayerValue? videoPlayerValue,
    VideoConfig? config,
    VideoInitStatus? status,
    double? aspectRatio,
    Duration? duration,
    Duration? position,
    bool? isFullScreen,
    bool? isVisible,
    bool? isLock,
    bool? isMaxPlaybackSpeed,
    bool? isVerticalDrag,
    VerticalDragType? verticalDragType,
    double? verticalDragValue,
    bool? isDragProgress,
    Duration? dragDuration,
    bool? isMaxPreviewTime,
  }) {
    return VideoValue(
      videoPlayerValue: videoPlayerValue ?? this.videoPlayerValue,
      config: config ?? this.config,
      status: status ?? this.status,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isVisible: isVisible ?? this.isVisible,
      isLock: isLock ?? this.isLock,
      isMaxPlaybackSpeed: isMaxPlaybackSpeed ?? this.isMaxPlaybackSpeed,
      isVerticalDrag: isVerticalDrag ?? this.isVerticalDrag,
      verticalDragType: verticalDragType ?? this.verticalDragType,
      verticalDragValue: verticalDragValue ?? this.verticalDragValue,
      isDragProgress: isDragProgress ?? this.isDragProgress,
      dragDuration: dragDuration ?? this.dragDuration,
      isMaxPreviewTime: isMaxPreviewTime ?? this.isMaxPreviewTime,
    );
  }
}

/// The widget used to pass [VideoController].
class VideoControllerInherited extends InheritedWidget {
  // ignore: public_member_api_docs
  const VideoControllerInherited({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  /// The controller of [VideoView].
  final VideoController controller;

  @override
  bool updateShouldNotify(covariant VideoControllerInherited oldWidget) =>
      controller != oldWidget.controller;
}

/// Vertical movement adjusts the volume or brightness.
enum VerticalDragType {
  // ignore: public_member_api_docs
  brightness,

  // ignore: public_member_api_docs
  volume,
}

/// Initialization status of video.
enum VideoInitStatus {
  /// Waiting for initialization.
  none,

  /// Initializing.
  loading,

  /// Initialization successful.
  success,

  /// Initialization failed.
  fail,
}

/// Extension of [VideoInitStatus].
extension VideoInitStatusExtension on VideoInitStatus {
  /// Whether the status is "successful".
  bool get isNone => this == VideoInitStatus.none;

  /// Whether the status is "failed".
  bool get isLoading => this == VideoInitStatus.loading;

  /// Whether the status is "successful".
  bool get isSuccess => this == VideoInitStatus.success;

  /// Whether the status is "failed".
  bool get isFail => this == VideoInitStatus.fail;
}

/// Position of text for video progress
enum VideoTextPosition {
  /// Are located on the left side of the progress bar.
  ltl,

  /// Are located on the right side of the progress bar.
  rtr,

  /// The current progress is to the left of the progress bar.
  /// The total duration is on the right side of the progress bar.
  ltr,

  /// Do not display.
  none,
}

/// Used to configure the VideoProgressBar widget's colors for how it
/// describes the video's status.
///
/// The widget uses default colors that are customizeable through this class.
class VideoProgressBarColors {
  /// Any property can be set to any paint. They each have defaults.
  VideoProgressBarColors({
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, .4),
    this.playedColor = const Color.fromRGBO(255, 255, 255, 1),
    this.bufferedColor = const Color.fromRGBO(255, 255, 255, .7),
    this.handleColor = const Color.fromRGBO(255, 255, 255, 1),
  }) : handleMoreColor = handleColor.withOpacity(.7);

  /// [backgroundColor] defaults to white at 40% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  final Color backgroundColor;

  /// [playedColor] defaults to white. This fills up a portion of the
  /// VideoProgressBar to represent how much of the video has played so far.
  final Color playedColor;

  /// [bufferedColor] defaults to white at 70% opacity. This fills up a portion
  /// of VideoProgressBar to represent how much of the video has buffered so
  /// far.
  final Color bufferedColor;

  /// [handleColor] defaults to white. To represent the playback position of
  /// the current video.
  final Color handleColor;

  /// [handleMoreColor] defaults to white at 70% opacity. To represent the
  /// playback position of the current video.
  final Color handleMoreColor;
}
