import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/src/inside.dart';
import 'package:flutter_video_view/src/video_view_config.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

export 'package:provider/provider.dart';
export 'package:video_player/video_player.dart';

/// @Describe: Controller base class, added VideoPlayerController.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/15

/// initialize, play, setLooping, pause, seekTo, setVolume
abstract class VideoViewNotifier extends BaseNotifier {
  /// Externally provided
  VideoViewNotifier({
    required this.videoPlayerController,
    this.videoViewConfig,
  }) {
    _initialize();
  }

  /// The controller of video.
  final VideoPlayerController videoPlayerController;

  /// The config of VideoView.
  final VideoViewConfig? videoViewConfig;

  /// get
  VideoViewConfig get viewConfig => videoViewConfig ?? VideoViewConfig();

  bool _beforeEnableWakelock = false;

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
        return viewConfig.deviceOrientationsEnterFullScreen!;
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

  /// The aspectRatio of video.
  double _aspectRatio = 1;

  /// get
  double get aspectRatio => _aspectRatio;

  /// Whether it is full screen mode.
  bool _isFullScreen = false;

  /// get
  bool get isFullScreen => _isFullScreen;

  /// set
  set isFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }

  Future<void> _initialize() async {
    await setLooping(looping: viewConfig.looping);
    await setVolume(1);
    await seekTo(viewConfig.startAt ?? Duration.zero);

    _beforeEnableWakelock = await Wakelock.enabled;
    if (viewConfig.allowedScreenSleep && !_beforeEnableWakelock) {
      await Wakelock.enable();
    }

    if ((viewConfig.autoInitialize || viewConfig.autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await initialize();
    }

    if (viewConfig.fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  /// Initialize the controller.
  Future<void> initialize() async {
    isInitializing = false;

    try {
      isInitializing = true;
      await videoPlayerController.initialize();
    } catch (e) {
      debugPrint('VideoView: $e');
    } finally {
      isInitializing = false;
    }

    final VideoPlayerValue value = videoPlayerController.value;
    if (value.isInitialized) {
      _aspectRatio = viewConfig.aspectRatio ?? value.aspectRatio;

      final double videoWidth = value.size.width;
      final double videoHeight = value.size.height;
      final bool isLandscapeVideo = videoWidth > videoHeight;
      final bool isPortraitVideo = videoWidth < videoHeight;

      if (viewConfig.deviceOrientationsEnterFullScreen != null) {
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

      if (viewConfig.autoPlay) {
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
    await videoPlayerController.play();
  }

  /// Pauses the video.
  Future<void> pause() async {
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

  /// Enter full-screen mode.
  Future<void> enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: viewConfig.systemOverlaysEnterFullScreen ?? <SystemUiOverlay>[],
    );
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Exit full-screen mode.
  Future<void> exitFullScreen() async {
    isFullScreen = false;
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: viewConfig.systemOverlaysExitFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      viewConfig.deviceOrientationsExitFullScreen,
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

  /// Limit the maximum speed.
  double get maxSpeed =>
      defaultTargetPlatform == TargetPlatform.iOS ? 2.0 : 3.0;

  @override
  void dispose() {
    if (!_beforeEnableWakelock) {
      Wakelock.disable();
    }
    videoPlayerController.dispose();

    super.dispose();
  }
}

enum _VideoOrientation { custom, landscape, portrait, other }
