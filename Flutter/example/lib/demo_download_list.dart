// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/res/app_localizations.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';
import 'dart:io';

/// Download list demo
class DemoDownloadList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoDownloadListState();
}

class _DemoDownloadListState extends State<StatefulWidget> {
  static const DEFAULT_PLACE_HOLDER = "http://xiaozhibo-10055601.file.myqcloud.com/coverImg.jpg";

  List<DownloadModel> models = [];
  SuperVodDataLoader loader = SuperVodDataLoader();
  late FTXDownloadListener listener;

  _DemoDownloadListState() {
    registerListener();
  }

  @override
  void initState() {
    super.initState();
    refreshDownloadList();
  }

  void registerListener() {
    DownloadHelper.instance.addDownloadListener(listener = FTXDownloadListener((event, info) {
      List<DownloadModel> tempModels = models;
      for (int i = 0; i < models.length; i++) {
        DownloadModel downloadModel = models[i];
        if (_compareMediaInfo(downloadModel.mediaInfo, info)) {
          tempModels.removeAt(i);
          tempModels.insert(i, DownloadModel(downloadModel.videoModel, info));
        }
      }
      setState(() {
        models = tempModels;
      });
    }, (errorCode, errorMsg, info) {
      List<DownloadModel> tempModels = models;
      for (int i = 0; i < models.length; i++) {
        DownloadModel downloadModel = models[i];
        if (_compareMediaInfo(downloadModel.mediaInfo, info)) {
          tempModels.removeAt(i);
          tempModels.insert(i, DownloadModel(downloadModel.videoModel, info));
        }
      }
      setState(() {
        models = tempModels;
      });
    }));
  }

  bool _compareMediaInfo(TXVodDownloadMediaInfo org, TXVodDownloadMediaInfo dst) {
    if (null != org.dataSource && null != dst.dataSource) {
      return org.dataSource!.appId == dst.dataSource!.appId &&
          org.dataSource!.fileId == dst.dataSource!.fileId &&
          org.dataSource!.quality == dst.dataSource!.quality;
    } else if (org.url != null && org.url!.isNotEmpty && dst.url != null) {
      return org.url!.compareTo(dst.url!) == 0;
    }
    return false;
  }

