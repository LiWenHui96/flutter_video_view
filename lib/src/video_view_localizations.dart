import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// @Describe: LocalizationsDelegate
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class VideoViewLocalizations extends LocalizationsDelegate<VideoLocalizations> {
  // ignore: public_member_api_docs
  const VideoViewLocalizations();

  /// Provided to [MaterialApp] for use.
  static const VideoViewLocalizations delegate = VideoViewLocalizations();

  @override
  bool isSupported(Locale locale) =>
      VideoLocalizations.languages.contains(locale.languageCode);

  @override
  Future<VideoLocalizations> load(Locale locale) {
    return SynchronousFuture<VideoLocalizations>(VideoLocalizations(locale));
  }

  @override
  bool shouldReload(VideoViewLocalizations old) => false;
}

/// Localizations
abstract class LocalizationsBase {
  // ignore: public_member_api_docs
  const LocalizationsBase(this.locale);

  // ignore: public_member_api_docs
  final Locale? locale;

  // ignore: public_member_api_docs
  Object? getItem(String key);

  /// Text when initialization fails.
  String get loadFailed => getItem('loadFailed').toString();

  /// Reinitialize.
  String get retry => getItem('retry').toString();

  /// Maximum speed playback.
  String get speedPlay => getItem('speedPlay').toString();

  /// Description of detecting.
  String get detecting => getItem('detecting').toString();

  /// Description of [ConnectivityResult.bluetooth].
  String get bluetooth => getItem('bluetooth').toString();

  /// Description of [ConnectivityResult.wifi].
  String get wifi => getItem('wifi').toString();

  /// Description of [ConnectivityResult.ethernet].
  String get ethernet => getItem('ethernet').toString();

  /// Description of [ConnectivityResult.mobile].
  String get mobile => getItem('mobile').toString();

  /// Description of [ConnectivityResult.none].
  String get none => getItem('none').toString();
}

/// localizations
class VideoLocalizations extends LocalizationsBase {
  // ignore: public_member_api_docs
  const VideoLocalizations(Locale? locale) : super(locale);

  static const VideoLocalizations _static = VideoLocalizations(null);

  @override
  Object? getItem(String key) {
    Map<String, Object>? localData;
    if (locale != null) {
      localData = localizedValues[locale!.languageCode];
    }
    if (localData == null) {
      return localizedValues['en']![key];
    }
    return localData[key];
  }

  /// Internally available
  static VideoLocalizations of(BuildContext context) {
    return Localizations.of<VideoLocalizations>(context, VideoLocalizations) ??
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
      'speedPlay': 'Maximum speed playback',
      'detecting': 'Detecting',
      'bluetooth': 'Bluetooth',
      'wifi': 'WIFI',
      'ethernet': 'Ethernet',
      'mobile': 'Mobile',
      'none': 'None',
    },
    'zh': <String, String>{
      'loadFailed': '加载失败喽~',
      'retry': '重试',
      'speedPlay': '倍速播放中',
      'detecting': '检测中',
      'bluetooth': '蓝牙',
      'wifi': 'WIFI',
      'ethernet': '以太网',
      'mobile': '移动网络',
      'none': '无连接',
    },
  };
}
