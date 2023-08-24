// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/res/app_localizations.dart';

import 'ui/demo_inputdialog.dart';
import 'ui/demo_volume_slider.dart';
import 'ui/demo_video_slider_view.dart';

class DemoTXLivePlayer extends StatefulWidget {
  @override
  _DemoTXLivelayerState createState() => _DemoTXLivelayerState();
}

class _DemoTXLivelayerState extends State<DemoTXLivePlayer> with WidgetsBindingObserver {
  late TXLivePlayerController _controller;
  double _aspectRatio = 16.0 / 9.0;
  double _progress = 0.0;
  int _volume = 100;
  bool _isMute = false;
  String _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
  bool _isStop = true;
  bool _isPlaying = false;
  double _maxLiveProgressTime = 0;
  StreamSubscription? playEventSubscription;
  StreamSubscription? playNetEventSubscription;
  StreamSubscription? playerStateEventSubscription;

  GlobalKey<VideoSliderViewState> progressSliderKey = GlobalKey();

  Future<void> init() async {
    if (!mounted) return;

    _controller = TXLivePlayerController();

    playEventSubscription = _controller.onPlayerEventBroadcast.listen((event) {
      // Subscribe to event distribution
      if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        _progress = event["EVT_PLAY_PROGRESS"].toDouble();
        _maxLiveProgressTime = _progress >= _maxLiveProgressTime ? _progress : _maxLiveProgressTime;
        progressSliderKey.currentState?.updateProgress(1, _maxLiveProgressTime);
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        // First frame appearance
        _isStop = false;
        _isPlaying = true;
        EasyLoading.dismiss();
        _resizeVideo(event);
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_STREAM_SWITCH_SUCC) {
        // Stream switching successful.
        EasyLoading.dismiss();
        if (_url == "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv") {
          EasyLoading.showSuccess(AppLocals.current.playerSwitchTo1080);
        } else {
          EasyLoading.showSuccess(AppLocals.current.playerSwitchTo480);
        }
      } else if (event["event"] == TXVodPlayEvent.PLAY_ERR_STREAM_SWITCH_FAIL) {
        EasyLoading.dismiss();
        EasyLoading.showError(AppLocals.current.playerLiveSwitchFailed);
        switchUrl();
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION) {
        LogUtils.w("PLAY_EVT_CHANGE_RESOLUTION", event);
        _resizeVideo(event);
      }
    });

    playNetEventSubscription = _controller.onPlayerNetStatusBroadcast.listen((event) {
      // Subscribe to status changes
    });

    playerStateEventSubscription = _controller.onPlayerState.listen((event) {
      // Subscribe to status changes
      debugPrint("Playback status ${event!.name}");
    });

    await SuperPlayerPlugin.setConsoleEnabled(true);
    await _controller.initialize();
    await _controller.setConfig(FTXLivePlayConfig());
    await _controller.startLivePlay(_url, playType: TXPlayType.LIVE_FLV);
  }

  void _resizeVideo(Map<dynamic, dynamic> event) {
    int? videoWidth = event[TXVodPlayEvent.EVT_PARAM1];
    int? videoHeight = event[TXVodPlayEvent.EVT_PARAM2];
    if ((videoWidth != null && videoWidth != 0) && (videoHeight != null && videoHeight != 0)) {
      setState(() {
        _aspectRatio = 1.0 * videoWidth / videoHeight;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    init();
    WidgetsBinding.instance.addObserver(this);
    EasyLoading.show(status: 'loading...');
  }

  @override
  Future didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    print("didChangeAppLifecycleState $state");
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (_isPlaying) {
          _controller.resume();
        }
        break;
      case AppLifecycleState.paused:
        _controller.pause();
        break;
      default:
        break;
    }
  }

  void switchUrl() {
    if (_url == "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo480p.flv") {
      _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
    } else {
      _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo480p.flv";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage("images/ic_new_vod_bg.png"),
        fit: BoxFit.cover,
      )),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(AppLocals.current.playerLivePlay),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 220,
                color: Colors.black,
                child: Center(
                  child: _aspectRatio > 0
                      ? AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: TXPlayerVideo(controller: _controller),
                        )
                      : Container(),
                ),
              ),
              VideoSliderView(_controller, progressSliderKey),
              Expanded(
                  child: GridView.count(
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 30.0,
                padding: EdgeInsets.all(10.0),
                crossAxisCount: 4,
                childAspectRatio: 2,
                children: [
                  _createItem(AppLocals.current.playerResumePlay, () async {
                    if (_isStop) {
                      EasyLoading.showError(AppLocals.current.playerLiveStopTip);
                      return;
                    }
                    _controller.resume();
                  }),
                  _createItem(AppLocals.current.playerPausePlay, () {
                    if (_isStop) {
                      EasyLoading.showError(AppLocals.current.playerLiveStopTip);
                      return;
                    }
                    _isPlaying = false;
                    _controller.pause();
                  }),
                  _createItem(AppLocals.current.playerStopPlay, () {
                    _isStop = true;
                    _controller.stop();
                  }),
                  _createItem(AppLocals.current.playerReplay, () => _controller.startLivePlay(_url, playType: TXPlayType.LIVE_FLV)),
                  _createItem(AppLocals.current.playerQualitySwitch, () async {
                    if (_isStop) {
                      EasyLoading.showError(AppLocals.current.playerLiveStopTip);
                      return;
                    }
                    switchUrl();
                    _controller.switchStream(_url);

                    EasyLoading.show(status: 'loading...');
                  }),
                  _createItem(_isMute ? AppLocals.current.playerCancelMute : AppLocals.current.playerSetMute, () async {
                    setState(() {
                      _isMute = !_isMute;
                      _controller.setMute(_isMute);
                    });
                  }),
                  _createItem(AppLocals.current.playerAdjustVolume, () => onClickVolume),
                ],
              )),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 100,
                    child: IconButton(icon: Image.asset('images/addp.png'), onPressed: () => {onPressed()}),
                  )
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createItem(String name, GestureTapCallback tapBlock) {
    return InkWell(
      onTap: tapBlock,
      child: Container(
        child: Text(name,
          style: TextStyle(fontSize: 18, color: Colors.blue),
          overflow: TextOverflow.visible,),
      ),
    );
  }

  @override
  void dispose() {
    playerStateEventSubscription?.cancel();
    playEventSubscription?.cancel();
    playNetEventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    EasyLoading.dismiss();
  }

  void onPressed() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoInputDialog("", 0, "", (String url, int appId, String fileId, String pSign, bool enableDownload) {
            _url = url;
            _controller.stop();
            if (url.isNotEmpty) {
              _controller.startLivePlay(url);
            }
          }, showFileEdited: false);
        });
  }

  void onClickVolume() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoVolumeSlider(_volume, (int result) {
            _volume = result;
            _controller.setVolume(_volume);
          });
        });
  }
}
