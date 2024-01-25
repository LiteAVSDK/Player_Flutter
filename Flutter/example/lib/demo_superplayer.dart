// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/demo_download_list.dart';
import 'package:super_player_example/ui/demo_inputdialog.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';
import 'package:super_player_example/res/app_localizations.dart';
import 'dart:ui';

/// flutter superplayer demo
class DemoSuperPlayer extends StatefulWidget {
  Map? initParams = {};

  DemoSuperPlayer({this.initParams});

  @override
  State<StatefulWidget> createState() => _DemoSuperPlayerState();
}

class _DemoSuperPlayerState extends State<DemoSuperPlayer> with TXPipPlayerRestorePage {
  static const TAG = "_DemoSuperPlayerState";
  static const DEFAULT_PLACE_HOLDER = "http://xiaozhibo-10055601.file.myqcloud.com/coverImg.jpg";

  static const ARGUMENT_TYPE_POS = "arg_type_pos";
  static const ARGUMENT_VIDEO_DATA = "arg_video_data";
  static const sPlayerViewDisplayRatio = 720.0 / 1280.0;

  List<SuperPlayerModel> videoModels = [];
  bool _isFullScreen = false;
  late SuperPlayerController _controller;
  SuperVodDataLoader loader = SuperVodDataLoader();
  StreamSubscription? simpleEventSubscription;
  int tabSelectPos = 0;
  SuperPlayerModel? currentVideoModel;
  SuperPlayerModel? initVideoModel;
  double? initStartTime;
  TextStyle _textStyleSelected = new TextStyle(fontSize: 16, color: Colors.white);
  TextStyle _textStyleUnSelected = new TextStyle(fontSize: 16, color: Colors.grey);
  double playerHeight = 220;

  @override
  void initState() {
    super.initState();
    // Listen for device rotation.
    SuperPlayerPlugin.startVideoOrientationService();
    // open brightness observer
    SuperPlayerPlugin.registerSysBrightness(true);
    _controller = SuperPlayerController(context);
    TXPipController.instance.setPipPlayerPage(this);
    FTXVodPlayConfig config = FTXVodPlayConfig();
    // If `preferredResolution` is not configured, the bitrate with a resolution of 720x1280 will be played first when playing multi-bitrate videos.
    config.preferredResolution = 720 * 1280;
    _controller.setPlayConfig(config);
    simpleEventSubscription = _controller.onSimplePlayerEventBroadcast.listen((event) {
      String evtName = event["event"];
      if (evtName == SuperPlayerViewEvent.onStartFullScreenPlay) {
        // enter fullscreen
      } else if (evtName == SuperPlayerViewEvent.onStopFullScreenPlay) {
        // exit fullscreen
      } else {
        print(evtName);
      }
    });
    if (null != widget.initParams) {
      tabSelectPos = widget.initParams![ARGUMENT_TYPE_POS];
      initVideoModel = widget.initParams![ARGUMENT_VIDEO_DATA];
      initStartTime = widget.initParams![TXPipController.ARGUMENT_PIP_START_TIME];
    }
    _adjustSuperPlayerViewHeight();
    if (tabSelectPos == 0) {
      _getLiveListData();
    } else if (tabSelectPos == 1) {
      _getVodListData();
    }
  }

  /// In portrait mode, the player always maintains a 16:9 aspect ratio and prioritizes filling the width.
  void _adjustSuperPlayerViewHeight() {
    playerHeight = (window.physicalSize.width / window.devicePixelRatio) * sPlayerViewDisplayRatio;
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
            appBar: _isFullScreen ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    title: Text("${AppLocals.of(context).playerPlayWidget}"),
                    actions: [
                      InkWell(
                          onTap: _jumpToDownloadList,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.only(left: 8, right: 8),
                            child: Image(image: AssetImage("images/superplayer_ic_vod_download_list.png",
                                    package: PlayerConstants.PKG_NAME)),
                          ))
                    ],
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

