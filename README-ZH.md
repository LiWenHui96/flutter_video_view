# Flutter VideoView

[![pub package](https://img.shields.io/pub/v/flutter_video_view)](https://pub.dev/packages/flutter_video_view)
[![GitHub license](https://img.shields.io/github/license/LiWenHui96/flutter_video_view?label=协议&style=flat-square)](https://github.com/LiWenHui96/flutter_video_view/blob/master/LICENSE)

Language: 中文 | [English](README.md)

`flutter_video_view` 是一款用于 Flutter 的视频播放器。video_player 插件为视频播放提供了低级访问权限。

## 安装

具体的配置请移步 [video_player](https://pub.dev/packages/video_player)。

⚠️ 注：无须在 pubspec.yaml 文件中添加 `video_player` 依赖项。

## 准备工作

### 版本限制

```yaml
  sdk: ">=2.12.0 <3.0.0"
  flutter: ">=2.10.0"
```

### 添加依赖

1. 将 `flutter_video_view` 添加至 `pubspec.yaml` 引用

```yaml
dependencies:
  flutter_video_view: ^latest_version
```

2. 执行flutter命令获取包

```
flutter pub get
```

3. 引入

```dart
import 'package:flutter_video_view/flutter_video_view.dart';
```

### 本地化配置

在 `MaterialApp` 添加

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

## 使用方法

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

[VideoViewConfig](lib/src/video_config.dart) 参数名及描述：

| 参数名                               | 类型                         | 描述                                 | 默认值                                                                                           |
|-----------------------------------|----------------------------|------------------------------------|-----------------------------------------------------------------------------------------------|
| width                             | `double?`                  | 宽度                                 | `MediaQuery.of(context).size.width`                                                           |
| height                            | `double?`                  | 高度                                 | `MediaQuery.of(context).size.height`                                                          |
| backgroundColor                   | `Color`                    | 背景色                                | `Colors.black`                                                                                |
| tooltipBackgroundColor            | `Color`                    | 信息提示小部件的背景色，用于显示有关音量、亮度、速度、播放进度等信息 | `Colors.black54`                                                                              |
| foregroundColor                   | `Color`                    | 按钮和文本等小部件字体的颜色                     | `Colors.white`                                                                                |
| textSize                          | `double`                   | 所有文字的大小                            | `14`                                                                                          |
| iconSize                          | `double`                   | 所有图标的大小                            | `16`                                                                                          |
| useSafe                           | `bool`                     | 在顶部时，是否与顶部保持安全距离                   | `true`                                                                                        |
| maxScale                          | `double`                   | 缩放的最大比例                            | `2.5`                                                                                         |
| minScale                          | `double`                   | 缩放的最小比例                            | `0.8`                                                                                         |
| panEnabled                        | `bool`                     | 是否允许平移                             | `false`                                                                                       |
| scaleEnabled                      | `bool`                     | 是否允许缩放                             | `false`                                                                                       |
| aspectRatio                       | `double?`                  | 视频的横纵比                             | `null`                                                                                        |
| allowedScreenSleep                | `bool`                     | 定义播放器是否睡眠                          | `true`                                                                                        |
| autoInitialize                    | `bool`                     | 启动时是否初始化视频，这将为播放视频做好准备             | `false`                                                                                       |
| autoPlay                          | `bool`                     | 初始化完成后是否立即播放                       | `false`                                                                                       |
| startAt                           | `Duration?`                | 视频第一次播放时从哪里开始播放                    | `null`                                                                                        |
| volume                            | `double`                   | 视频的音量，而不是设备音量                      | `1.0`                                                                                         |
| looping                           | `bool`                     | 视频是否循环播放                           | `false`                                                                                       |
| overlay                           | `Widget?`                  | 放置在视频和控制器之间的小部件                    | `null`                                                                                        |
| placeholderBuilder                | `PlaceholderBuilder?`      | 处于各种初始化状态的小部件                      | `null`                                                                                        |
| fullScreenByDefault               | `bool`                     | 启用自动播放时是否全屏播放，仅当[autoPlay]为真时有效    | `false`                                                                                       |
| useRootNavigator                  | `bool`                     | 打开/关闭全全屏模式是否使用rootNavigator        | `true`                                                                                        |
| deviceOrientationsEnterFullScreen | `List<DeviceOrientation>?` | 定义进入全屏时允许的设备方向                     | `null`                                                                                        |
| systemOverlaysExitFullScreen      | `List<SystemUiOverlay>`    | 定义退出全屏后可见的系统覆盖                     | `SystemUiOverlay.values`                                                                      |
| deviceOrientationsExitFullScreen  | `List<DeviceOrientation>`  | 定义退出全屏后允许的设备方向                     | `DeviceOrientation.values`                                                                    |
| showControlsOnInitialize          | `bool`                     | 初始化小部件时是否显示控制器                     | `true`                                                                                        |
| showControls                      | `OnShowControls?`          | 是否显示控制器                            | `true`                                                                                        |
| hideControlsTimer                 | `Duration`                 | 定义隐藏视频控制器之前的[Duration]             | `Duration(seconds: 3)`                                                                        |
| controlsType                      | `ControlsType`             | 控制器的显示类型                           | `ControlsType.normal`                                                                         |
| showBuffering                     | `bool`                     | 是否显示缓冲中的占位符                        | `true`                                                                                        |
| bufferingBuilder                  | `Widget?`                  | 缓冲时的占位符显示在视频上方                     | `null`                                                                                        |
| finishBuilder                     | `FinishBuilder?`           | 视频播放完成时显示的小部件                      | `null`                                                                                        |
| controlsBackgroundColor           | `List<Color>`              | 控制器的背景色                            | <Color>[Color.fromRGBO(0, 0, 0, .7), Color.fromRGBO(0, 0, 0, .3), Color.fromRGBO(0, 0, 0, 0)] |
| showCenterPlay                    | `bool`                     | 是否显示在中部的播放按钮                       | `true`                                                                                        |
| centerPlayButton                  | `Widget?`                  | 中部的播放按钮                            | `null`                                                                                        |
| canLongPress                      | `bool`                     | 长按是否可以最大速度播放视频                     | `true`                                                                                        |
| canChangeVolumeOrBrightness       | `bool`                     | 音量或亮度是否可以调节                        | `true`                                                                                        |
| canChangeProgress                 | `bool`                     | 视频进度是否可以调整                         | `true`                                                                                        |
| canBack                           | `bool`                     | 是否显示返回按钮                           | `true`                                                                                        |
| title                             | `String?`                  | 视频标题                               | `null`                                                                                        |
| titleTextStyle                    | `TextStyle?`               | 视频标题的文字的样式                         | `null`                                                                                        |
| topActionsBuilder                 | `TopActionsBuilder?`       | 放置在右上角的小部件                         | `null`                                                                                        |
| canShowLock                       | `bool`                     | 是否显示可锁定按钮                          | `false`                                                                                       |
| centerLeftActionsBuilder          | `CenterActionsBuilder?`    | 左中的小部件                             | `null`                                                                                        |
| centerRightActionsBuilder         | `CenterActionsBuilder?`    | 右中的小部件                             | `null`                                                                                        |
| bottomBuilder                     | `BottomBuilder?`           | 用于定义底部的控制按钮和显示内容的布局                | `null`                                                                                        |
| onTextPosition                    | `OnTextPosition?`          | 进度信息文字位于进度条上的枚举值                   | `null`                                                                                        |
| onProgressBarGap                  | `OnProgressBarGap?`        | 进度条和时间信息小部件的间隔宽度                   | `10`                                                                                          |
| videoViewProgressColors           | `VideoViewProgressColors?` | 指示器中使用的默认颜色                        | `null`                                                                                        |
| maxPreviewTime                    | `Duration?`                | 最大可预览时长                            | `null`                                                                                        |
| maxPreviewTimeBuilder             | `MaxPreviewTimeBuilder?`   | 达到最大预览可预览时长时显示的小部件。                | `null`                                                                                        |

> 如果你喜欢我的项目，请在项目右上角 "Star" 一下。你的支持是我最大的鼓励！ ^_^