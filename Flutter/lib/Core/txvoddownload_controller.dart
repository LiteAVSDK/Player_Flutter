// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// include features:
/// 1. Video predownlaod
/// 2. Video download
class TXVodDownlaodController {
  static const String TAG = 'TXVodDownlaodController';
  static TXVodDownlaodController? _instance;
  static TXVodDownlaodController get instance => _sharedInstance();

  StreamSubscription? _downloadEventSubscription;
  final StreamController<Map<dynamic, dynamic>> _downloadEventStreamController = StreamController.broadcast();
  Stream<Map<dynamic, dynamic>> get onDownlaodEventBroadcast => _downloadEventStreamController.stream;
  late MethodChannel _methodChannel;

  FTXPredownlodOnCompleteListener? _onPreDownloadOnCompleteListener;
  FTXPredownlodOnErrorListener? _onPreDownloadOnErrorListener;

  static TXVodDownlaodController _sharedInstance() {
    if (_instance == null) {
      _instance = TXVodDownlaodController._createInsatnce();
    }
    return _instance!;
  }

  TXVodDownlaodController._createInsatnce() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/txvodplayer/download/event");
    _downloadEventSubscription = eventChannel.receiveBroadcastStream('event')
        .listen(_eventHandler, onError: _errorHandler);
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
  Future<int> startPreLoad(final String playUrl,
      final int preloadSizeMB,
      final int preferredResolution,
      { FTXPredownlodOnCompleteListener? onCompleteListener,
        FTXPredownlodOnErrorListener? onErrorListener,
      }) async {
    _onPreDownloadOnCompleteListener = onCompleteListener;
    _onPreDownloadOnErrorListener = onErrorListener;
    var map = {"playUrl": playUrl,
      "preloadSizeMB": preloadSizeMB,
      "preferredResolution": preferredResolution };
    return await _methodChannel.invokeMethod("startPreLoad", map);
  }


  /// 停止预下载。
  /// taskId： 任务id,[startPreLoad]返回值
  Future<void> stopPreLoad(final int taskId) async {
    var map = {"taskId": taskId};
    await _methodChannel.invokeMethod("stopPreLoad", map);
  }


  _eventHandler(event) {
    if (null == event) {
      return;
    }
    LogUtils.d(TAG, '_eventHandler, event= ${event}');
    final Map<dynamic, dynamic> map = event;
    switch (map["event"]) {
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
      default:
        break;
    }
    _downloadEventStreamController.add(event);
  }

  _errorHandler(error) {

  }
}