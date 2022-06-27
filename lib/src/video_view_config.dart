import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'video_view.dart';

/// @Describe: The config of VideoView.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class VideoViewConfig {
  // ignore: public_member_api_docs
  VideoViewConfig({
    this.width = double.infinity,
    this.height,
    this.backgroundColor = Colors.black,
    this.tipBackgroundColor = Colors.black54,
    this.foregroundColor = Colors.white,
    this.defaultTextSize = 14,
    this.defaultIconSize = 16,
    this.canUseSafe = false,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.panEnabled = false,
    this.scaleEnabled = false,
    this.aspectRatio,
    this.allowedScreenSleep = true,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.overlay,
    this.placeholderBuilder,
    this.bufferingPlaceholder,
    this.finishBuilder,
    this.fullScreenByDefault = false,
    this.useRootNavigator = true,
    this.routePageBuilder,
    this.systemOverlaysEnterFullScreen,
    this.deviceOrientationsEnterFullScreen,
    this.systemOverlaysExitFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsExitFullScreen = DeviceOrientation.values,
    this.showControlsOnInitialize = true,
    this.showControls = true,
    this.hideControlsTimer = const Duration(seconds: 3),
    this.controlsBackgroundColor = const <Color>[
      Color.fromRGBO(0, 0, 0, .7),
      Color.fromRGBO(0, 0, 0, .3),
      Color.fromRGBO(0, 0, 0, 0),
    ],
    this.canLongPress = true,
    this.canChangeVolumeOrBrightness = true,
    this.canChangeProgress = true,
    this.title,
    this.titleTextStyle,
    this.canShowDevice = true,
    this.topActions,
    this.canShowLock = true,
    this.centerLeftActions,
    this.centerRightActions,
    this.textPosition,
    this.videoViewProgressColors,
  })  : assert(
          maxScale > 0,
          'The maxScale must be greater than zero and greater than minScale.',
        ),
        assert(
          minScale > 0,
          'The minScale must be a finite number greater than zero and less '
          'than maxScale.',
        ),
        assert(
          !hideControlsTimer.isNegative,
          'The duration of the controller disappear must be greater than zero.',
        );

  /// The width of video.
  final double width;

  /// The height of video.
  final double? height;

  /// The background color of video.
  ///
  /// Defaults to black.
  final Color backgroundColor;

  /// The background color of a widget that displays information about volume,
  /// brightness, speed, playback progress, and so on.
  ///
  /// Defaults to black54.
  final Color tipBackgroundColor;

  /// The color for the video's Button` and `Text` widget descendants.
  ///
  /// Defaults to white.
  final Color foregroundColor;

  /// Size of all text.
  ///
  /// Defaults to 14.
  final double defaultTextSize;

  /// Size of all text.
  ///
  /// Defaults to 16.
  final double defaultIconSize;

  /// When it is at the top, whether to maintain a safe distance from the top.
  ///
  /// Defaults to false.
  final bool canUseSafe;

  /// The maximum allowed scale.
  ///
  /// Defaults to 2.5.
  final double maxScale;

  /// The minimum allowed scale.
  ///
  /// Defaults to 0.8.
  final double minScale;

  /// Whether or not to allow panning.
  ///
  /// Defaults to false.
  final bool panEnabled;

  /// Whether or not to allow zooming.
  ///
  /// Defaults to false.
  final bool scaleEnabled;

  /// The Aspect Ratio of the Video.
  final double? aspectRatio;

  /// Defines if the player will sleep in fullscreen or not.
  ///
  /// Defaults to true.
  final bool allowedScreenSleep;

  /// Initialize the Video on Startup. This will prep the video for playback.
  ///
  /// Defaults to false.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed.
  ///
  /// Defaults to false.
  final bool autoPlay;

  /// Where does the video start playing when it first plays.
  ///
  /// Defaults to zero.
  final Duration? startAt;

  /// Whether the video is looped.
  ///
  /// Defaults to false.
  final bool looping;

  /// A widget which is placed between the video and the controls.
  final Widget? overlay;

  /// Widgets in various initialized states.
  final Map<VideoInitState, Widget>? placeholderBuilder;

  /// The placeholder when buffered is displayed above the video.
  final Widget? bufferingPlaceholder;

  /// Widget to display when video playback is complete.
  final Widget Function(BuildContext context, bool isFullScreen)? finishBuilder;

  /// Whether to play full screen when auto play is enabled.
  /// Valid only if [autoPlay] is true.
  ///
  /// Defaults to false.
  final bool fullScreenByDefault;

  /// Defines if push/pop navigations use the rootNavigator.
  ///
  /// Defaults to true.
  final bool useRootNavigator;

  /// Defines a custom `RoutePageBuilder` for the fullscreen.
  final VideoViewRoutePageBuilder? routePageBuilder;

  /// Defines the system overlays visible on entering fullscreen.
  final List<SystemUiOverlay>? systemOverlaysEnterFullScreen;

  /// Defines the set of allowed device orientations on entering fullscreen.
  final List<DeviceOrientation>? deviceOrientationsEnterFullScreen;

  /// Defines the system overlays visible after exiting fullscreen.
  final List<SystemUiOverlay> systemOverlaysExitFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen.
  final List<DeviceOrientation> deviceOrientationsExitFullScreen;

  /// Whether controls are displayed when initializing the widget.
  ///
  /// Defaults to true.
  final bool showControlsOnInitialize;

  /// Whether to display controls.
  ///
  /// Defaults to true.
  final bool showControls;

  /// Defines the [Duration] before the video controls are hidden.
  ///
  /// Defaults to three seconds.
  final Duration hideControlsTimer;

  /// The background color of the controller.
  final List<Color> controlsBackgroundColor;

  /// Whether the video can be played at double speed by long pressing.
  ///
  /// Defaults to true.
  final bool canLongPress;

  /// Whether the volume or brightness can be adjusted.
  ///
  /// Defaults to true.
  final bool canChangeVolumeOrBrightness;

  /// Whether the video progress can be adjusted.
  ///
  /// Defaults to true.
  final bool canChangeProgress;

  /// The title of video.
  final String? title;

  /// The textStyle of [title].
  final TextStyle? titleTextStyle;

  /// Whether to display the information of time, power and network status.
  final bool canShowDevice;

  /// Widgets placed at the top right.
  final List<Widget> Function(BuildContext context, bool isFullScreen)?
      topActions;

  /// Whether the lockable button is displayed.
  final bool canShowLock;

  /// Widgets on the middle left.
  ///
  /// `lockButton` is the lockable button, which is used to decide where put it.
  final List<Widget> Function(
    BuildContext context,
    bool isFullScreen,
    bool isLock,
    Widget lockButton,
  )? centerLeftActions;

  /// Widgets on the middle right.
  ///
  /// `lockButton` is the lockable button, which is used to decide where put it.
  final List<Widget> Function(
    BuildContext context,
    bool isFullScreen,
    bool isLock,
    Widget lockButton,
  )? centerRightActions;

  /// Enumeration value where the progress information is located on
  /// the progress bar.
  ///
  /// Defaults to TextPosition.ltl.
  final VideoTextPosition Function(bool isFullScreen)? textPosition;

  /// The default colors used throughout the indicator.
  ///
  /// See [VideoViewProgressColors] for default values.
  final VideoViewProgressColors? videoViewProgressColors;
}

/// Initialization status of video.
enum VideoInitState {
  /// Waiting for initialization.
  none,

  /// Initializing.
  initializing,

  /// Initialization successful.
  success,

  /// Initialization failed.
  fail,
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
class VideoViewProgressColors {
  /// Any property can be set to any paint. They each have defaults.
  VideoViewProgressColors({
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
