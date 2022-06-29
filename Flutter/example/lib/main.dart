// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';

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

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initPlayerLicense();
    _getflutterSdkVersion();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    LogUtils.logOpen = true;
  }

  /// set player license
  Future<void> initPlayerLicense() async{
    String licenceURL = ""; // 获取到的 licence url
    String licenceKey = ""; // 获取到的 licence key
    await SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
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
  }

  Future<void> _getflutterSdkVersion() async {
    String? liteavSdkVersion = await SuperPlayerPlugin.getLiteAVSDKVersion();
    setState(() {
      _liteAVSdkVersion = liteavSdkVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/ic_new_vod_bg.png"),
              fit: BoxFit.cover,
            )
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('腾讯云Flutter播放器', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),),
          ),
          body: Builder(
              builder: (context) {
                return Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      TreePage(),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: new EdgeInsets.all(20.0) ,
                          child: Text('LiteAVSDKVersion: ${_liteAVSdkVersion}'),
                        )
                      ),
                    ],
                  ),
                );
              }
          ),
        ),
      ),
      builder: EasyLoading.init(),
    );
  }
}
