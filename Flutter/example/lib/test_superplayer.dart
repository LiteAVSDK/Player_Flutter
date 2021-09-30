import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';
import 'ui/test_inputdialog.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';
import 'dart:ui';

class TestSuperPlayer extends StatefulWidget {
  @override
  _TestSuperPlayerState createState() => _TestSuperPlayerState();
}

class _TestSuperPlayerState extends State<TestSuperPlayer> {
  bool _liveSelected = true;//live is default
  var _currentModels = <SuperPlayerViewModel>[];
  SuperPlayerViewConfig _playerConfig = SuperPlayerViewConfig();
  SuperPlayerPlatformViewController _playerController;
  bool _isFullSceen = false;
  double _aspectRatio = defaultTargetPlatform == TargetPlatform.android?(1.0 * (window.physicalSize.height) / (window.physicalSize.width - window.padding.top)):16.0/9.0;
  TextStyle _textStyleSelected = new TextStyle(
      fontSize: 16, color: Colors.white
  );
  TextStyle _textStyleUnSelected = new TextStyle(
      fontSize: 16, color: Colors.grey
  );
  final Completer<bool> _initPlayer = Completer();//防止player未初始化的时候就调用playmodel

  //高清url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv";
  //超清url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
  //标清url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo480p.flv";
  @override
  void initState() {
    super.initState();
    _getLiveListData();
    debugPrint("= initState = ${window.padding.top}, ${window.physicalSize.width}");
  }

  @override
  void dispose() {
    _playerController.resetPlayer();
    super.dispose();
  }

