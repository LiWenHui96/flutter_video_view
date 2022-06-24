import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'inside.dart';
import 'video_view_config.dart';

/// @Describe: The controller of VideoView.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/15

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

  bool _beforeEnableWakelock = false;

  bool _isInitializing = false;

  /// Whether initializing.
  bool get isInitializing => _isInitializing;

  set isInitializing(bool value) {
    _isInitializing = value;
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
    await videoPlayerController.setPlaybackSpeed(
      speed ?? (defaultTargetPlatform == TargetPlatform.iOS ? 2.0 : 3.0),
    );
  }

  /// Enter full-screen mode.
  Future<void> enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays:
          videoViewConfig.systemOverlaysEnterFullScreen ?? <SystemUiOverlay>[],
    );
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Exit full-screen mode.
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

enum _VideoOrientation { custom, landscape, portrait, other }
