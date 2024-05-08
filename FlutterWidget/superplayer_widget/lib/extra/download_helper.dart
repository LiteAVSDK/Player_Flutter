// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// Download helper class, used in conjunction with the player component to simplify the download process.
/// 下载帮助类，配合播放器组件使用，简化下载使用流程
class DownloadHelper {
  static DownloadHelper? _instance;

  static DownloadHelper get instance => _sharedInstance();

  /// SuperPlayerPlugin instance
  /// SuperPlayerPlugin单例
  static DownloadHelper _sharedInstance() {
    _instance ??= DownloadHelper._internal();
    return _instance!;
  }

  final List<FTXDownloadListener> _listeners = [];

  /// init model
  /// 初始model
  DownloadHelper._internal() {
    TXVodDownloadController.instance.setDownloadObserver((event, info) {
      for (FTXDownloadListener listener in _listeners) {
        listener.onStateChangeListener(event, info);
      }
    }, (errorCode, errorMsg, info) {
      for (FTXDownloadListener listener in _listeners) {
        listener.onErrorListener(errorCode, errorMsg, info);
      }
    });
  }

  void addDownloadListener(FTXDownloadListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeDownloadListener(FTXDownloadListener listener) {
    _listeners.remove(listener);
  }

  void clearListener() {
    _listeners.clear();
  }

  /// Generate a download `MediaInfo` based on the video model.
  /// 根据videoModel生成下载MediaInfo
  TXVodDownloadMediaInfo getMediaInfoByCurrent(SuperPlayerModel? model, int qualityId) {
    TXVodDownloadMediaInfo mediaInfo = TXVodDownloadMediaInfo();
    if (null != model) {
      if (model.videoId != null) {
        TXVodDownloadDataSource dataSource = TXVodDownloadDataSource();
        dataSource.appId = model.appId;
        dataSource.fileId = model.videoId!.fileId;
        dataSource.pSign = model.videoId!.psign;
        dataSource.quality = qualityId;
        dataSource.userName = "default";
        mediaInfo.dataSource = dataSource;
      } else {
        mediaInfo.url = model.videoURL;
      }
      // Downloads will be distinguished by `userName` for different users. A default user is provided here
      mediaInfo.userName = "default";
    }
    return mediaInfo;
  }

  Future<bool> isDownloaded(SuperPlayerModel? model, int width, int height) async {
    TXVodDownloadMediaInfo mediaInfo =
        getMediaInfoByCurrent(model, VideoQualityUtils.getCacheVideoQualityIndex(width, height));
    TXVodDownloadMediaInfo cacheInfo = await TXVodDownloadController.instance.getDownloadInfo(mediaInfo);
    return cacheInfo.downloadState == TXVodPlayEvent.EVENT_DOWNLOAD_FINISH;
  }

  Future<void> startDownloadBySize(SuperPlayerModel? model, int width, int height) async {
    return startDownload(model, VideoQualityUtils.getCacheVideoQualityIndex(width, height));
  }

  Future<void> startDownload(SuperPlayerModel? model, int qualityId) async {
    return TXVodDownloadController.instance.startDownload(getMediaInfoByCurrent(model, qualityId));
  }

  Future<void> startDownloadOrg(TXVodDownloadMediaInfo mediaInfo) async {
    return TXVodDownloadController.instance.startDownload(mediaInfo);
  }

  Future<void> resumeDownloadOrg(TXVodDownloadMediaInfo mediaInfo) async {
    return TXVodDownloadController.instance.resumeDownload(mediaInfo);
  }

  Future<bool> deleteDownload(TXVodDownloadMediaInfo mediaInfo) async {
    return TXVodDownloadController.instance.deleteDownloadMediaInfo(mediaInfo);
  }

  Future<void> stopDownload(TXVodDownloadMediaInfo mediaInfo) async {
    return TXVodDownloadController.instance.stopDownload(mediaInfo);
  }

  void destroy() {
    TXVodDownloadController.instance.setDownloadObserver(null, null);
  }
}

class FTXDownloadListener {
  final FTXDownlodOnStateChangeListener onStateChangeListener;
  final FTXDownlodOnErrorListener onErrorListener;

  FTXDownloadListener(this.onStateChangeListener, this.onErrorListener);
}
