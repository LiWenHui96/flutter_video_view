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
  VideoController? controller;

  @override
  void initState() {
    Future<void>.delayed(Duration.zero, () {
      final String? url = ModalRoute.of(context)?.settings.arguments as String?;
      final Uri? uri = Uri.tryParse(url ?? '');

      controller = VideoController(
        videoPlayerController: VideoPlayerController.networkUrl(uri!),
        videoConfig: VideoConfig(
          height: 260,
          // autoInitialize: true,
          autoPlay: true,
          deviceOrientationsExitFullScreen: <DeviceOrientation>[
            DeviceOrientation.portraitUp,
          ],
        ),
      );

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          if (controller != null)
            Flexible(child: VideoView(controller: controller!)),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                height: 1000,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: const Text('这是一个视频测试'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
