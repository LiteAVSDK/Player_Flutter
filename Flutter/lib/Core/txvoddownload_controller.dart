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

  FTXPredownlodOnCompleteListener? _onPreDownloadOnCompleteListener;
  FTXPredownlodOnErrorListener? _onPreDownloadOnErrorListener;

  FTXDownlodOnStateChangeListener? _downlodOnStateChangeListener;
  FTXDownlodOnErrorListener? _downlodOnErrorListener;

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
    final int preloadSizeMB,
    final int preferredResolution, {
    FTXPredownlodOnCompleteListener? onCompleteListener,
    FTXPredownlodOnErrorListener? onErrorListener,
  }) async {
    _onPreDownloadOnCompleteListener = onCompleteListener;
    _onPreDownloadOnErrorListener = onErrorListener;
    IntMsg msg = await _api.startPreLoad(PreLoadMsg()
      ..playUrl = playUrl
      ..preloadSizeMB = preloadSizeMB
      ..preferredResolution = preferredResolution);
    return msg.value ?? -1;
  }

  /// 停止预下载。
  /// taskId： 任务id,[startPreLoad]返回值
  Future<void> stopPreLoad(final int taskId) async {
    await _api.stopPreLoad(IntMsg()..value = taskId);
  }

  /// 开始下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> startDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.startDownload(mediaInfo.toMsg());
  }

  /// 继续下载，与开始下载接口有区别，该接口会寻找对应的缓存，复用之前的缓存来续点下载，
  /// 而开始下载接口会启动一个全新的下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> resumeDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.resumeDownload(mediaInfo.toMsg());
  }

  /// 停止下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMediaInfo]
  Future<void> stopDownload(TXVodDownloadMediaInfo mediaInfo) async {
    await _api.stopDownload(mediaInfo.toMsg());
  }

  /// 设置下载请求头
  Future<void> setDownloadHeaders(Map<String, String> headers) async {
    await _api.setDownloadHeaders(new MapMsg()..map = headers);
  }

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

  /// 获得指定视频的下载信息
  /// return [TXVodDownloadMediaInfo]
  Future<TXVodDownloadMediaInfo> getDownloadInfo(TXVodDownloadMediaInfo mediaInfo) async {
    TXVodDownloadMediaMsg msg = await _api.getDownloadInfo(mediaInfo.toMsg());
    return _getDownloadInfoFromMsg(msg);
  }

  /// 设置下载事件监听，该监听为全局下载监听配置，重复调用
  void setDownloadObserver(FTXDownlodOnStateChangeListener? downlodOnStateChangeListener,
      FTXDownlodOnErrorListener? downlodOnErrorListener) {
    _downlodOnStateChangeListener = downlodOnStateChangeListener;
    _downlodOnErrorListener = downlodOnErrorListener;
  }

  /// 删除下载任务
  Future<bool> deleteDownloadMediaInfo(TXVodDownloadMediaInfo mediaInfo) async {
    BoolMsg msg = await _api.deleteDownloadMediaInfo(mediaInfo.toMsg());
    return msg.value ?? false;
  }

  TXVodDownloadMediaInfo _getDownloadInfoFromMap(Map<dynamic, dynamic> map) {
    TXVodDownloadMediaInfo medialnfo = TXVodDownloadMediaInfo();
    medialnfo.playPath = map["playPath"];
    medialnfo.progress = map["progress"];
    medialnfo.downloadState = map["downloadState"];
    medialnfo.userName = map["userName"];
    medialnfo.duration = map["duration"];
    medialnfo.playableDuration = map["playableDuration"];
    medialnfo.size = map["size"];
    medialnfo.downloadSize = map["downloadSize"];
    medialnfo.url = map["url"];
    if (map.keys.contains("appId")) {
      TXVodDownloadDataSource dataSource = TXVodDownloadDataSource();
      dataSource.appId = map["appId"];
      dataSource.fileId = map["fileId"];
      dataSource.pSign = map["pSign"];
      dataSource.token = map["token"];
      dataSource.userName = map["userName"];
      dataSource.quality = map["quality"];
      medialnfo.dataSource = dataSource;
    }
    return medialnfo;
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
    LogUtils.d(TAG, '_eventHandler, event= ${event}');
    final Map<dynamic, dynamic> map = event;
    int eventCode = map["event"];
    switch (eventCode) {
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_COMPLETE:
        int taskId = map['taskId'];
        String url = map['url'];
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_COMPLETE, taskID=${taskId} ,url=${url}');
        if (_onPreDownloadOnCompleteListener != null) {
          _onPreDownloadOnCompleteListener!(taskId, url);
        }
        break;
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_ERROR:
        int taskId = map['taskId'];
        String url = map['url'];
        int code = map['code'] ?? 0;
        String msg = map['msg'] ?? '';
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_ERROR, taskID=${taskId} ,url=${url}, code=${code} , msg=${msg}');
        if (_onPreDownloadOnErrorListener != null) {
          _onPreDownloadOnErrorListener!(taskId, url, code, msg);
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
