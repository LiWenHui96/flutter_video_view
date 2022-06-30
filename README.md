# Flutter VideoView

[![pub package](https://img.shields.io/pub/v/flutter_video_view)](https://pub.dev/packages/flutter_video_view)
[![GitHub license](https://img.shields.io/github/license/LiWenHui96/flutter_video_view?label=协议&style=flat-square)](https://github.com/LiWenHui96/flutter_video_view/blob/master/LICENSE)

Language: [中文](README-ZH.md) | English

## Preparing for use

### Version constraints

```yaml
  sdk: ">=2.16.0 <3.0.0"
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

final view = VideoView(
  controller: VideoViewController.network(
    'url',
    videoViewConfig: VideoViewConfig(),
  ),
);
```

Popups are implemented by using [VideoViewConfig](lib/src/video_view_config.dart).

| Name                              | Type                                                                                              | Description                                                                                                              | Default                                                          |
|-----------------------------------|---------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| width                             | `double`                                                                                          | The width of video                                                                                                       | `double.infinity`                                                |
| height                            | `double?`                                                                                         | The height of video                                                                                                      | `null`                                                           |
| backgroundColor                   | `Color`                                                                                           | The background color of video                                                                                            | `Colors.black`                                                   |
| tipBackgroundColor                | `Color`                                                                                           | The background color of a widget that displays information about volume, brightness, speed, playback progress, and so on | `Colors.black54`                                                 |
| foregroundColor                   | `Color`                                                                                           | The color for the video's Button` and `Text` widget descendants                                                          | `Colors.white`                                                   |
| defaultTextSize                   | `double`                                                                                          | Size of all texts                                                                                                        | `14`                                                             |
| defaultIconSize                   | `double`                                                                                          | Size of all icons                                                                                                        | `16`                                                             |
| canUseSafe                        | `bool`                                                                                            | When it is at the top, whether to maintain a safe distance from the top                                                  | `true`                                                           |
| maxScale                          | `double`                                                                                          | The maximum allowed scale                                                                                                | `2.5`                                                            |
| minScale                          | `double`                                                                                          | The minimum allowed scale                                                                                                | `0.8`                                                            |
| panEnabled                        | `bool`                                                                                            | Whether or not to allow panning                                                                                          | `false`                                                          |
| scaleEnabled                      | `bool`                                                                                            | Whether or not to allow zooming                                                                                          | `false`                                                          |
| aspectRatio                       | `double?`                                                                                         | The Aspect Ratio of the Video                                                                                            | `null`                                                           |
| allowedScreenSleep                | `bool`                                                                                            | Defines if the player will sleep in fullscreen or not                                                                    | `true`                                                           |
| autoInitialize                    | `bool`                                                                                            | Initialize the Video on Startup. This will prep the video for playback                                                   | `false`                                                          |
| autoPlay                          | `bool`                                                                                            | Play the video as soon as it's displayed                                                                                 | `false`                                                          |
| startAt                           | `Duration?`                                                                                       | Where does the video start playing when it first plays                                                                   | `Duration.zero`                                                  |
| volume                            | `double`                                                                                          | The volume of the video, not the device volume                                                                           | `1.0`                                                            |
| looping                           | `bool`                                                                                            | Whether the video is looped                                                                                              | `false`                                                          |
| overlay                           | `Widget?`                                                                                         | A widget which is placed between the video and the controls                                                              | `null`                                                           |
| placeholderBuilder                | `Map<VideoInitState, Widget>?`                                                                    | Widgets in various initialized states                                                                                    | `null`                                                           |
| bufferingPlaceholder              | `Widget?`                                                                                         | The placeholder when buffered is displayed above the video                                                               | `null`                                                           |
| finishBuilder                     | `Widget Function(BuildContext context, bool isFullScreen)?`                                       | Widget to display when video playback is complete                                                                        | `null`                                                           |
| fullScreenByDefault               | `bool`                                                                                            | Whether to play full screen when auto play is enabled, Valid only if [autoPlay] is true                                  | `false`                                                          |
| useRootNavigator                  | `bool`                                                                                            | Defines if push/pop navigations use the rootNavigator                                                                    | `true`                                                           |
| routePageBuilder                  | `VideoViewRoutePageBuilder?`                                                                      | Defines a custom `RoutePageBuilder` for the fullscreen                                                                   | `null`                                                           |
| systemOverlaysEnterFullScreen     | `List<SystemUiOverlay>?`                                                                          | Defines the system overlays visible on entering fullscreen                                                               | `null`                                                           |
| deviceOrientationsEnterFullScreen | `List<DeviceOrientation>?`                                                                        | Defines the set of allowed device orientations on entering fullscreen                                                    | `null`                                                           |
| systemOverlaysExitFullScreen      | `List<SystemUiOverlay>`                                                                           | Defines the system overlays visible after exiting fullscreen                                                             | `SystemUiOverlay.values`                                         |
| deviceOrientationsExitFullScreen  | `List<DeviceOrientation>`                                                                         | Defines the set of allowed device orientations after exiting fullscreen                                                  | `DeviceOrientation.values`                                       |
| showControlsOnInitialize          | `bool`                                                                                            | Whether controls are displayed when initializing the widget                                                              | `true`                                                           |
| showControls                      | `bool`                                                                                            | Whether to display controls                                                                                              | `true`                                                           |
| hideControlsTimer                 | `Duration`                                                                                        | Defines the [Duration] before the video controls are hidden                                                              | `Duration(seconds: 3)`                                           |
| controlsBackgroundColor           | `List<Color>`                                                                                     | The background color of the controller                                                                                   | <Color>[Color.fromRGBO(0, 0, 0, .6), Color.fromRGBO(0, 0, 0, 0)] |
| canLongPress                      | `bool`                                                                                            | Whether the video can be played at double speed by long pressing                                                         | `true`                                                           |
| canChangeVolumeOrBrightness       | `bool`                                                                                            | Whether the volume or brightness can be adjusted                                                                         | `true`                                                           |
| canChangeProgress                 | `bool`                                                                                            | Whether the video progress can be adjusted                                                                               | `true`                                                           |
| title                             | `String?`                                                                                         | The title of video                                                                                                       | `null`                                                           |
| titleTextStyle                    | `TextStyle?`                                                                                      | The textStyle of [title]                                                                                                 | `null`                                                           |
| canShowDevice                     | `bool`                                                                                            | Whether to display the information of time, power and network status                                                     | `false`                                                          |
| topActions                        | `List<Widget> Function(BuildContext context, bool isFullScreen)?`                                 | Widgets placed at the top right                                                                                          | `null`                                                           |
| canShowLock                       | `bool`                                                                                            | Whether the lockable button is displayed                                                                                 | `false`                                                          |
| centerLeftActions                 | `List<Widget> Function(BuildContext context, bool isFullScreen, bool isLock, Widget lockButton)?` | Widgets on the middle left                                                                                               | `null`                                                           |
| centerRightActions                | `List<Widget> Function(BuildContext context, bool isFullScreen, bool isLock, Widget lockButton)?` | Widgets on the middle right                                                                                              | `null`                                                           |
| textPosition                      | `VideoTextPosition Function(bool isFullScreen)?`                                                  | Enumeration value where the progress information is located on the progress bar                                          | `null`                                                           |
| videoViewProgressColors           | `VideoViewProgressColors?`                                                                        | The default colors used throughout the indicator                                                                         | `null`                                                           |

> If you like my project, please in the upper right corner of the project "Star". Your support is my biggest encouragement! ^_^