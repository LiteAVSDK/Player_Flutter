import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';
import 'ui/test_inputdialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TestTXLivePlayer extends StatefulWidget {
  @override
  _TestTXPLivelayerState createState() => _TestTXPLivelayerState();
}

class _TestTXPLivelayerState extends State<TestTXLivePlayer> {

  TXLivePlayerController _controller;
  double _aspectRatio = 0;
  double _progress = 0.0;
  String _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
  bool _isStop = true;

  Future<void> init() async {
    if (!mounted) return;

    _controller = TXLivePlayerController();

    _controller.onPlayerEventBroadcast.listen((event) {//订阅事件分发
      //debugPrint("= TestTXLivePlayer listen event = ${event.toString()}");
      if(event["event"] == 2005) {
        _progress = event["EVT_PLAY_PROGRESS"].toDouble();
      }else if (event["event"] == 2004 || event["event"] == 2003) {//首帧出现
        _isStop = false;
        EasyLoading.dismiss();
      }else if (event["event"] == 2015) {//切换流成功
        EasyLoading.dismiss();
        if (_url == "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv") {
          EasyLoading.showSuccess('切换到1080p!');
        }else {
          EasyLoading.showSuccess('切换到480p!');
        }
      }
    });

    _controller.onPlayerNetStatusBroadcast.listen((event) {
      debugPrint("= TestTXLivePlayer listen netStatus = ${event.toString()}");
      double w = (event["VIDEO_WIDTH"]).toDouble();
      double h = (event["VIDEO_HEIGHT"]).toDouble();

      if(w > 0 && h > 0) {
        setState(() {
          _aspectRatio = 1.0 * w / h;
        });
      }
    });

    _controller.onPlayerState.listen((event) {//订阅状态变化
      //debugPrint("= TestTXLivePlayer listen state = ${event.toString()}");
    });


    await SuperPlayerPlugin.setConsoleEnabled(true);
    await _controller.initialize();
//    await _controller.setRenderRotation(2);
//    await _controller.setLiveMode(LiveMode.Speed);
//    await _controller.play("http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv", playType: TXPlayType.LIVE_FLV);
    //安卓需要设置hls格式才可正常播放
    await _controller.play(_url, playType: TXPlayType.LIVE_FLV);
//    await _controller.play("http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv", playType: TXPlayType.VOD_HLS);
  }

  @override
  void initState() {
    super.initState();
    init();
    EasyLoading.show(status: 'loading...');
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
            title: const Text('直播'),
          ),
          body:SafeArea(
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
                            _controller.play(_url, playType: TXPlayType.LIVE_FLV);
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

                            if (_url == "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo480p.flv") {
                              _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
                              _controller.switchStream(_url);
                            }else {
                              _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo480p.flv";
                              _controller.switchStream(_url);
                            }

                            EasyLoading.show(status: 'loading...');
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              "清晰度切换",
                              style: TextStyle(fontSize: 18, color:Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    )
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
          ),
        ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    EasyLoading.dismiss();
  }

  void onPressed() {
    showDialog(context: context, builder: (context) {
      return TestInputDialog("", 0, "", (String url, int appId, String fileId) {
        _url = url;
        _controller.stop();
        if (url.isNotEmpty) {
          _controller.play(url);
        }
      }, showFileEdited:false);
    });
  }
}