// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class SuperPlayerPlugin {
  static SuperPlayerPlugin? _instance;

  static SuperPlayerPlugin get instance => _sharedInstance();

  /// SuperPlayerPlugin单例
  static SuperPlayerPlugin _sharedInstance() {
    if (_instance == null) {
      _instance = SuperPlayerPlugin._internal();
    }
    return _instance!;
  }

  final StreamController<Map<dynamic, dynamic>> _eventStreamController = StreamController.broadcast();

  /// 原生交互，通用事件监听
  Stream<Map<dynamic, dynamic>> get onEventBroadcast => _eventStreamController.stream;

  SuperPlayerPlugin._internal() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/playerPlugin/event");
    eventChannel.receiveBroadcastStream("event").listen(_eventHandler, onError: _errorHandler);
  }

  _eventHandler(event) {
    if (null == event) {
      return;
    }
    _eventStreamController.add(event);
  }

  _errorHandler(error) {}

  static const MethodChannel _channel = const MethodChannel('flutter_super_player');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 创建直播播放器
  static Future<int?> createLivePlayer() async {
    return await _channel.invokeMethod('createLivePlayer');
  }

  /// 创建点播播放器
  static Future<int?> createVodPlayer() async {
    return await _channel.invokeMethod('createVodPlayer');
  }

  /// 开关log输出
  static Future<int?> setConsoleEnabled(bool enabled) async {
    return await _channel.invokeMethod('setConsoleEnabled', {"enabled": enabled});
  }

  /// 释放播放器资源
  static Future<int?> releasePlayer(int? playerId) async {
    return await _channel.invokeMethod('releasePlayer', {"playerId": playerId});
  }

  /// 设置全局最大缓存文件个数
  static Future<void> setGlobalMaxCacheSize(int size) async {
    return await _channel.invokeMethod('setGlobalMaxCacheSize', {"size": size});
  }

  /// 设置全局点播缓存目录。点播MP4、HLS有效
  static Future<void> setGlobalCacheFolderPath(String path) async {
    return await _channel.invokeMethod('setGlobalCacheFolderPath', {"path": path});
  }

  /// 设置全局license
  static Future<void> setGlobalLicense(String licenceUrl, String licenceKey) async {
    return await _channel.invokeMethod("setGlobalLicense", {"licenceUrl": licenceUrl, "licenceKey": licenceKey});
  }

  /// 设置log输出级别 [TXLogLevel]
  static Future<void> setLogLevel(int logLevel) async {
    return await _channel.invokeMethod("setLogLevel", {"logLevel": logLevel});
  }

  /// 修改当前界面亮度
  static Future<void> setBrightness(double brightness) async {
    return await _channel.invokeMethod("setBrightness", {"brightness": brightness});
  }

  /// 恢复当前界面亮度
  static Future<void> restorePageBrightness() async {
    return await _channel.invokeMethod("setBrightness", {"brightness": -1});
  }

  /// 获得当前界面亮度 0.0 ~ 1.0
  static Future<double> getBrightness() async {
    return await _channel.invokeMethod("getBrightness");
  }

  /// 设置当前系统音量，0.0 ~ 1.0
  static Future<void> setSystemVolume(double volume) async {
    return await _channel.invokeMethod("setSystemVolume", {"volume": volume});
  }

  /// 获得当前系统音量，范围：0.0 ~ 1.0
  static Future<double> getSystemVolume() async {
    return await _channel.invokeMethod("getSystemVolume");
  }

  /// 释放音频焦点，只用于安卓端
  static Future<double> abandonAudioFocus() async {
    return await _channel.invokeMethod("abandonAudioFocus");
  }

  /// 请求获得音频焦点，只用于安卓端
  static Future<double> requestAudioFocus() async {
    return await _channel.invokeMethod("requestAudioFocus");
  }
}
