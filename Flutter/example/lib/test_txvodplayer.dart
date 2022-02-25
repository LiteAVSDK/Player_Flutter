import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';
import 'ui/test_inputdialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'ui/test_volume_slider.dart';
import 'ui/test_speed_slider.dart';
import 'ui/test_bitrate_checkbox.dart';

class TestTXVodPlayer extends StatefulWidget {
  @override
  _TestTXPVodlayerState createState() => _TestTXPVodlayerState();
}

class _TestTXPVodlayerState extends State<TestTXVodPlayer> with WidgetsBindingObserver{

  TXVodPlayerController _controller;
  double _aspectRatio = 0;
  double _progress = 0.0;
  bool _isMute = false;
  int _volume = 100;
  List _supportedBitrates = [];
  int _curBitrateIndex = 0;
  String _url = "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";
  int _appId = 0;
  String _fileId = "";
  double _rate = 1.0;

  Future<void> init() async {
    if (!mounted) return;

    _controller = TXVodPlayerController();
    _controller.onPlayerState.listen((val){
      debugPrint("********** $val **********");
    });

    _controller.onPlayerEventBroadcast.listen((event) async {//订阅状态变化
      //debugPrint("= TestTXVodPlayer listen state = ${event.toString()}");
      if(event["event"] == 2004 || event["event"] == 2003) {
        EasyLoading.dismiss();
        _supportedBitrates = await _controller.getSupportedBitrates();
      }else if(event["event"] == 2005) {
        _progress = event["EVT_PLAY_PROGRESS"].toDouble();
      }
    });

    _controller.onPlayerNetStatusBroadcast.listen((event) async {//订阅状态变化
      //debugPrint("= TestTXVodPlayer listen state = ${event.toString()}");
      double w = (event["VIDEO_WIDTH"]).toDouble();
      double h = (event["VIDEO_HEIGHT"]).toDouble();

      if(w > 0 && h > 0) {
        setState(() {
          _aspectRatio = 1.0 * w / h;
        });
      }
    });

    await _controller.initialize();
    // await _controller.setStartTime(20);
    await _controller.setLoop(true);
    // await _controller.setIsAutoPlay(isAutoPlay: false);
//    await _controller.setLiveMode(LiveMode.Speed);
//    await _controller.play("http://200024424.vod.myqcloud.com/200024424_709ae516bdf811e6ad39991f76a4df69.f20.mp4");
//    await _controller.play("http://1251964405.vod2.myqcloud.com/vodtransgzp1251964405/5285890814466934861/v.f586090.mp4");
    await _controller.play(_url);
  }

  @override
  void initState() {
    super.initState();
    init();
    WidgetsBinding.instance?.addObserver(this);
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
          )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('点播'),
        ),
        body: SafeArea(
            child: Container(
              //color: Colors.blueGrey,
              child: Column(
                children: [
                  Container(
                    height: 150,
                    color: Colors.black,
                    child: Center(
                      child: _aspectRatio>0?AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: TXPlayerVideo(controller: _controller),
                      ):Container(),
                    ),
                  ),
                  Expanded(
                    child:GridView.count(
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 30.0,
                      padding: EdgeInsets.all(10.0),
                      crossAxisCount: 4,
                      childAspectRatio: 2,
                      children: [
                        new GestureDetector(
                          onTap: () => {
                            _controller.resume()
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "播放",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                        new GestureDetector(
                          onTap: () => {
                            _controller.pause()
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "暂停",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                        new GestureDetector(
                          onTap: () => {
                            _controller.seek(_progress+10)
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "前进",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                        new GestureDetector(
                          onTap: () => {
                            _controller.seek(_progress-10)
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "后退",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                        new GestureDetector(
                          onTap: () => {
                            onClickSetRate()
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "变速播放",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
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
                              _isMute?"取消静音":"设置静音",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
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
                              style: TextStyle(fontSize: 18, color:Colors.blue),
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
                            }else {
                              EasyLoading.showError('无其他码率!');
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "切换码率",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                        new GestureDetector(
                          onTap: () async {
                            await _controller.setMirror(true);
                            EasyLoading.showSuccess('设置成功!');
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "设置镜像",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100,
                            child: IconButton(
                                icon: new Image.asset(
                                    'images/addp.png'
                                ),
                                onPressed: () => {
                                  onPressed()
                                }),
                          )
                        ],
                      )
                  ),
                ],
              ),
            )
        ),
      ),
    );
    return Scaffold(

    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    EasyLoading.dismiss();
  }

  void onPressed() {
    showDialog(context: context, builder: (context) {
      return TestInputDialog("", 0, "", (String url, int appId, String fileId) {
        _url = url;
        _appId = appId;
        _fileId = fileId;
        if (url.isNotEmpty) {
          _controller.play(url);
        }else if (appId != 0 && fileId.isNotEmpty) {
          TXPlayerAuthParams params = TXPlayerAuthParams();
          params.appId = appId;
          params.fileId = fileId;
          _controller.startPlayWithParams(params);
        }
      });
    });
  }

  void onClickVolume() {
    showDialog(context: context, builder: (context) {
      return TestVolumeSlider(_volume, (int result){
        _volume = result;
        _controller.setAudioPlayoutVolume(_volume);
      });
    });
  }

  void onClickSetRate() {
    showDialog(context: context, builder: (context) {
      return TestSpeedSlider(_rate, (double result) {
        _rate = result;
        _controller.setRate(_rate);
      });
    });
  }

  void onClickBitrate() {
    showDialog(context: context, builder: (context) {
      return TestBitrateCheckbox(_supportedBitrates, _curBitrateIndex, (int result) {
        _curBitrateIndex = result;
        _controller.setBitrateIndex(_curBitrateIndex);
        EasyLoading.showSuccess('切换成功!');
      });
    });
  }
}