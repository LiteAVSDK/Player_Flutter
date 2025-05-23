// Copyright (c) 2022 Tencent. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';
import 'common/demo_config.dart';
import 'shortvideo/demo_short_video_lib.dart';

class DemoShortVideoPlayer extends StatefulWidget {
  @override
  _DemoShortVideoPlayerState createState() => _DemoShortVideoPlayerState();
}

class _DemoShortVideoPlayerState extends State<DemoShortVideoPlayer> with WidgetsBindingObserver {
  static const TAG = "ShortVideo";
  int _currentIndex = 0;
  List<SuperPlayerModel> superPlayerModelList = [];
  VideoEventDispatcher eventDispatcher = VideoEventDispatcher();

  @override
  void initState() {
    super.initState();
    // stop pip window if exists
    TXPipController.instance.exitAndReleaseCurrentPip();
    _loadData();
    WidgetsBinding.instance.addObserver(this);
  }

  void _loadData() async {
    // check license
    final ShortVideoDataLoader loader = ShortVideoDataLoader();
    if (!isLicenseSuc.isCompleted) {
      SuperPlayerPlugin.setGlobalLicense(LICENSE_URL, LICENSE_KEY);
      await isLicenseSuc.future;
      loader.getPageListDataOneByOneFunction((dataModels) {
        setState(() {
          superPlayerModelList = dataModels;
        });
      });
    } else {
      loader.getPageListDataOneByOneFunction((dataModels) {
        setState(() {
          superPlayerModelList = dataModels;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];
    for (int i = 0; i < superPlayerModelList.length; i++) {
      widgetList.add(ShortVideoPageWidget(
        position: i,
        model: superPlayerModelList[i],
        eventDispatcher: eventDispatcher,
      ));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.black),
      child: SafeArea(
          child: Stack(
            children: [
              PageView(
                scrollDirection: Axis.vertical,
                onPageChanged: (int index) {
                  LogUtils.i(TAG, "[onPageEndChanged] outside ${_currentIndex.toString()} ——》 ${index.toString()}");
                  _stopAndPlay(index);
                },
                children: widgetList,
              ),
              InkWell(
                onTap: _onBackTap,
                child: const Image(
                  width: 40,
                  height: 40,
                  image: AssetImage("images/superplayer_btn_back_play.png", package: PlayerConstants.PKG_NAME),
                ),
              )
            ],
          )),
    );
  }

  void _onBackTap() {
    Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        LogUtils.i(TAG, "[AppLifecycleState.paused]");
        _onApplicationPause();
        break;
      case AppLifecycleState.resumed:
        LogUtils.i(TAG, "[AppLifecycleState.resumed]");
        _onApplicationResume();
        break;
      default:
        break;
    }
  }

  _stopAndPlay(int index) async {
    eventDispatcher.notifyEvent(ShortVideoEvent(index, BaseEvent.PLAY_AND_STOP));
    _currentIndex = index;
  }

  _onApplicationPause() {
    eventDispatcher.notifyEvent(ShortVideoEvent(_currentIndex, BaseEvent.PAUSE));
  }

  _onApplicationResume() {
    eventDispatcher.notifyEvent(ShortVideoEvent(_currentIndex, BaseEvent.RESUME));
  }

  @override
  void dispose() {
    eventDispatcher.closeStream();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
