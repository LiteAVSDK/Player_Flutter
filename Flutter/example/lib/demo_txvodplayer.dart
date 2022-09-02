// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';
import 'ui/demo_inputdialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'ui/demo_volume_slider.dart';
import 'ui/demo_speed_slider.dart';
import 'ui/demo_bitrate_checkbox.dart';
import 'ui/demo_video_slider_view.dart';

class DemoTXVodPlayer extends StatefulWidget {
  @override
  _DemoTXVodlayerState createState() => _DemoTXVodlayerState();
}

class _DemoTXVodlayerState extends State<DemoTXVodPlayer>
    with WidgetsBindingObserver {
  late TXVodPlayerController _controller;
  double _aspectRatio = 16 / 9;
  double _currentProgress = 0.0;
  bool _isMute = false;
  int _volume = 100;
  List _supportedBitrates = [];
  int _curBitrateIndex = 0;
  String _url =
      "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";
  int _appId = 0;
  String _fileId = "";
  double _rate = 1.0;
  bool enableHardware = true;
  int volume = 80;
  StreamSubscription? playEventSubscription;
  StreamSubscription? playNetEventSubscription;

  GlobalKey<VideoSliderState> progressSliderKey = GlobalKey();

  Future<void> init() async {
    if (!mounted) return;
    _controller = TXVodPlayerController();
    _controller.onPlayerState.listen((val) {
      debugPrint("播放状态 ${val?.name}");
    });
    LogUtils.logOpen = true;

    SuperPlayerPlugin.setGlobalMaxCacheSize(200);
    SuperPlayerPlugin.setGlobalCacheFolderPath("postfixPath");

    playEventSubscription = _controller.onPlayerEventBroadcast.listen((event) async {
      //订阅状态变化
      if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN ||
          event["event"] == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        EasyLoading.dismiss();
        _supportedBitrates = (await _controller.getSupportedBitrates())!;
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        _currentProgress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS].toDouble();
        double videoDuration = event[TXVodPlayEvent.EVT_PLAY_DURATION].toDouble(); // 总播放时长，转换后的单位 秒
        if (videoDuration == 0.0) {
          progressSliderKey.currentState?.updatePorgess(0.0, 0.0);
        } else {
          progressSliderKey.currentState?.updatePorgess(_currentProgress / videoDuration, videoDuration);
        }
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_GET_PLAYINFO_SUCC) {
        String? playUrl = event[TXVodPlayEvent.EVT_PLAY_URL]?.toString();
      }
    });

    playNetEventSubscription = _controller.onPlayerNetStatusBroadcast.listen((event) async {
      //订阅状态变化
      double w = (event[TXVodNetEvent.NET_STATUS_VIDEO_WIDTH]).toDouble();
      double h = (event[TXVodNetEvent.NET_STATUS_VIDEO_HEIGHT]).toDouble();

      if (w > 0 && h > 0) {
        setState(() {
          _aspectRatio = 1.0 * w / h;
        });
      }
    });
    await SuperPlayerPlugin.setConsoleEnabled(true);

    await _controller.initialize();
    await _controller.setLoop(true);
    await _controller.enableHardwareDecode(enableHardware);
    await _controller.setAudioPlayoutVolume(volume);

    _controller.setConfig(FTXVodPlayConfig());
    await _controller.startPlay(_url);
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
          title: const Text('点播播放'),
        ),
        body: SafeArea(
            child: Container(
              //color: Colors.blueGrey,
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
                      mainAxisSpacing: 20.0,
                      padding: EdgeInsets.all(10.0),
                      crossAxisCount: 4,
                      childAspectRatio: 2,
                      children: getFunctionWidgetList(),
                    ),
                  ),
                  Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100,
                            child: IconButton(
                                icon: new Image.asset('images/addp.png'),
                                onPressed: () => {onPressed()}),
                          )
                        ],
                      )),
                ],
              ),
            )),
      ),
    );
  }

  List<Widget> getFunctionWidgetList() {
    List<Widget> children = [
      new GestureDetector(
        onTap: () => {_controller.resume()},
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "播放",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () => {_controller.pause()},
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "暂停",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () => {_controller.seek(_currentProgress + 10)},
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "前进",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () => {_controller.seek(_currentProgress - 10)},
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "后退",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () => {onClickSetRate()},
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "变速播放",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () {
          _isMute = !_isMute;
          _controller.setMute(_isMute);
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            _isMute ? "取消静音" : "设置静音",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () {
          // _volume = _volume + 10;
          // _volume = _volume<=100?_volume:100;
          // _controller.setAudioPlayoutVolume(_volume);
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
      new GestureDetector(
        onTap: () async {
          if (_supportedBitrates.length > 1) {
            // EasyLoading.show(status: 'loading...');
            // _curBitrateIndex = _curBitrateIndex + 1;
            // _curBitrateIndex = _curBitrateIndex % _supportedBitrates.length;
            // _controller.setBitrateIndex(_curBitrateIndex);
            onClickBitrate();
          } else {
            EasyLoading.showError('无其他码率!');
          }
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "切换码率",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () async {
          double time =
          await _controller.getCurrentPlaybackTime();
          EasyLoading.showToast('${time.toStringAsFixed(2)}秒');
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "播放时间",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () async {
          int width = await _controller.getWidth();
          int height = await _controller.getHeight();
          EasyLoading.showToast('width:$width,height:$height');
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "视频尺寸",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () async {
          bool isLoop = await _controller.isLoop();
          EasyLoading.showToast('isLoop:$isLoop');
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "是否循环",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () async {
          TXPlayerState? state = _controller.playState;
          if (state != TXPlayerState.disposed &&
              state != TXPlayerState.stopped) {
            enableHardware = !enableHardware;
            bool enableSuccess = await _controller
                .enableHardwareDecode(enableHardware);
            double stratTime =
            await _controller.getCurrentPlaybackTime();
            await _controller.setStartTime(stratTime);
            await _controller.startPlay(_url);
            String wareMode = enableHardware ? "硬解" : "软解";
            if (enableSuccess) {
              EasyLoading.showToast("切换$wareMode成功");
            } else {
              EasyLoading.showToast("切换$wareMode失败");
            }
          } else {
            EasyLoading.showToast("视频已播放结束");
          }
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            enableHardware ? "切换软解" : "切换硬解",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
      new GestureDetector(
        onTap: () async {
          double time = await _controller.getPlayableDuration();
          EasyLoading.showToast("可播放时长$time");
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "可播时长",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ),
    ];

    /// ios 没有该能力
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      children.add(new GestureDetector(
        onTap: () async {
          double time = await _controller.getBufferDuration();
          EasyLoading.showToast('${time.toStringAsFixed(2)}秒');
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            "缓存时长",
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
      ));
    }
    return children;
  }

  @override
  void dispose() {
    playNetEventSubscription?.cancel();
    playEventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    EasyLoading.dismiss();
  }

  void onPressed() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoInputDialog("", 0, "",
                  (String url, int appId, String fileId,String pSign) {
                _url = url;
                _appId = appId;
                _fileId = fileId;
                if (url.isNotEmpty) {
                  _controller.startPlay(url);
                } else if (appId != 0 && fileId.isNotEmpty) {
                  TXPlayInfoParams params = TXPlayInfoParams(appId: _appId,
                    fileId: _fileId, psign: pSign != null ? pSign : "");
                  _controller.startPlayWithParams(params);
                }
              }, needPisgn: true);
        });
  }

  void onClickVolume() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoVolumeSlider(_volume, (int result) {
            _volume = result;
            _controller.setAudioPlayoutVolume(_volume);
          });
        });
  }

  void onClickSetRate() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoSpeedSlider(_rate, (double result) {
            _rate = result;
            _controller.setRate(_rate);
          });
        });
  }

  void onClickBitrate() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoBitrateCheckbox(_supportedBitrates, _curBitrateIndex,
                  (int result) {
                _curBitrateIndex = result;
                _controller.setBitrateIndex(_curBitrateIndex);
                EasyLoading.showSuccess('切换成功!');
              });
        });
  }
}
