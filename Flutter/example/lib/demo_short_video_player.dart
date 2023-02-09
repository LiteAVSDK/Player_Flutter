// Copyright (c) 2022 Tencent. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';
import 'shortvideo/demo_short_video_lib.dart';

class DemoShortVideoPlayer extends StatefulWidget {
  @override
  _DemoShortVideoPlayerState createState() => _DemoShortVideoPlayerState();
}

class _DemoShortVideoPlayerState extends State<DemoShortVideoPlayer> with WidgetsBindingObserver {
  static const TAG = "ShortVideo::ShortVideoListViewState";
  int _currentIndex = 0;
  List<SuperPlayerModel> superPlayerModelList = [];

  @override
  void initState() {
    super.initState();
    ShortVideoDataLoader loader = ShortVideoDataLoader();
    loader.getPageListDataOneByOneFunction((dataModels) {
      setState(() {
        superPlayerModelList = dataModels;
      });
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];
    for (int i = 0; i < superPlayerModelList.length; i++) {
      widgetList.add(ShortVideoPageWidget(
          position: i, videoUrl: superPlayerModelList[i].videoURL, coverUrl: superPlayerModelList[i].coverUrl));
    }

    return Stack(
      children: [
        PageView(
          scrollDirection: Axis.vertical,
          onPageChanged: (int index) {
            LogUtils.i(TAG, "[onPageEndChanged] outside ${_currentIndex.toString()} ——》 ${index.toString()}");
            _stopAndPlay(index);
          },
          children: widgetList,
        ),
        SafeArea(
            child: Container(
              child: InkWell(
                onTap: _onBackTap,
                child: const Image(
                  width: 40,
                  height: 40,
                  image: AssetImage("images/superplayer_btn_back_play.png", package: StringResource.PKG_NAME),
                ),
              ),
            )),
      ],
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
    }
  }

  _stopAndPlay(int index) async {
    EventBusUtils.getInstance().fire(new StopAndResumeEvent(index));
    _currentIndex = index;
  }

  _onApplicationPause() {
    EventBusUtils.getInstance().fire(new ApplicationPauseEvent());
  }

  _onApplicationResume() {
    EventBusUtils.getInstance().fire(new ApplicationResumeEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
