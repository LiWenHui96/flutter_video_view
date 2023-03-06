import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_video_view/flutter_video_view.dart';

import 'page_video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await redoSystemStyle();

  runApp(const MyApp());
}

/// Program entry
class MyApp extends StatefulWidget {
  // ignore: public_member_api_docs
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        VideoViewLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en', 'US'), Locale('zh', 'CN')],
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: <String, WidgetBuilder>{'video': (_) => const VideoPage()},
      title: 'Video View Example',
    );
  }
}

/// Home
class HomePage extends StatefulWidget {
  // ignore: public_member_api_docs
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String url =
      'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

  @override
  Widget build(BuildContext context) {
    final Widget child = Center(
      child: ElevatedButton(
        onPressed: () async =>
            Navigator.pushNamed(context, 'video', arguments: url),
        child: const Text('视频'),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Video View Example')),
      body: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// Handle the status bar and navigation bar as a whole.
Future<void> redoSystemStyle({bool isPortrait = true}) async {
  if (isPortrait) {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true,
    ),
  );
}
