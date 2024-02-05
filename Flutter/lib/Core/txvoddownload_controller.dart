// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

final TXFlutterDownloadApi _api = TXFlutterDownloadApi();

/// include features:
/// 1. Video predownlaod
/// 2. Video download
class TXVodDownloadController {
  static const String TAG = 'TXVodDownlaodController';
  static TXVodDownloadController? _instance;

  static TXVodDownloadController get instance => _sharedInstance();

  StreamSubscription? _downloadEventSubscription;
  final StreamController<Map<dynamic, dynamic>> _downloadEventStreamController = StreamController.broadcast();

  Stream<Map<dynamic, dynamic>> get onDownloadEventBroadcast => _downloadEventStreamController.stream;

  Map<int, _PreloadListener> _preloadListeners = {};
  Map<int, _PreloadListener> _fileIdBeforeStartListeners = {};
  FTXDownlodOnStateChangeListener? _downlodOnStateChangeListener;
  FTXDownlodOnErrorListener? _downlodOnErrorListener;
  AtomicInt _atomicPreloadId = AtomicInt(0);

  static TXVodDownloadController _sharedInstance() {
    if (_instance == null) {
      _instance = TXVodDownloadController._createInstance();
    }
    return _instance!;
  }

  TXVodDownloadController._createInstance() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/txvodplayer/download/event");
    _downloadEventSubscription =
        eventChannel.receiveBroadcastStream('event').listen(_eventHandler, onError: _errorHandler);
  }

  /// Start pre-downloading.
  /// [Important] Before starting pre-download, please set the cache directory [SuperPlayerPlugin.setGlobalCacheFolderPath] and cache size [SuperPlayerPlugin.setGlobalMaxCacheSize] of the playback engine first. This setting is a global configuration and needs to be consistent with the player to avoid invalidation of playback cache.
  /// playUrl: The URL to be pre-downloaded.
  /// preloadSizeMB: The pre-downloaded size (unit: MB).
  /// preferredResolution: The expected resolution, long type, value is height x width. For example, 720*1080. If multiple resolutions are not supported or not specified, pass -1.
  /// onCompleteListener: Pre-download successful callback.
  /// onErrorListener: Pre-download failed callback.
  /// Return value: Task ID, which can be used to stop pre-download [stopPreload].
  ///
  /// 启动预下载。
  /// 【重要】启动预下载前，请先设置好播放引擎的缓存目录[SuperPlayerPlugin.setGlobalCacheFolderPath]和缓存大小[SuperPlayerPlugin.setGlobalMaxCacheSize]，这个设置是全局配置需和播放器保持一致，否则会造成播放缓存失效。
  /// playUrl: 要预下载的url
  /// preloadSizeMB: 预下载的大小（单位：MB）
  /// preferredResolution 期望分辨率，long类型，值为高x宽。可参考如720*1080。不支持多分辨率或不需指定时，传-1。
  /// onCompleteListener：预下载成功回调
  /// onErrorListener：预下载失败回调
  /// 返回值：任务ID，可用这个任务ID停止预下载 [stopPreload]
  Future<int> startPreLoad(
    final String playUrl,
    final double preloadSizeMB,
    final int preferredResolution, {
    FTXPredownlodOnCompleteListener? onCompleteListener,
    FTXPredownlodOnErrorListener? onErrorListener,
  }) async {
    IntMsg msg = await _api.startPreLoad(PreLoadMsg()
      ..playUrl = playUrl
      ..preloadSizeMB = preloadSizeMB
      ..preferredResolution = preferredResolution);
    int taskId = msg.value ?? -1;
    if (taskId >= 0) {
      _preloadListeners[taskId] = _PreloadListener()
          ..onCompleteListener = onCompleteListener
          ..onErrorListener = onErrorListener;
    }
    return taskId;
  }

  Future<void> startPreload(
    TXPlayInfoParams txPlayInfoParams,
    final double preloadSizeMB,
    final int preferredResolution, {
    FTXPredownlodOnCompleteListener? onCompleteListener,
    FTXPredownlodOnErrorListener? onErrorListener,
    FTXPredownlodOnStartListener? onStartListener,
  }) async {
    int tmpPreloadTaskId = await _atomicPreloadId.incrementAndGet();
    await _api.startPreLoadByParams(PreLoadInfoMsg()
      ..tmpPreloadTaskId = tmpPreloadTaskId
      ..playUrl = txPlayInfoParams.url
      ..fileId = txPlayInfoParams.fileId
      ..appId = txPlayInfoParams.appId
      ..pSign = txPlayInfoParams.psign
      ..preloadSizeMB = preloadSizeMB
      ..preferredResolution = preferredResolution);
    _fileIdBeforeStartListeners[tmpPreloadTaskId] = _PreloadListener()
      ..onCompleteListener = onCompleteListener
      ..onErrorListener = onErrorListener
      ..onStartListener = onStartListener;
  }

  /// Stop pre-downloading.
  /// taskId: Task ID, returned by [startPreLoad].
  ///
  /// 停止预下载。
  /// taskId： 任务id,[startPreLoad]返回值
  Future<void> stopPreLoad(final int taskId) async {
    await _api.stopPreLoad(IntMsg()..value = taskId);
  }

  /// Start downloading.
  /// videoDownloadModel: Download constructor [TXVodDownloadMediaInfo].
  ///
  /// 开始下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> startDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.startDownload(mediaInfo.toMsg());
  }

  /// Resume downloading. This interface is different from the start downloading interface.
  /// This interface will find the corresponding cache and reuse the previous cache to resume downloading,
  /// while the start downloading interface will start a brand new download.
  /// videoDownloadModel: Download constructor [TXVodDownloadMediaInfo].
  ///
  /// 继续下载，与开始下载接口有区别，该接口会寻找对应的缓存，复用之前的缓存来续点下载，
  /// 而开始下载接口会启动一个全新的下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> resumeDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.resumeDownload(mediaInfo.toMsg());
  }

  /// Stop downloading.
  /// videoDownloadModel: Download constructor [TXVodDownloadMediaInfo].
  ///
  /// 停止下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> stopDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.stopDownload(mediaInfo.toMsg());
  }

  /// Set download request headers.
  ///
  /// 设置下载请求头
  Future<void> setDownloadHeaders(Map<String, String> headers) async {
    await _api.setDownloadHeaders(new MapMsg()..map = headers);
  }

  /// Get all video download lists.
  /// return [TXVodDownloadMediaInfo].
  ///
  /// 获取所有视频下载列表
  /// return [TXVodDownloadMediaInfo]
  Future<List<TXVodDownloadMediaInfo>> getDownloadList() async {
    TXDownloadListMsg listMsg = await _api.getDownloadList();
    List<TXVodDownloadMediaInfo> outputList = [];
    if (null != listMsg.infoList) {
      for (TXVodDownloadMediaMsg? msg in listMsg.infoList!) {
        if (null != msg) {
          outputList.add(_getDownloadInfoFromMsg(msg));
        }
      }
    }
    return outputList;
  }

  /// Get the download information of the specified video.
  /// return [TXVodDownloadMediaInfo].
  ///
  /// 获得指定视频的下载信息
  /// return [TXVodDownloadMediaInfo]
  Future<TXVodDownloadMediaInfo> getDownloadInfo(TXVodDownloadMediaInfo mediaInfo) async {
    TXVodDownloadMediaMsg msg = await _api.getDownloadInfo(mediaInfo.toMsg());
    return _getDownloadInfoFromMsg(msg);
  }

  /// Set the download event listener. This listener is a global download listener configuration and can be called repeatedly.
  ///
  /// 设置下载事件监听，该监听为全局下载监听配置，重复调用
  void setDownloadObserver(FTXDownlodOnStateChangeListener? downlodOnStateChangeListener,
      FTXDownlodOnErrorListener? downlodOnErrorListener) {
    _downlodOnStateChangeListener = downlodOnStateChangeListener;
    _downlodOnErrorListener = downlodOnErrorListener;
  }

  /// Delete download task.
  ///
  /// 删除下载任务
  Future<bool> deleteDownloadMediaInfo(TXVodDownloadMediaInfo mediaInfo) async {
    BoolMsg msg = await _api.deleteDownloadMediaInfo(mediaInfo.toMsg());
    return msg.value ?? false;
  }

  TXVodDownloadMediaInfo _getDownloadInfoFromMap(Map<dynamic, dynamic> map) {
    TXVodDownloadMediaInfo mediaInfo = TXVodDownloadMediaInfo();
    mediaInfo.playPath = map["playPath"];
    mediaInfo.progress = map["progress"];
    mediaInfo.downloadState = map["downloadState"];
    mediaInfo.userName = map["userName"];
    mediaInfo.duration = map["duration"];
    mediaInfo.playableDuration = map["playableDuration"];
    mediaInfo.size = map["size"];
    mediaInfo.downloadSize = map["downloadSize"];
    mediaInfo.url = map["url"];
    if (map.keys.contains("appId")) {
      TXVodDownloadDataSource dataSource = TXVodDownloadDataSource();
      dataSource.appId = map["appId"];
      dataSource.fileId = map["fileId"];
      dataSource.pSign = map["pSign"];
      dataSource.token = map["token"];
      dataSource.userName = map["userName"];
      dataSource.quality = map["quality"];
      mediaInfo.dataSource = dataSource;
    }
    mediaInfo.speed = map["speed"];
    mediaInfo.isResourceBroken = map["isResourceBroken"];

    return mediaInfo;
  }

  TXVodDownloadMediaInfo _getDownloadInfoFromMsg(TXVodDownloadMediaMsg msg) {
    TXVodDownloadMediaInfo mediaInfo = TXVodDownloadMediaInfo();
    mediaInfo.playPath = msg.playPath;
    mediaInfo.progress = msg.progress;
    mediaInfo.downloadState = msg.downloadState;
    mediaInfo.userName = msg.userName;
    mediaInfo.duration = msg.duration;
    mediaInfo.playableDuration = msg.playableDuration;
    mediaInfo.size = msg.size;
    mediaInfo.downloadSize = msg.downloadSize;
    mediaInfo.url = msg.url;
    if (null != msg.appId) {
      TXVodDownloadDataSource dataSource = TXVodDownloadDataSource();
      dataSource.appId = msg.appId;
      dataSource.fileId = msg.fileId;
      dataSource.pSign = msg.pSign;
      dataSource.token = msg.token;
      dataSource.userName = msg.userName;
      dataSource.quality = msg.quality;
      mediaInfo.dataSource = dataSource;
    }
    return mediaInfo;
  }

  _eventHandler(event) {
    if (null == event) {
      return;
    }
    LogUtils.d(TAG, '_eventHandler, event= $event');
    final Map<dynamic, dynamic> map = event;
    int eventCode = map["event"];
    switch (eventCode) {
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_COMPLETE:
        int taskId = map['taskId'];
        String url = map['url'];
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_COMPLETE, taskID=$taskId ,url=$url');
        _preloadListeners[taskId]?.onCompleteListener?.call(taskId, url);
        _preloadListeners.remove(taskId);
        break;
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_ERROR:
        int tmpTaskId = map['tmpTaskId'] ?? -1;
        int taskId = map['taskId'];
        String url = map['url'];
        int code = map['code'] ?? 0;
        String msg = map['msg'] ?? '';
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_ERROR, taskID=$taskId ,url=$url, code=$code , msg=$msg');
        if (tmpTaskId >= 0) {
          _fileIdBeforeStartListeners[tmpTaskId]!.onErrorListener?.call(taskId, url, code, msg);
          _fileIdBeforeStartListeners.remove(tmpTaskId);
        } else {
          _preloadListeners[taskId]?.onErrorListener?.call(taskId, url, code, msg);
          _preloadListeners.remove(taskId);
        }
        break;
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_START:
        int tmpTaskId = map['tmpTaskId'];
        int taskId = map['taskId'];
        String fileId = map['fileId'] ?? '';
        String url = map['url'] ?? '';
        Map<dynamic, dynamic> bundle = map['params'] ?? {};
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_START, tmpTaskId=$tmpTaskId, '
            'taskID=$taskId ,fileId=$fileId, url=$url , bundle=$bundle');
        if (_fileIdBeforeStartListeners[tmpTaskId] != null) {
          _preloadListeners[taskId] = _fileIdBeforeStartListeners[tmpTaskId]!;
          _preloadListeners[taskId]!.onStartListener?.call(taskId, fileId, url, bundle);
          _fileIdBeforeStartListeners.remove(tmpTaskId);
        }
        break;
      case TXVodPlayEvent.EVENT_DOWNLOAD_START:
      case TXVodPlayEvent.EVENT_DOWNLOAD_PROGRESS:
      case TXVodPlayEvent.EVENT_DOWNLOAD_STOP:
      case TXVodPlayEvent.EVENT_DOWNLOAD_FINISH:
        _downlodOnStateChangeListener?.call(eventCode, _getDownloadInfoFromMap(map));
        break;
      case TXVodPlayEvent.EVENT_DOWNLOAD_ERROR:
        TXVodDownloadMediaInfo info = _getDownloadInfoFromMap(map);
        int errorCode = map["errorCode"];
        String errorMsg = map["errorMsg"];
        _downlodOnErrorListener?.call(errorCode, errorMsg, info);
        break;
      default:
        break;
    }
    _downloadEventStreamController.add(event);
  }

  _errorHandler(error) {}

}

class _PreloadListener {
  FTXPredownlodOnCompleteListener? onCompleteListener;
  FTXPredownlodOnErrorListener? onErrorListener;
  FTXPredownlodOnStartListener? onStartListener;
  _PreloadListener({this.onCompleteListener, this.onErrorListener, this.onStartListener});
}

class AtomicInt {
  int _value = 0;
  final _lock = Lock();

  AtomicInt(this._value);

  Future<int> get() async {
    return await _lock.synchronized(() async {
      return _value;
    });
  }

  Future<int> incrementAndGet() async {
    return await _lock.synchronized(() async {
      _value++;
      return _value;
    });
  }
}
