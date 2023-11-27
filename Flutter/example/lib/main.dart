// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/common/demo_config.dart';
import 'package:super_player_example/demo_superplayer.dart';
import 'package:super_player_example/res/app_localization_delegate.dart';
import 'package:super_player_example/res/app_localizations.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';

import 'ui/treePage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String? _liteAVSdkVersion = 'Unknown';
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initPlayerLicense();
    _getFlutterSdkVersion();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    LogUtils.logOpen = true;
  }

  /// set player license
  Future<void> initPlayerLicense() async {
    await SuperPlayerPlugin.setGlobalLicense(LICENSE_URL, LICENSE_KEY);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SuperPlayerPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion!;
    });
    TXPipController.instance.setNavigatorHandle((params) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => DemoSuperPlayer(initParams: params)));
    });

    SuperPlayerPlugin.setGlobalMaxCacheSize(200);
    SuperPlayerPlugin.setGlobalCacheFolderPath("postfixPath");
  }

  Future<void> _getFlutterSdkVersion() async {
    String? liteAVSdkVersion = await SuperPlayerPlugin.getLiteAVSDKVersion();
    setState(() {
      _liteAVSdkVersion = liteAVSdkVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizationDelegate.delegate,
        SuperPlayerWidgetLocals.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocals.current.playerTitle,
      supportedLocales: [
        Locale.fromSubtags(languageCode: 'en'),
        Locale.fromSubtags(languageCode: 'zh'),
      ],
      localeListResolutionCallback: (List<Locale>? locales, Iterable<Locale> supportedLocales) {},
      navigatorKey: navigatorKey,
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage("images/ic_new_vod_bg.png"),
          fit: BoxFit.cover,
        )),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            // To wait for the context to be ready in the widget.
            title: Builder(
              builder: (context) => Text(
                AppLocals.of(context).playerTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          body: Builder(builder: (context) {
            return Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  TreePage(),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: new EdgeInsets.all(20.0),
                        child: Text('LiteAVSDKVersion: $_liteAVSdkVersion'),
                      )),
                ],
              ),
            );
          }),
        ),
      ),
      builder: EasyLoading.init(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
