import 'package:flutter/material.dart';

/// @Describe: Localizations
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/16

abstract class VideoViewLocalizationsBase {
  /// Externally provided
  const VideoViewLocalizationsBase(this.locale);

  // ignore: public_member_api_docs
  final Locale? locale;

  // ignore: public_member_api_docs
  Object? getItem(String key);

  /// Text when initialization fails.
  String get loadFailed => getItem('loadFailed').toString();

  /// Reinitialize.
  String get retry => getItem('retry').toString();

  /// Double speed playback.
  String get speedPlay => getItem('speedPlay').toString();
}

/// localizations
class VideoViewLocalizations extends VideoViewLocalizationsBase {
  /// Externally provided
  const VideoViewLocalizations(Locale? locale) : super(locale);

  static const VideoViewLocalizations _static = VideoViewLocalizations(null);

  @override
  Object? getItem(String key) {
    Map<String, Object>? localData;
    if (locale != null) {
      localData = localizedValues[locale!.languageCode];
    }
    if (localData == null) {
      return localizedValues['zh']![key];
    }
    return localData[key];
  }

  /// Internally available
  static VideoViewLocalizations of(BuildContext context) {
    return Localizations.of<VideoViewLocalizations>(
          context,
          VideoViewLocalizations,
        ) ??
        _static;
  }

  /// Language Support
  static const List<String> languages = <String>['en', 'zh'];

  /// Language Values
  static const Map<String, Map<String, Object>> localizedValues =
      <String, Map<String, Object>>{
    'en': <String, String>{
      'loadFailed': 'Load failed',
      'retry': 'Retry',
      'speedPlay': 'Double speed playback',
    },
    'zh': <String, String>{
      'loadFailed': '加载失败喽~',
      'retry': '重试',
      'speedPlay': '倍速播放中',
    },
  };
}