  void refreshDownloadList() async {
    List<Future<void>> requestList = [];
    List<DownloadModel> tempModels = [];
    List<TXVodDownloadMediaInfo> mediaInfoList = await TXVodDownloadController.instance.getDownloadList();
    for (TXVodDownloadMediaInfo mediaInfo in mediaInfoList) {
      if (mediaInfo.dataSource != null) {
        SuperPlayerModel model = SuperPlayerModel();
        model.isEnableDownload = false;
        model.appId = mediaInfo.dataSource!.appId ?? 0;
        model.videoId = SuperPlayerVideoId();
        model.videoId!.fileId = mediaInfo.dataSource!.fileId ?? "";
        model.videoId!.psign = mediaInfo.dataSource!.pSign ?? "";
        model.playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
        model.videoURL = mediaInfo.playPath!;
        requestList.add(loader.getVideoData(model, (resultModel) {
          tempModels.add(DownloadModel(resultModel, mediaInfo));
        }));
      } else {
        SuperPlayerModel model = SuperPlayerModel();
        model.isEnableDownload = false;
        model.videoURL = mediaInfo.playPath!;
        model.playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
        model.coverUrl = DEFAULT_PLACE_HOLDER;
        model.title = FSPLocal.current.txSpwTestVideo;
        tempModels.add(DownloadModel(model, mediaInfo));
      }
      await Future.wait(requestList);
      setState(() {
        models.clear();
        models.addAll(tempModels);
      });
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
          title: Text(AppLocals.of(context).playerDownloadList),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) => getBody(),
          ),
        ),
      ),
    );
  }

  Widget getBody() {
    return ListView.builder(
        shrinkWrap: true, itemCount: models.length, itemBuilder: (context, index) => buildDownloadItem(models[index]));
  }

  Widget buildDownloadItem(DownloadModel downloadModel) {
    return InkWell(
      onTap: () => onTapCacheVideo(downloadModel),
      onLongPress: () => onLongPressCacheVideo(downloadModel),
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Column(
          children: [_buildItemContent(downloadModel), Divider()],
        ),
      ),
    );
  }

  Widget _buildItemContent(DownloadModel downloadModel) {
    SuperPlayerModel playModel = downloadModel.videoModel;
    TXVodDownloadMediaInfo mediaInfo = downloadModel.mediaInfo;
    int duration = 0;
    if (mediaInfo.duration != null && mediaInfo.duration != 0) {
      if (Platform.isIOS) {
        duration = mediaInfo.duration!;
      } else {
        duration = mediaInfo.duration! ~/ 1000;
      }
    } else {
      duration = playModel.duration;
    }
    return IntrinsicHeight(
      child: Row(
        children: [
          Stack(
            children: [
              Image.network(
                playModel.coverUrl.isEmpty ? DEFAULT_PLACE_HOLDER : playModel.coverUrl,
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              Positioned(
                  right: 6,
                  bottom: 6,
                  child: Text(
                    Utils.formattedTime(duration.toDouble()),
                    style: TextStyle(color: Color(ColorResource.COLOR_WHITE), fontSize: 12),
                  ))
            ],
          ),
          // Add Expanded to fill the remaining space, determine the width size,
          // and ensure that the child view can find the container boundary.
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 8, right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemTitleArea(playModel, mediaInfo),
                  _buildItemDownloadInfo(mediaInfo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTitleArea(SuperPlayerModel playModel, TXVodDownloadMediaInfo mediaInfo) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(
            playModel.title,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: TextStyle(color: Colors.white, fontSize: 12),
          )),
          Container(
            margin: EdgeInsets.only(left: 2),
            child: mediaInfo.dataSource != null
                ? ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    child: Container(
                      padding: EdgeInsets.only(left: 3, right: 3, top: 1, bottom: 1),
                      decoration: BoxDecoration(color: Color(ColorResource.COLOR_TRANS_GRAY_2)),
                      child: Text(
                        VideoQualityUtils.getNameByCacheQualityId(mediaInfo.dataSource!.quality!),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  )
                : Container(),
          )
        ],
      ),
    );
  }

  Widget _buildItemDownloadInfo(TXVodDownloadMediaInfo mediaInfo) {
    int stateColor = ColorResource.COLOR_DOWNLOAD_CACHING;
    String stateText = AppLocals.of(context).playerCaching;
    if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_START ||
        mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_PROGRESS) {
      stateColor = ColorResource.COLOR_DOWNLOAD_CACHING;
      stateText = AppLocals.of(context).playerCaching;
    } else if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_ERROR) {
      stateColor = ColorResource.COLOR_DOWNLOAD_INTERUPT;
      stateText = AppLocals.of(context).playerCacheError;
    } else if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_STOP) {
      stateColor = ColorResource.COLOR_DOWNLOAD_COMPELETE;
      stateText = AppLocals.of(context).playerCacheInterrupt;
    } else if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_FINISH) {
      stateColor = ColorResource.COLOR_DOWNLOAD_COMPELETE;
      stateText = AppLocals.of(context).playerCacheComplete;
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 4),
              child: Text(
                "${AppLocals.of(context).playerCacheSize}:${(mediaInfo.size != null ? mediaInfo.size! / 1024 ~/ 1024 : 0)}MB",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                softWrap: true,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
            // Ellipsis for overflow
            Expanded(
                child: Text(
              "${AppLocals.of(context).playerCacheProgressLabel}:${((mediaInfo.progress ?? 0) * 100).toInt()}%",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              softWrap: true,
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ))
          ],
        )),
        Container(
          width: 5,
          height: 5,
          margin: EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(stateColor)),
        ),
        Text(
          stateText,
          style: TextStyle(color: Color(ColorResource.COLOR_TRANS_GRAY_3), fontSize: 10),
        )
      ],
    );
  }

  void onTapCacheVideo(DownloadModel downloadModel) {
    TXVodDownloadMediaInfo mediaInfo = downloadModel.mediaInfo;
    if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_FINISH) {
      SuperPlayerModel playerModel = downloadModel.videoModel;
      // Use local playback address
      playerModel.videoURL = downloadModel.mediaInfo.playPath!;
      // Set videoId to null to avoid additional parameter concatenation by the player component for the URL
      playerModel.videoId = null;
      // Set multiVideoURLs to null to avoid limited playback of multi-bitrate URLs by the player component
      playerModel.multiVideoURLs = [];
      Navigator.of(context).pop(playerModel);
    } else if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_STOP ||
        mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_ERROR) {
      DownloadHelper.instance.resumeDownloadOrg(downloadModel.mediaInfo);
      refreshDownloadList();
    } else if (mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_PROGRESS ||
        mediaInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_START) {
      DownloadHelper.instance.stopDownload(downloadModel.mediaInfo);
      refreshDownloadList();
    }
  }

  void onLongPressCacheVideo(DownloadModel downloadModel) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Color(ColorResource.COLOR_APP_MAIN_THEME),
            contentPadding: EdgeInsets.fromLTRB(5, 0, 5, 10),
            title: Text(
              AppLocals.of(context).playerTip,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(ColorResource.COLOR_WHITE), fontSize: 16),
            ),
            content: Container(
              margin: EdgeInsets.only(top: 15),
              child: Text(
                AppLocals.of(context).playerCheckUserDeleteVideo,
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(ColorResource.COLOR_TRANS_GRAY_4), fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => _onDialogDeleteDownload(downloadModel),
                  child: Text(
                    AppLocals.of(context).playerConfirm,
                    style: TextStyle(color: Color(ColorResource.COLOR_BTN_BULUE), fontSize: 14),
                  )),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocals.of(context).playerCancel,
                    style: TextStyle(color: Color(ColorResource.COLOR_TRANS_GRAY_4), fontSize: 14),
                  )),
            ],
          );
        });
  }

  void _onDialogDeleteDownload(DownloadModel downloadModel) async {
    bool deleteResult = await DownloadHelper.instance.deleteDownload(downloadModel.mediaInfo);
    Navigator.of(context).pop();
    if (deleteResult) {
      setState(() {
        models.remove(downloadModel);
      });
    } else {
      EasyLoading.showToast(AppLocals.of(context).playerDeleteFailed);
    }
  }

  @override
  void dispose() {
    super.dispose();
    DownloadHelper.instance.removeDownloadListener(listener);
  }
}

class DownloadModel {
  SuperPlayerModel videoModel;
  TXVodDownloadMediaInfo mediaInfo;

  DownloadModel(this.videoModel, this.mediaInfo);
}
