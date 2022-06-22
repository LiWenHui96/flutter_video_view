import 'dart:io';

import 'package:flutter/material.dart';

import 'inside.dart';
import 'notifier/video_view_notifier.dart';
import 'video_view_config.dart';

/// @Describe: The controller of VideoView.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/15

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
    VideoViewConfig? videoViewConfig,
  }) : super(
          videoPlayerController: VideoPlayerController.asset(
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
    VideoViewConfig? videoViewConfig,
  }) : super(
          videoPlayerController: VideoPlayerController.network(
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
    VideoViewConfig? videoViewConfig,
  }) : super(
          videoPlayerController: VideoPlayerController.file(
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
    VideoViewConfig? videoViewConfig,
  }) : super(
          videoPlayerController: VideoPlayerController.contentUri(
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

  // ignore: public_member_api_docs
  static VideoViewController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VideoViewControllerInherited>()!
      .controller;
}
