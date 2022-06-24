// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/ui/demo_inputdialog.dart';
import 'superplayer/demo_superplayer_lib.dart';

/// flutter superplayer demo
class DemoSuperplayer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoSuperplayerState();
}

class _DemoSuperplayerState extends State<DemoSuperplayer> {
  List<SuperPlayerModel> videoModels = [];
  bool _isFullScreen = false;
  late SuperPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SuperPlayerController(context);
    FTXVodPlayConfig config = FTXVodPlayConfig();
    // 如果不配置preferredResolution，则在播放多码率视频的时候优先播放720 * 1280分辨率的码率
    config.preferredResolution = 720 * 1280;
    _controller.setPlayConfig(config);
    _controller.onSimplePlayerEventBroadcast.listen((event) {
      String evtName = event["event"];
      if (evtName == SuperPlayerViewEvent.onStartFullScreenPlay) {
      } else if (evtName == SuperPlayerViewEvent.onStopFullScreenPlay) {
      } else {
        print(evtName);
      }
    });
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage("images/ic_new_vod_bg.png"),
            fit: BoxFit.cover,
          )),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _isFullScreen
                ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    title: const Text('SuperPlayer'),
                  ),
            body: SafeArea(
              child: Builder(
                builder: (context) => getBody(),
              ),
            ),
          ),
        ),
        onWillPop: onWillPop);
  }

  Future<bool> onWillPop() async {
    return !_controller.onBackPress();
  }

  Widget getBody() {
    return Column(
      children: [_getPlayArea(), Expanded(flex: 1, child: _getListArea()), _getAddArea()],
    );
  }

  Widget _getPlayArea() {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      height: 220,
      child: SuperPlayerView(_controller),
    );
  }

  Widget _getListArea() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: videoModels.length,
        itemBuilder: (context, i) => _buildVideoItem(videoModels[i]),
      ),
    );
  }

  Widget _buildVideoItem(SuperPlayerModel playModel) {
    return Column(
      children: [
        ListTile(
            leading: Image.network(
              playModel.coverUrl,
              width: 100,
              height: 60,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            title: new Text(
              playModel.title,
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => playCurrentModel(playModel),
        horizontalTitleGap: 10,),
        Divider()
      ],
    );
  }

  Widget _getAddArea() {
    return Container(
      height: 50,
      child: IconButton(icon: new Image.asset('images/addp.png'), onPressed: () => {onAddVideoTap(context)}),
    );
  }

  void onAddVideoTap(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return DemoInputDialog("", 0, "", (String url, int appId, String fileId, String pSign) {
            SuperPlayerModel model = new SuperPlayerModel();
            model.appId = appId;
            if (url.isNotEmpty) {
              model.videoURL = url;
            } else if (appId != 0 && fileId.isNotEmpty) {
              model.videoId = new SuperPlayerVideoId();
              model.videoId!.fileId = fileId;
              if (pSign.isNotEmpty) {
                model.videoId!.psign = pSign;
              }
            } else {
              EasyLoading.showError("请输入播放地址!");
              return;
            }

            playCurrentModel(model);
          }, needPisgn: true);
        });
  }

  void playCurrentModel(SuperPlayerModel model) {
    _controller.playWithModel(model);
  }

  void initData() async {
    List<SuperPlayerModel> models = [];

    int playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;

    SuperPlayerModel model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "8602268011437356984";
    model.title = "云点播（fileId播放）";
    model.playAction = playAction;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1252463788;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "4564972819219071568";
    model.playAction = playAction;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1252463788;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "4564972819219071668";
    model.playAction = playAction;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1252463788;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "4564972819219071679";
    model.playAction = playAction;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1252463788;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "4564972819219081699";
    model.playAction = playAction;
    models.add(model);

    List<Future<void>> requestList = [];
    SuperVodDataLoader loader = SuperVodDataLoader();
    for (SuperPlayerModel tempModel in models) {
      requestList.add(loader.getVideoData(tempModel, (resultModel) {
        videoModels.add(resultModel);
      }));
    }

    await Future.wait(requestList);

    setState(() {
      if (videoModels.isNotEmpty) {
        playCurrentModel(videoModels[0]);
      } else {
        EasyLoading.showError("video list request error");
      }
    });
  }

  @override
  void dispose() {
    // must invoke when page exit.
    _controller.releasePlayer();
    // restore page brightness
    SuperPlayerPlugin.restorePageBrightness();
    super.dispose();
  }
}
