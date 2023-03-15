# Flutter VideoView

[![pub package](https://img.shields.io/pub/v/flutter_video_view)](https://pub.dev/packages/flutter_video_view)
[![GitHub license](https://img.shields.io/github/license/LiWenHui96/flutter_video_view?label=协议&style=flat-square)](https://github.com/LiWenHui96/flutter_video_view/blob/master/LICENSE)

Language: [中文](README-ZH.md) | English

`flutter_video_view` is a video player for flutter. The [video_player](https://pub.dev/packages/video_player) plugin
gives low level access for the video playback.

## Installation

Please move to step [video_player](https://pub.dev/packages/video_player) for specific configuration.

⚠️ PS: There is no need to add `video_player` dependency to the pubspec.yaml file.

## Preparing for use

### Version constraints

```yaml
  sdk: ">=2.12.0 <3.0.0"
  flutter: ">=2.10.0"
```

### Rely

1. Add `flutter_video_view` to `pubspec.yaml` dependencies.

```yaml
dependencies:
  flutter_video_view: ^latest_version
```

2. Get the package by executing the flutter command.

```
flutter pub get
```

3. Introduce

```dart
import 'package:flutter_video_view/flutter_video_view.dart';
```

### Localized configuration

Add in `MaterialApp`.

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        ...
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            ...
            VideoViewLocalizationsDelegate.delegate,
        ],
        ...
    );
  }
}
```

## Usage

```dart
import 'package:flutter_video_view/flutter_video_view.dart';

final VideoPlayerController videoPlayerController = VideoPlayerController.xxx();

final view = VideoView(
  controller: VideoViewController(
    videoPlayerController: videoPlayerController,
    videoViewConfig: VideoViewConfig(),
  ),
);
```

Popups are implemented by using [VideoViewConfig](lib/src/video_config.dart).

| Name                              | Type                       | Description                                                                                                              | Default                                                                                       |
|-----------------------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| width                             | `double?`                  | The width of video                                                                                                       | `MediaQuery.of(context).size.width`                                                           |
| height                            | `double?`                  | The height of video                                                                                                      | `MediaQuery.of(context).size.height`                                                          |
| backgroundColor                   | `Color`                    | The background color of video                                                                                            | `Colors.black`                                                                                |
| tooltipBackgroundColor            | `Color`                    | The background color of a widget that displays information about volume, brightness, speed, playback progress, and so on | `Colors.black54`                                                                              |
| foregroundColor                   | `Color`                    | The color for the video's Button` and `Text` widget descendants                                                          | `Colors.white`                                                                                |
| textSize                          | `double`                   | Size of all texts                                                                                                        | `14`                                                                                          |
| iconSize                          | `double`                   | Size of all icons                                                                                                        | `16`                                                                                          |
| useSafe                           | `bool`                     | When it is at the top, whether to maintain a safe distance from the top                                                  | `true`                                                                                        |
| maxScale                          | `double`                   | The maximum allowed scale                                                                                                | `2.5`                                                                                         |
| minScale                          | `double`                   | The minimum allowed scale                                                                                                | `0.8`                                                                                         |
| panEnabled                        | `bool`                     | Whether or not to allow panning                                                                                          | `false`                                                                                       |
| scaleEnabled                      | `bool`                     | Whether or not to allow zooming                                                                                          | `false`                                                                                       |
| aspectRatio                       | `double?`                  | The Aspect Ratio of the Video                                                                                            | `null`                                                                                        |
| allowedScreenSleep                | `bool`                     | Defines if the player will sleep in fullscreen or not                                                                    | `true`                                                                                        |
| autoInitialize                    | `bool`                     | Initialize the Video on Startup. This will prep the video for playback                                                   | `false`                                                                                       |
| autoPlay                          | `bool`                     | Play the video as soon as it's displayed                                                                                 | `false`                                                                                       |
| startAt                           | `Duration?`                | Where does the video start playing when it first plays                                                                   | `null`                                                                                        |
| volume                            | `double`                   | The volume of the video, not the device volume                                                                           | `1.0`                                                                                         |
| looping                           | `bool`                     | Whether the video is looped                                                                                              | `false`                                                                                       |
| overlay                           | `Widget?`                  | A widget which is placed between the video and the controls                                                              | `null`                                                                                        |
| placeholderBuilder                | `PlaceholderBuilder?`      | Widgets in various initialized states                                                                                    | `null`                                                                                        |
| fullScreenByDefault               | `bool`                     | Whether to play full screen when auto play is enabled, Valid only if [autoPlay] is true                                  | `false`                                                                                       |
| useRootNavigator                  | `bool`                     | Defines if push/pop navigations use the rootNavigator                                                                    | `true`                                                                                        |
| deviceOrientationsEnterFullScreen | `List<DeviceOrientation>?` | Defines the set of allowed device orientations on entering fullscreen                                                    | `null`                                                                                        |
| systemOverlaysExitFullScreen      | `List<SystemUiOverlay>`    | Defines the system overlays visible after exiting fullscreen                                                             | `SystemUiOverlay.values`                                                                      |
| deviceOrientationsExitFullScreen  | `List<DeviceOrientation>`  | Defines the set of allowed device orientations after exiting fullscreen                                                  | `DeviceOrientation.values`                                                                    |
| showControlsOnInitialize          | `bool`                     | Whether controls are displayed when initializing the widget                                                              | `true`                                                                                        |
| showControls                      | `OnShowControls?`          | Whether to display controls                                                                                              | `true`                                                                                        |
| hideControlsTimer                 | `Duration`                 | Defines the [Duration] before the video controls are hidden                                                              | `Duration(seconds: 3)`                                                                        |
| controlsType                      | `ControlsType`             | Types of controls.                                                                                                       | `ControlsType.normal`                                                                         |
| showBuffering                     | `bool`                     | Whether to show placeholders in the buffer                                                                               | `true`                                                                                        |
| bufferingBuilder                  | `Widget?`                  | The placeholder when buffered is displayed above the video                                                               | `null`                                                                                        |
| finishBuilder                     | `FinishBuilder?`           | Widget to display when video playback is complete                                                                        | `null`                                                                                        |
| controlsBackgroundColor           | `List<Color>`              | The background color of the controller                                                                                   | <Color>[Color.fromRGBO(0, 0, 0, .7), Color.fromRGBO(0, 0, 0, .3), Color.fromRGBO(0, 0, 0, 0)] |
| showCenterPlay                    | `bool`                     | Whether to show the play button in the middle.                                                                           | `true`                                                                                        |
| centerPlayButton                  | `Widget?`                  | Play button in the middle.                                                                                               | `null`                                                                                        |
| canLongPress                      | `bool`                     | Whether the video can be played at double speed by long pressing                                                         | `true`                                                                                        |
| canChangeVolumeOrBrightness       | `bool`                     | Whether the volume or brightness can be adjusted                                                                         | `true`                                                                                        |
| canChangeProgress                 | `bool`                     | Whether the video progress can be adjusted                                                                               | `true`                                                                                        |
| canBack                           | `bool`                     | Whether to show [BackButton].                                                                                            | `true`                                                                                        |
| title                             | `String?`                  | The title of video                                                                                                       | `null`                                                                                        |
| titleTextStyle                    | `TextStyle?`               | The textStyle of [title]                                                                                                 | `null`                                                                                        |
| topActionsBuilder                 | `TopActionsBuilder?`       | Widgets placed at the top right                                                                                          | `null`                                                                                        |
| canShowLock                       | `bool`                     | Whether the lockable button is displayed                                                                                 | `false`                                                                                       |
| centerLeftActionsBuilder          | `CenterActionsBuilder?`    | Widgets on the middle left                                                                                               | `null`                                                                                        |
| centerRightActionsBuilder         | `CenterActionsBuilder?`    | Widgets on the middle right                                                                                              | `null`                                                                                        |
| bottomBuilder                     | `BottomBuilder?`           | It is used to define the control buttons at the bottom and the layout of the display content.                            | `null`                                                                                        |
| onTextPosition                    | `OnTextPosition?`          | Enumeration value where the progress information is located on the progress bar                                          | `null`                                                                                        |
| onProgressBarGap                  | `OnProgressBarGap?`        | The interval width of the progress bar and time information widget.                                                      | `10`                                                                                          |
| videoViewProgressColors           | `VideoViewProgressColors?` | The default colors used throughout the indicator                                                                         | `null`                                                                                        |
| maxPreviewTime                    | `Duration?`                | Maximum preview duration.                                                                                                | `null`                                                                                        |
| maxPreviewTimeBuilder             | `MaxPreviewTimeBuilder?`   | The widget displayed when the maximum preview duration is reached.                                                       | `null`                                                                                        |

> If you like my project, please in the upper right corner of the project "Star". Your support is my biggest
> encouragement! ^_^