  void onPressed(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return TestInputDialog("", 0, "",
              (String url, int appId, String fileId) {
            SuperPlayerViewModel model = new SuperPlayerViewModel();
            model.appId = appId;
            if (url.isNotEmpty) {
              model.videoURL = url;
            }else if (appId != 0 && fileId.isNotEmpty) {
              model.videoId = new SuperPlayerVideoId();
              model.videoId.fileId = fileId;
            }else {
              EasyLoading.showError("请输入播放地址!");
              return;
            }

            playCurrentModel(model);
          });
        });
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
        appBar: _isFullSceen
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('SuperPlayer'),
              ),
        body:SafeArea(
          child:Builder(
            builder: (context) => createBody(),
          ),
        ),
      ),
    );
  }

  Widget createBody() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_isFullSceen) {
        return new Column(
          children: [getPlayArea()],
        );
      }
    }

    return new Column(
      children: [getPlayArea(), Expanded(child: getListArea()), getAddArea()],
    );
  }

  Widget getPlayArea() {
    return new AspectRatio(
        aspectRatio: _aspectRatio,
        child: SuperPlayerVideo(
          onCreated: (SuperPlayerPlatformViewController vc) async {
            _playerController = vc;
            _playerController.setPlayConfig(_playerConfig);
            _playerController.onPlayerEventBroadcast.listen((event) {
              setState(() {
                String evtName = event["event"];
                if (evtName == SuperPlayerViewEvent.onStartFullScreenPlay) {
                  if (defaultTargetPlatform == TargetPlatform.android) {
                    _isFullSceen = true;
                    AutoOrientation.landscapeAutoMode();

                    ///关闭状态栏，与底部虚拟操作按钮
                    SystemChrome.setEnabledSystemUIOverlays([]);
                  }
                  print("onStartFullScreenPlay");
                } else if (evtName == SuperPlayerViewEvent.onStopFullScreenPlay){
                    if (defaultTargetPlatform == TargetPlatform.android) {
                      _isFullSceen = false;

                      /// 如果是全屏就切换竖屏
                      AutoOrientation.portraitAutoMode();

                      ///显示状态栏，与底部虚拟操作按钮
                      SystemChrome.setEnabledSystemUIOverlays(
                          [SystemUiOverlay.top, SystemUiOverlay.bottom]);
                    }
                    print("onStopFullScreenPlay");
                  } else if (evtName == SuperPlayerViewEvent.onSuperPlayerBackAction) {
                    print("onSuperPlayerBackAction");
                  }
                }
              );
            });
            _initPlayer.complete(true);
          },
        ));
  }

  Widget getListArea() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [getTabRow(), Expanded(child: getVideoList())],
    );
  }

  Widget getAddArea() {
    return new Container(
      // color: Colors.red,
      height: 50,
      child: IconButton(
          icon: new Image.asset('images/addp.png'),
          onPressed: () => {onPressed(context)}),
    );
  }

  Widget getTabRow() {
    return new Container(
      height: 40,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          new GestureDetector(
            child: new Container(
              child: Text(
                "直播",
                style: _liveSelected?_textStyleSelected:_textStyleUnSelected,
              ),
            ),
            onTap: _getLiveListData,
          ),
          new GestureDetector(
              onTap: _getVodListDataOneByOne,
              child: new Container(
                child: Text(
                  "点播",
                  style: _liveSelected?_textStyleUnSelected:_textStyleSelected,
                ),
              )),
        ],
      ),
    );
  }

  ListView getVideoList() {
    return new ListView.builder(
        itemCount: _currentModels.length,
        itemBuilder: (BuildContext context, int i) {
          return _buildRow(_currentModels[i]);
        });
  }

  _getLiveListData() async {
    setState(() {
      _liveSelected = true;
    });
    var url = "http://xzb.qcloud.com/get_live_list2";
    var httpClient = new HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != HttpStatus.OK) {
      return;
    }
    var json = await response.transform(utf8.decoder).join();
    Map<String, dynamic> root = jsonDecode(json);
    var code = root['code'];
    var message = root['message'];
    log("_getLiveListData,code=$code,message = $message");
    if (code != 200) {
      return;
    }
    var data = root['data'];
    List list = data['list'];
    var models = <SuperPlayerViewModel>[];
    for (int i = 0; i < list.length; i++) {
      SuperPlayerViewModel model = new SuperPlayerViewModel();
      model.appId = list[i]['appId'];
      model.title = list[i]['name'];
      model.coverUrl = list[i]['coverUrl'];

      List playUrls = list[i]['playUrl'];
      List<SuperPlayerUrl> multiVideoURLs = [];
      for (int j = 0; j < playUrls.length; j++) {
        SuperPlayerUrl spUrl = new SuperPlayerUrl();
        spUrl.title = playUrls[j]['title'];
        spUrl.url = playUrls[j]['url'];
        multiVideoURLs.add(spUrl);
      }
      model.multiVideoURLs = multiVideoURLs;

      models.add(model);

      if(i == 0){
        playCurrentModel(model);
      }
    }

    setState(() {
      _currentModels.clear();
      _currentModels.addAll(models);
    });
  }

  Widget _buildRow(SuperPlayerViewModel playModel) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
          leading: Image.network(playModel.coverUrl),
          title: new Text(
            playModel.title,
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => playCurrentModel(playModel)

        ),
        Divider()
      ],
    );
  }

  _getVodListDataOneByOne() {
    List<AppIdAndFileId> defaultData = [];
    defaultData.add(new AppIdAndFileId(1252463788, "5285890781763144364"));
    defaultData.add(new AppIdAndFileId(1400329073, "5285890800381567412"));
    defaultData.add(new AppIdAndFileId(1400329073, "5285890800381530399"));
    defaultData.add(new AppIdAndFileId(1252463788, "4564972819219071668"));
    defaultData.add(new AppIdAndFileId(1252463788, "4564972819219071679"));
    defaultData.add(new AppIdAndFileId(1252463788, "4564972819219081699"));

    setState(() {
      _liveSelected = false;
      _currentModels.clear();
    });

    for (var model in defaultData) {
      _getVodListData(model.appId, model.fileId);
    }
  }

  _getVodListData(int appId, String fileId) async {
    var url = "https://playvideo.qcloud.com/getplayinfo/v4";
    url = url + "/$appId/$fileId";
    var query = makeQueryString(null, null, -1, null);
    if (query != null) {
      url = url + "?" + query;
    }
    var httpClient = new HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != HttpStatus.OK) {
      return;
    }
    var json = await response.transform(utf8.decoder).join();
    Map<String, dynamic> root = jsonDecode(json);
    int code = root['code'];
    String message = root['message'];
    String warning = root['warning'];
    log("_getVodListData,code=$code,message=$message,warning=$warning");
    if (code != 0) {
      return;
    }
    int version = root['version'];
    SuperPlayerViewModel model = new SuperPlayerViewModel();
    model.appId = appId;
    model.videoId = new SuperPlayerVideoId();
    model.videoId.fileId = fileId;
    if (version == 2) {
      model.coverUrl = root['coverInfo']['coverUrl'];
      model.duration = root['videoInfo']['sourceVideo']['duration'];
      model.title = root['videoInfo']['basicInfo']['description'];
      if (model.title == null || model.title.length == 0) {
        model.title = root['videoInfo']['basicInfo']['name'];
      }
    } else if (version == 4) {
      model.title = root['media']['basicInfo']['description'];
      if (model.title == null || model.title.length == 0) {
        model.title = root['media']['basicInfo']['name'];
      }
      model.coverUrl = root['media']['basicInfo']['coverUrl'];
      model.duration = root['media']['basicInfo']['duration'];
    }

    setState(() {
      _currentModels.add(model);
    });
  }

  String makeQueryString(String timeout, String us, int exper, String sign) {
    var str = new StringBuffer();
    if (timeout != null) {
      str.write("t=" + timeout + "&");
    }
    if (us != null) {
      str.write("us=" + us + "&");
    }
    if (sign != null) {
      str.write("sign=" + sign + "&");
    }
    if (exper >= 0) {
      str.write("exper=$exper" + "&");
    }
    String result = str.toString();
    if (result.length > 1) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  playCurrentModel(SuperPlayerViewModel playModel) async {
    print("playCurrentModel,playModel = playModel=$playModel");
    await _initPlayer.future;//一定要有_playerController
    _playerController.playWithModel(playModel);
  }
}

class AppIdAndFileId {
  int appId;
  String fileId;

  AppIdAndFileId(int appId, String fileId) {
    this.appId = appId;
    this.fileId = fileId;
  }
}