  void _jumpToDownloadList() async {
    bool needResume = false;
    if (_controller.playerState == SuperPlayerState.PLAYING) {
      _controller.pause();
      needResume = true;
    }
    dynamic result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DemoDownloadList()));
    if (result is SuperPlayerModel) {
      playVideo(result);
    } else if (needResume) {
      _controller.resume();
      LogUtils.v(TAG, "download list return result is not a videoModel, result is :$result");
    }
  }

  Widget getTabRow() {
    return Container(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            child: Container(
              child: Text(
                AppLocals.current.playerLive,
                style: tabSelectPos == 0 ? _textStyleSelected : _textStyleUnSelected,
              ),
            ),
            onTap: _getLiveListData,
          ),
          GestureDetector(
              onTap: _getVodListData,
              child: Container(
                child: Text(
                  AppLocals.current.playerVod,
                  style: tabSelectPos == 1 ? _textStyleSelected : _textStyleUnSelected,
                ),
              )),
        ],
      ),
    );
  }

  Widget getBody() {
    return Column(
      children: [_getPlayArea(), Expanded(flex: 1, child: _getListArea()), _getAddArea()],
    );
  }

  Widget _getPlayArea() {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      height: playerHeight,
      child: SuperPlayerView(_controller),
    );
  }

  Widget _getListArea() {
    return Container(
        margin: EdgeInsets.only(top: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            getTabRow(),
            Expanded(
                child: ListView.builder(
              shrinkWrap: true,
              itemCount: videoModels.length,
              itemBuilder: (context, i) => _buildVideoItem(videoModels[i]),
            ))
          ],
        ));
  }

  Widget _buildVideoItem(SuperPlayerModel playModel) {
    return Column(
      children: [
        ListTile(
          leading: Image.network(
            playModel.coverUrl.isEmpty ? DEFAULT_PLACE_HOLDER : playModel.coverUrl,
            width: 100,
            height: 60,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          title: new Text(
            playModel.title,
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => playCurrentModel(playModel, 0),
          horizontalTitleGap: 10,
        ),
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
    bool isLive = tabSelectPos == 0;
    showDialog(
        context: context,
        builder: (context) {
          return DemoInputDialog(
            "",
            0,
            "",
            (String url, int appId, String fileId, String pSign, bool enableDownload) {
              SuperPlayerModel model = new SuperPlayerModel();
              model.appId = appId;
              model.isEnableDownload = enableDownload;
              if (url.isNotEmpty) {
                model.videoURL = url;
                model.coverUrl = DEFAULT_PLACE_HOLDER;
                playCurrentModel(model, 0);
                _addVideoToCurrentList(model);
              } else if (appId != 0 && fileId.isNotEmpty) {
                model.videoId = new SuperPlayerVideoId();
                model.videoId!.fileId = fileId;
                if (pSign.isNotEmpty) {
                  model.videoId!.psign = pSign;
                }
                loader.getVideoData(model, (resultModel) {
                  _addVideoToCurrentList(resultModel);
                  playCurrentModel(resultModel, 0);
                });
              } else {
                EasyLoading.showError(AppLocals.current.playerInputAddTip);
              }
            },
            needPisgn: !isLive,
            showFileEdited: !isLive,
            needDownload: !isLive,
          );
        });
  }

  void _addVideoToCurrentList(SuperPlayerModel model) {
    setState(() {
      videoModels.add(model);
    });
  }

  void playCurrentModel(SuperPlayerModel model, double startTime) {
    currentVideoModel = model;
    _controller.setStartTime(startTime);
    _controller.playWithModelNeedLicence(model);
  }

  void playVideo(SuperPlayerModel model) {
    if (null != initVideoModel) {
      playCurrentModel(initVideoModel!, initStartTime ?? 0);
      initVideoModel = null;
      initStartTime = null;
    } else {
      playCurrentModel(model, 0);
    }
  }

  void _getLiveListData() async {
    setState(() {
      tabSelectPos = 0;
    });
    List<SuperPlayerModel> models = [];

    int playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
    SuperPlayerModel model = SuperPlayerModel();
    model.title = AppLocals.current.playerTestVideo;
    model.videoURL = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
    model.coverUrl =
        "http://1500005830.vod2.myqcloud.com/6c9a5118vodcq1500005830/66bc542f387702300661648850/0RyP1rZfkdQA.png";
    model.playAction = playAction;
    models.add(model);

    videoModels.clear();
    videoModels.addAll(models);
    setState(() {
      if (videoModels.isNotEmpty) {
        playVideo(videoModels[0]);
      } else {
        EasyLoading.showError("video list request error");
      }
    });
  }

  void _getVodListData() async {
    setState(() {
      tabSelectPos = 1;
    });
    List<SuperPlayerModel> models = [];

    int playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;

    SuperPlayerModel model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "8602268011437356984";
    model.title = AppLocals.current.playerVodVideo;
    model.playAction = playAction;
    model.isEnableDownload = true;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1252463788;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "5285890781763144364";
    model.title = AppLocals.current.playerTencentCloud;
    model.playAction = playAction;
    model.isEnableDownload = false;
    models.add(model);

    model = SuperPlayerModel();
    model.title = AppLocals.current.playerEncryptVideo;
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "243791578431393746";
    model.videoId!.psign =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6MTUwMDAwNTgzMCwiZmlsZUlkIjoiMjQzNzkxNTc4NDMxMzkzNzQ2IiwiY"
        "3VycmVudFRpbWVTdGFtcCI6MTY3MzQyNjIyNywiY29udGVudEluZm8iOnsiYXVkaW9WaWRlb1R5cGUiOiJQcm90ZWN0ZWRBZGFwdGl"
        "2ZSIsImRybUFkYXB0aXZlSW5mbyI6eyJwcml2YXRlRW5jcnlwdGlvbkRlZmluaXRpb24iOjEyfX0sInVybEFjY2Vzc0luZm8iOnsiZ"
        "G9tYWluIjoiMTUwMDAwNTgzMC52b2QyLm15cWNsb3VkLmNvbSIsInNjaGVtZSI6IkhUVFBTIn19.q34pq7Bl0ryKDwUHGyzfXKP-C"
        "DI8vrm0k_y-IaxgF_U";
    model.playAction = playAction;
    model.isEnableDownload = true;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "387702299774545556";
    model.playAction = playAction;
    model.isEnableDownload = false;
    model.title = AppLocals.current.playerVideoTitleIntroduction;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "387702299774253670";
    model.playAction = playAction;
    model.isEnableDownload = false;
    model.title = AppLocals.current.playerVideoTitleEasy;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "387702299774574470";
    model.playAction = playAction;
    model.title = AppLocals.current.playerVideoTitleNumber;
    model.isEnableDownload = false;
    models.add(model);

    model = SuperPlayerModel();
    model.appId = 1500005830;
    model.videoId = new SuperPlayerVideoId();
    model.videoId!.fileId = "387702299774251236";
    model.playAction = playAction;
    model.isEnableDownload = false;
    model.title = AppLocals.current.playerVideoTitleAchievement;
    models.add(model);

    List<Future<void>> requestList = [];
    for (SuperPlayerModel tempModel in models) {
      requestList.add(loader.getVideoData(tempModel, (_) {}));
    }

    await Future.wait(requestList);
    videoModels.clear();
    videoModels.addAll(models);

    if(mounted) {
      setState(() {
        if (videoModels.isNotEmpty) {
          playVideo(videoModels[0]);
        } else {
          EasyLoading.showError("video list request error");
        }
      });
    }
  }

  @override
  void dispose() {
    _releasePlayerSource();
    super.dispose();
  }

  Future<void> _releasePlayerSource() async {
    // must invoke when page exit.
    await _controller.releasePlayer();
    // restore current brightness to sys brightness
    SuperPlayerPlugin.restorePageBrightness();
    // unregister brightness observer
    SuperPlayerPlugin.registerSysBrightness(false);
    simpleEventSubscription?.cancel();
  }

  @override
  void onNeedSavePipPageState(Map<String, dynamic> params) {
    params[ARGUMENT_TYPE_POS] = tabSelectPos;
    params[ARGUMENT_VIDEO_DATA] = currentVideoModel;
  }
}
