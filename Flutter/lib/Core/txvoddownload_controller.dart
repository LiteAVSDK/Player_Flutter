// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

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
  late MethodChannel _methodChannel;

  FTXPredownlodOnCompleteListener? _onPreDownloadOnCompleteListener;
  FTXPredownlodOnErrorListener? _onPreDownloadOnErrorListener;

  FTXDownlodOnStateChangeListener? _downlodOnStateChangeListener;
  FTXDownlodOnErrorListener? _downlodOnErrorListener;

  static TXVodDownloadController _sharedInstance() {
    if (_instance == null) {
      _instance = TXVodDownloadController._createInsatnce();
    }
    return _instance!;
  }

  TXVodDownloadController._createInsatnce() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/txvodplayer/download/event");
    _downloadEventSubscription =
        eventChannel.receiveBroadcastStream('event').listen(_eventHandler, onError: _errorHandler);
    _methodChannel = MethodChannel("cloud.tencent.com/txvodplayer/download/api");
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
    var map = {"playUrl": playUrl, "preloadSizeMB": preloadSizeMB, "preferredResolution": preferredResolution};
    return await _methodChannel.invokeMethod("startPreLoad", map);
  }

  /// 停止预下载。
  /// taskId： 任务id,[startPreLoad]返回值
  Future<void> stopPreLoad(final int taskId) async {
    var map = {"taskId": taskId};
    await _methodChannel.invokeMethod("stopPreLoad", map);
  }

  /// 开始下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMedialnfo]
  /// userName: 下载用户，用来区分不同用户的下载，可不传，不传则使用默认值
  Future<void> startDonwload(TXVodDownloadMedialnfo medialnfo) async {
    await _methodChannel.invokeMethod("startDownload", medialnfo.toJson());
  }

  /// 停止下载
  /// videoDownloadModel: 下载构造体 [TXVodDownloadMedialnfo]
  Future<void> stopDownload(TXVodDownloadMedialnfo medialnfo) async {
    await _methodChannel.invokeMethod("stopDownload", medialnfo.toJson());
  }

  /// 设置下载请求头
  Future<void> setDownloadHeaders(Map<String, String> headers) async {
    await _methodChannel.invokeMethod("setDownloadHeaders", {"headers": headers});
  }

  /// 获取所有视频下载列表
  /// return [TXVodDownloadMedialnfo]
  Future<List<TXVodDownloadMedialnfo>> getDownloadList() async {
    List<TXVodDownloadMedialnfo> outputList = [];
    List<dynamic> donwloadOrgList = await _methodChannel.invokeMethod("getDownloadList");
    for (dynamic data in donwloadOrgList) {
      outputList.add(_getDownloadInfoFromMap(data));
    }
    return outputList;
  }

  /// 获得指定视频的下载信息
  /// return [TXVodDownloadMedialnfo]
  Future<TXVodDownloadMedialnfo> getDownloadInfo(TXVodDownloadMedialnfo medialnfo) async {
    Map<dynamic, dynamic> data = await _methodChannel.invokeMethod("getDownloadInfo", medialnfo.toJson());
    return _getDownloadInfoFromMap(data);
  }

  /// 设置下载事件监听，该监听为全局下载监听配置，重复调用，listener会先后覆盖
  void setDownloadObserver(
      FTXDownlodOnStateChangeListener downlodOnStateChangeListener, FTXDownlodOnErrorListener downlodOnErrorListener) {
    _downlodOnStateChangeListener = downlodOnStateChangeListener;
    _downlodOnErrorListener = downlodOnErrorListener;
  }

  TXVodDownloadMedialnfo _getDownloadInfoFromMap(Map<dynamic, dynamic> map) {
    TXVodDownloadMedialnfo medialnfo = TXVodDownloadMedialnfo();
    medialnfo.playPath = map["playPath"];
    medialnfo.progress = map["progress"];
    medialnfo.downloadState = map["downloadState"];
    medialnfo.userName = map["userName"];
    medialnfo.duration = map["duration"];
    medialnfo.playableDuration = map["playableDuration"];
    medialnfo.size = map["size"];
    medialnfo.downloadSize = map["downloadSize"];
    medialnfo.url = map["url"];
    if(map.keys.contains("appId")) {
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

  _eventHandler(event) {
    if (null == event) {
      return;
    }
    LogUtils.d(TAG, '_eventHandler, event= ${event}');
    final Map<dynamic, dynamic> map = event;
    int eventCode = map["event"];
    switch (eventCode) {
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_COMPLETE:
        int taskId = map['taskId'] as int;
        String url = map['url'] as String;
        LogUtils.d(TAG, 'receive EVENT_PREDOWNLOAD_ON_COMPLETE, taskID=${taskId} ,url=${url}');
        if (_onPreDownloadOnCompleteListener != null) {
          _onPreDownloadOnCompleteListener!(taskId, url);
        }
        break;
      case TXVodPlayEvent.EVENT_PREDOWNLOAD_ON_ERROR:
        int taskId = map['taskId'] as int;
        String url = map['url'] as String;
        int code = map['code'] as int;
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
        TXVodDownloadMedialnfo info = _getDownloadInfoFromMap(map);
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
