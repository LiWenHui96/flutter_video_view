import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'video_view_localizations.dart';

/// @Describe: LocalizationsDelegate
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

class VideoViewLocalizationsDelegate
    extends LocalizationsDelegate<VideoViewLocalizations> {
  // ignore: public_member_api_docs
  const VideoViewLocalizationsDelegate();

  /// Provided to [MaterialApp] for use.
  static const VideoViewLocalizationsDelegate delegate =
      VideoViewLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      VideoViewLocalizations.languages.contains(locale.languageCode);

  @override
  Future<VideoViewLocalizations> load(Locale locale) {
    return SynchronousFuture<VideoViewLocalizations>(
      VideoViewLocalizations(locale),
    );
  }

  @override
  bool shouldReload(VideoViewLocalizationsDelegate old) => false;
}
