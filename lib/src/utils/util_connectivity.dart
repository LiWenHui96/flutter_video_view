import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_video_view/src/local/video_view_localizations.dart';

/// @Describe: Connectivity
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/24

class ConnectivityUtil {
  // ignore: public_member_api_docs
  factory ConnectivityUtil() => _singleton;

  ConnectivityUtil._() {
    _connectivity = Connectivity();
  }

  late Connectivity _connectivity;

  static ConnectivityUtil? _instance;

  static final ConnectivityUtil _singleton = _instance ??= ConnectivityUtil._();

  /// Get the current connectivity.
  static Future<ConnectivityResult> get current =>
      _singleton._connectivity.checkConnectivity();

  /// Gets a description of the current connectivity.
  static Future<String> getDescription(VideoViewLocalizations local) async {
    final ConnectivityResult result = await current;
    switch (result) {
      case ConnectivityResult.bluetooth:
        return local.bluetooth;
      case ConnectivityResult.wifi:
        return local.wifi;
      case ConnectivityResult.ethernet:
        return local.ethernet;
      case ConnectivityResult.mobile:
        return local.mobile;
      case ConnectivityResult.none:
        return local.none;
    }
  }
}
