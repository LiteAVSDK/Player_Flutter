import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/test_txLiveplayer.dart';
import 'test_txvodplayer.dart';
import 'test_superplayer.dart';
import 'ui/test_expansion_panel_list.dart';
import 'ui/test_define.dart';
import 'ui/treePage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
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
      _platformVersion = platformVersion;
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
            title: const Text('腾讯视频云', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),),
          ),
          body: Builder(
              builder: (context) {
                return Container(
                  color: Colors.transparent,
                  child: TreePage(),
                );
              }
          ),
        ),
      ),
      builder: EasyLoading.init(),
    );
  }
}
