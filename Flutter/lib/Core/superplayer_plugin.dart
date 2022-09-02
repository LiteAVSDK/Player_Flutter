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
  final StreamController<Map<dynamic, dynamic>> _eventPipStreamController = StreamController.broadcast();

  /// 原生交互，通用事件监听，来自插件的事件，例如 声音变化等事件
  Stream<Map<dynamic, dynamic>> get onEventBroadcast => _eventStreamController.stream;

  /// 原生交互，通用事件监听，来自原生容器的事件，例如 PIP事件、activity/controller 生命周期变化
  Stream<Map<dynamic, dynamic>> get onExtraEventBroadcast => _eventPipStreamController.stream;

  SuperPlayerPlugin._internal() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/playerPlugin/event");
    eventChannel.receiveBroadcastStream("event").listen(_eventHandler, onError: _errorHandler);

    EventChannel pipEventChanne = EventChannel("cloud.tencent.com/playerPlugin/pipEvent");
    pipEventChanne.receiveBroadcastStream("pipEvent").listen(_pipEventHandler, onError: _errorHandler);
  }

  _pipEventHandler(event) {
    if (null == event) {
      return;
    }
    _eventPipStreamController.add(event);
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

  /// 设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件
  /// @param size 最大缓存大小（单位：MB)
  static Future<void> setGlobalMaxCacheSize(int size) async {
    return await _channel.invokeMethod('setGlobalMaxCacheSize', {"size": size});
  }

  /// 在短视频播放场景中，视频文件的本地缓存是很刚需的一个特性，对于普通用户而言，一个已经看过的视频再次观看时，不应该再消耗一次流量。
  ///  @格式支持：SDK 支持 HLS(m3u8) 和 MP4 两种常见点播格式的缓存功能。
  ///  @开启时机：SDK 并不默认开启缓存功能，对于用户回看率不高的场景，也并不推荐您开启此功能。
  ///  @开启方式：全局生效，在使用播放器开启。开启此功能需要配置两个参数：本地缓存目录及缓存大小。
  ///
  /// 该缓存路径默认设置到app沙盒目录下，postfixPath只需要传递相对缓存目录即可，不需要传递整个绝对路径。
  /// e.g. postfixPath = 'testCache'
  /// Android 平台：视频将会缓存到sdcard的Android/data/your-pkg-name/files/testCache 目录。
  /// iOS 平台：视频将会缓存到沙盒的Documents/testCache 目录。
  /// @param postfixPath 缓存目录
  /// @return true 设置成功 false 设置失败
  static Future<bool> setGlobalCacheFolderPath(String postfixPath) async {
    return await _channel.invokeMethod('setGlobalCacheFolderPath', {"postfixPath": postfixPath});
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
    return await _channel.invokeMethod("setBrightness", {"brightness": -1.0});
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

  /// 当前设备是否支持画中画模式
  /// @return [TXVodPlayEvent]
  ///  0 可开启画中画模式
  ///  -101  android版本过低
  ///  -102  画中画权限关闭/设备不支持画中画
  ///  -103  当前界面已销毁
  static Future<int> isDeviceSupportPip() async {
    return await _channel.invokeMethod("isDeviceSupportPip");
  }

  /// 获取依赖Native端的 LiteAVSDK 的版本
  static Future<String?> getLiteAVSDKVersion() async {
    return await _channel.invokeMethod('getLiteAVSDKVersion');
  }

  ///
  /// 设置 liteav SDK 接入的环境。
  /// 腾讯云在全球各地区部署的环境，按照各地区政策法规要求，需要接入不同地区接入点。
  ///
  /// @param envConfig 需要接入的环境，SDK 默认接入的环境是：默认正式环境。
  /// @return 0：成功；其他：错误
  /// @note 目标市场为中国大陆的客户请不要调用此接口，如果目标市场为海外用户，请通过技术支持联系我们，了解 env_config 的配置方法，以确保 App 遵守 GDPR 标准。
  ///
  static Future<int> setGlobalEnv(String envConfig) async {
    return await _channel.invokeMethod("setGlobalEnv", {"envConfig": envConfig});
  }
}
