// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';

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
  String _url =
      "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
  bool _isStop = true;
  double _maxLiveProgressTime = 0;
  StreamSubscription? playEventSubscription;
  StreamSubscription? playNetEventSubscription;
  StreamSubscription? playerStateEventSubscription;

  GlobalKey<VideoSliderState> progressSliderKey = GlobalKey();

  Future<void> init() async {
    if (!mounted) return;

    _controller = TXLivePlayerController();

    playEventSubscription = _controller.onPlayerEventBroadcast.listen((event) {
      //订阅事件分发
      if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        _progress = event["EVT_PLAY_PROGRESS"].toDouble();
        _maxLiveProgressTime = _progress >= _maxLiveProgressTime ? _progress : _maxLiveProgressTime;
        progressSliderKey.currentState?.updatePorgess(1, _maxLiveProgressTime);
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN ||
          event["event"] == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        //首帧出现
        _isStop = false;
        EasyLoading.dismiss();
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_STREAM_SWITCH_SUCC) {
        //切换流成功
        EasyLoading.dismiss();
        if (_url == "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv") {
          EasyLoading.showSuccess('切换到1080p!');
        } else {
          EasyLoading.showSuccess('切换到480p!');
        }
      } else if (event["event"] == TXVodPlayEvent.PLAY_ERR_STREAM_SWITCH_FAIL) {
        EasyLoading.dismiss();
        EasyLoading.showError("切流失败");
        switchUrl();
      }else if(event["event"] == TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION) {
        LogUtils.w("PLAY_EVT_CHANGE_RESOLUTION", event);
      }
    });

    playNetEventSubscription =  _controller.onPlayerNetStatusBroadcast.listen((event) {
      double w = (event[TXVodNetEvent.NET_STATUS_VIDEO_WIDTH]).toDouble();
      double h = (event[TXVodNetEvent.NET_STATUS_VIDEO_HEIGHT]).toDouble();

      if (w > 0 && h > 0) {
        setState(() {
          _aspectRatio = 1.0 * w / h;
        });
      }
    });

    playerStateEventSubscription = _controller.onPlayerState.listen((event) {
      //订阅状态变化
      debugPrint("播放状态 ${event!.name}");
    });

    await SuperPlayerPlugin.setConsoleEnabled(true);
    await _controller.initialize();
    await _controller.setConfig(FTXLivePlayConfig());
    // 安卓需要设置hls格式才可正常播放
    await _controller.startPlay(_url, playType: TXPlayType.LIVE_FLV);
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
        _controller.resume();
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
          title: const Text('直播播放'),
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
                crossAxisCount: 3,
                childAspectRatio: 2,
                children: [
                  new GestureDetector(
                    onTap: () async {
                      if (_isStop) {
                        EasyLoading.showError('已经停止播放, 请重新播放');
                        return;
                      }
                      _controller.resume();
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "继续播放",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () async {
                      if (_isStop) {
                        EasyLoading.showError('已经停止播放, 请重新播放');
                        return;
                      }
                      _controller.pause();
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "暂停播放",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () async {
                      _isStop = true;
                      _controller.stop();
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "停止播放",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () async {
                      _controller.startPlay(_url, playType: TXPlayType.LIVE_FLV);
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "重新播放",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () async {
                      if (_isStop) {
                        EasyLoading.showError('已经停止播放，请重新播放');
                        return;
                      }
                      switchUrl();
                      _controller.switchStream(_url);

                      EasyLoading.show(status: 'loading...');
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "清晰度切换",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () async {
                      _controller.setMute(!_isMute);
                      _isMute = !_isMute;
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        "设置静音",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                  new GestureDetector(
                    onTap: () {
                      onClickVolume();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        "调整音量",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              )),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 100,
                    child: IconButton(icon: new Image.asset('images/addp.png'), onPressed: () => {onPressed()}),
                  )
                ],
              )),
            ],
          ),
        ),
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
          return DemoInputDialog("", 0, "", (String url, int appId, String fileId,String pSign) {
            _url = url;
            _controller.stop();
            if (url.isNotEmpty) {
              _controller.startPlay(url);
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
