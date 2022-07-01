import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_view/flutter_video_view.dart';

/// @Describe: Video
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/2

class VideoPage extends StatefulWidget {
  // ignore: public_member_api_docs
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  Widget build(BuildContext context) {
    final String? url = ModalRoute.of(context)?.settings.arguments as String?;
    final VideoViewController controller = VideoViewController(
      videoPlayerController: VideoPlayerController.network(url ?? ''),
      videoViewConfig: VideoViewConfig(
        height: 260,
        // aspectRatio: MediaQueryData.fromWindow(window).size.width / 260,
        autoInitialize: true,
        title: 'This is a small video of the test',
        deviceOrientationsExitFullScreen: <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ],
      ),
    );

    return Scaffold(
      body: Column(
        children: <Widget>[
          VideoView(controller: controller),
          Container(
            height: 40,
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: const Text('这是一个视频测试'),
          ),
        ],
      ),
    );
  }
}
