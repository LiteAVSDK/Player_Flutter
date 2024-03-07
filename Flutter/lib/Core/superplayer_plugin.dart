// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

final TXFlutterSuperPlayerPluginAPI _playerPluginApi = TXFlutterSuperPlayerPluginAPI();
final TXFlutterNativeAPI _nativeAPI = TXFlutterNativeAPI();

class SuperPlayerPlugin {
  static const TAG = "SuperPlayerPlugin";

  static SuperPlayerPlugin? _instance;

  static SuperPlayerPlugin get instance => _sharedInstance();

  /// SuperPlayerPlugin instance
  /// SuperPlayerPlugin单例
  static SuperPlayerPlugin _sharedInstance() {
    if (_instance == null) {
      _instance = SuperPlayerPlugin._internal();
    }
    return _instance!;
  }

  final StreamController<Map<dynamic, dynamic>> _eventStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _eventPipStreamController = StreamController.broadcast();

  /// Native interaction, common event listener, events from the plugin, such as sound change events.
  /// 原生交互，通用事件监听，来自插件的事件，例如 声音变化、播放器SDK加载鉴权等事件
  Stream<Map<dynamic, dynamic>> get onEventBroadcast => _eventStreamController.stream;

  /// Native interaction, common event listener, events from the native container,
  /// such as PIP events, activity/controller lifecycle changes.
  /// 原生交互，通用事件监听，来自原生容器的事件，例如 PIP事件、activity/controller 生命周期变化
  Stream<Map<dynamic, dynamic>> get onExtraEventBroadcast => _eventPipStreamController.stream;

  FTXLicenceLoadedListener? _licenseLoadedListener;

  SuperPlayerPlugin._internal() {
    EventChannel eventChannel = EventChannel("cloud.tencent.com/playerPlugin/event");
    eventChannel.receiveBroadcastStream("event").listen(_eventHandler, onError: _errorHandler);

    EventChannel pipEventChanne = EventChannel("cloud.tencent.com/playerPlugin/componentEvent");
    pipEventChanne.receiveBroadcastStream("pipEvent").listen(_pipEventHandler, onError: _errorHandler);
    onEventBroadcast.listen((event) {
      int evtCode = event["event"];
      if (evtCode == TXVodPlayEvent.EVENT_ON_LICENCE_LOADED) {
        _licenseLoadedListener?.call(event[TXVodPlayEvent.EVENT_RESULT], event[TXVodPlayEvent.EVENT_REASON]);
      }
    });
  }

  _pipEventHandler(event) {
    if (null == event) {
      return;
    }
    LogUtils.d(TAG, "[pipEventHandler], receive event =  $event ");
    _eventPipStreamController.add(event);
  }

  _eventHandler(event) {
    if (null == event) {
      return;
    }
    _eventStreamController.add(event);
  }

  _errorHandler(error) {}

  static Future<String?> get platformVersion async {
    StringMsg stringMsg = await _playerPluginApi.getLiteAVSDKVersion();
    return stringMsg.value;
  }

  /// Creating a live streaming player
  /// 创建直播播放器
  static Future<int?> createLivePlayer() async {
    PlayerMsg playerMsg = await _playerPluginApi.createLivePlayer();
    return playerMsg.playerId;
  }

  /// Creating a VOD player
  /// 创建点播播放器
  static Future<int?> createVodPlayer() async {
    PlayerMsg playerMsg = await _playerPluginApi.createVodPlayer();
    return playerMsg.playerId;
  }

  /// Turning on/off log output
  /// 开关log输出
  static Future<void> setConsoleEnabled(bool enabled) async {
    return await _playerPluginApi.setConsoleEnabled(BoolMsg()..value = enabled);
  }

  /// Releasing player resources
  /// 释放播放器资源
  static Future<void> releasePlayer(int? playerId) async {
    return await _playerPluginApi.releasePlayer(PlayerMsg()..playerId = playerId);
  }

  /// Setting the maximum cache size for the playback engine. After setting,
  /// files in the Cache directory will be automatically cleaned up based on the set value.
  /// @param size Maximum cache size (unit: MB).
  ///
  /// 设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件
  /// @param size 最大缓存大小（单位：MB)
  static Future<void> setGlobalMaxCacheSize(int size) async {
    return await _playerPluginApi.setGlobalMaxCacheSize(IntMsg()..value = size);
  }

  /// Local caching of video files is a highly demanded feature in short video playback scenarios. For ordinary users,
  /// when watching a video that has already been viewed, it should not consume data traffic again.
  ///  @Format support: The SDK supports caching for two common VOD formats: HLS(m3u8) and MP4.
  ///  @Timing of enabling: The SDK does not enable caching by default, and it is not recommended to
  ///   enable this feature for scenarios with low user review rates.
  ///  @Method of enabling: Global effect, enabled with the player. To enable this feature, two parameters need to be configured:
  ///   the local cache directory and the cache size.
  ///
  /// The cache path is set by default to the app sandbox directory, and postfixPath only needs to pass the relative cache directory,
  /// without passing the entire absolute path.
  /// e.g. postfixPath = 'testCache'
  /// On Android platform: the video will be cached to the sdcard/Android/data/your-pkg-name/files/testCache directory.
  /// On iOS platform: the video will be cached to the Documents/testCache directory in the sandbox.
  /// @param postfixPath Cache directory
  /// @return true if the setting is successful, false if the setting fails.
  ///
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
  static Future<bool?> setGlobalCacheFolderPath(String postfixPath) async {
    BoolMsg boolMsg = await _playerPluginApi.setGlobalCacheFolderPath(StringMsg()..value = postfixPath);
    return boolMsg.value;
  }

  /// Setting the global license
  /// 设置全局license
  static Future<void> setGlobalLicense(String licenceUrl, String licenceKey) async {
    return await _playerPluginApi.setGlobalLicense(LicenseMsg()
      ..licenseKey = licenceKey
      ..licenseUrl = licenceUrl);
  }

  /// Setting the log output level [TXLogLevel]
  static Future<void> setLogLevel(int logLevel) async {
    return await _playerPluginApi.setLogLevel(IntMsg()..value = logLevel);
  }

  /// Adjusting the brightness of the current interface
  /// 修改当前界面亮度
  static Future<void> setBrightness(double brightness) async {
    return await _nativeAPI.setBrightness(DoubleMsg()..value = brightness);
  }

  /// Restoring the brightness of the current interface
  /// 恢复当前界面亮度
  static Future<void> restorePageBrightness() async {
    return await _nativeAPI.restorePageBrightness();
  }

  /// Getting the current brightness of the interface, which ranges from 0.0 to 1.0
  /// 获得当前界面亮度 0.0 ~ 1.0
  static Future<double?> getBrightness() async {
    DoubleMsg doubleMsg = await _nativeAPI.getBrightness();
    return doubleMsg.value;
  }

  /// Get the system interface brightness. The iOS system has the same interface brightness,
  /// while there may be differences in Android. Range: 0.0 ~ 1.0.
  /// 获取系统界面亮度，IOS系统与界面亮度一致，安卓可能会有差异 范围：0.0 ~ 1.0
  static Future<double?> getSysBrightness() async {
    DoubleMsg doubleMsg = await _nativeAPI.getSysBrightness();
    return doubleMsg.value;
  }

  /// Set the current system volume, 0.0 ~ 1.0.
  /// 设置当前系统音量，0.0 ~ 1.0
  static Future<void> setSystemVolume(double volume) async {
    return await _nativeAPI.setSystemVolume(DoubleMsg()..value = volume);
  }

  /// Get the current system volume, range: 0.0 ~ 1.0
  /// 获得当前系统音量，范围：0.0 ~ 1.0
  static Future<double?> getSystemVolume() async {
    DoubleMsg doubleMsg = await _nativeAPI.getSystemVolume();
    return doubleMsg.value;
  }

  /// Release audio focus, for Android only
  /// 释放音频焦点，只用于安卓端
  static Future<void> abandonAudioFocus() async {
    return await _nativeAPI.abandonAudioFocus();
  }

  /// Request audio focus, for Android only
  /// 请求获得音频焦点，只用于安卓端
  static Future<void> requestAudioFocus() async {
    return await _nativeAPI.requestAudioFocus();
  }

  /// Whether the current device supports picture-in-picture mode.
  /// @return [TXVodPlayEvent]
  /// 0 Picture-in-picture mode can be enabled.
  /// -101 The Android version is too low.
  /// -102 Picture-in-picture permission is disabled or the device does not support picture-in-picture mode.
  /// -103 The current interface has been destroyed.
  ///
  /// 当前设备是否支持画中画模式
  /// @return [TXVodPlayEvent]
  ///  0 可开启画中画模式
  ///  -101  android版本过低
  ///  -102  画中画权限关闭/设备不支持画中画
  ///  -103  当前界面已销毁
  static Future<int?> isDeviceSupportPip() async {
    IntMsg intMsg = await _nativeAPI.isDeviceSupportPip();
    return intMsg.value;
  }

  /// Getting the version of LiteAVSDK that depends on the native side
  /// 获取依赖Native端的 LiteAVSDK 的版本
  static Future<String?> getLiteAVSDKVersion() async {
    StringMsg stringMsg = await _playerPluginApi.getLiteAVSDKVersion();
    return stringMsg.value;
  }

  /// Setting the environment for accessing the LiteAV SDK.
  /// Tencent Cloud has deployed environments in various regions around the world, and different access points need to be accessed
  /// according to local policies and regulations.
  ///
  /// @param envConfig The environment to be accessed. The SDK defaults to the official environment.
  ///  @return 0: success; others: error
  ///  @note Customers targeting the Chinese mainland market should not call this interface.
  ///   If the target market is overseas users, please contact us through technical support to learn about the configuration
  ///   method of `env_config` to ensure that the App complies with GDPR standards.
  ///
  /// 设置 liteav SDK 接入的环境。
  /// 腾讯云在全球各地区部署的环境，按照各地区政策法规要求，需要接入不同地区接入点。
  ///
  /// @param envConfig 需要接入的环境，SDK 默认接入的环境是：默认正式环境。
  /// @return 0：成功；其他：错误
  /// @note 目标市场为中国大陆的客户请不要调用此接口，如果目标市场为海外用户，请通过技术支持联系我们，了解 env_config 的配置方法，以确保 App 遵守 GDPR 标准。
  ///
  static Future<int?> setGlobalEnv(String envConfig) async {
    IntMsg intMsg = await _playerPluginApi.setGlobalEnv(StringMsg()..value = envConfig);
    return intMsg.value;
  }

  /// Starts listening for device rotation direction. After it is turned on, if the device's auto-rotation is turned on,
  /// the player will automatically rotate the video direction based on the current device orientation.
  /// <h1>This interface is currently only applicable to the Android side, and the iOS side will automatically enable this feature</h1>
  /// Before calling this interface, please be sure to inform the user of the privacy risks.
  /// If necessary, confirm whether you have permission to access the rotation sensor.
  /// @return true: success
  /// false: failure, due to premature enabling, waiting for context initialization, failure to obtain sensor, etc.
  ///
  /// 开始监听设备旋转方向，开启之后，如果设备自动旋转打开，播放器会自动根据当前设备方向来旋转视频方向。
  /// <h1>该接口目前只适用安卓端，IOS端会自动开启该能力</h1>
  /// 在调用该接口前，请务必向用户告知隐私风险。
  /// 如有需要，请确认是否有获取旋转sensor的权限。
  /// @return true : 开启成功
  ///         false : 开启失败，如开启过早，还未等到上下文初始化、获取sensor失败等原因
  static Future<bool?> startVideoOrientationService() async {
    BoolMsg boolMsg = await _playerPluginApi.startVideoOrientationService();
    return boolMsg.value;
  }

  ///
  /// register or unregister system brightness.if register the system brightness observer,
  /// current window brightness wil changed by system brightness's change.
  /// <h2>only for android</h2>
  /// @param isRegister:true register system brightness
  ///                  :false unregister system brightness
  ///
  static Future<void> registerSysBrightness(bool isRegister) async {
    await _nativeAPI.registerSysBrightness(BoolMsg()..value = isRegister);
  }

  ///
  /// 设置SDK的监听，目前有licence加载监听，后续还会陆续开放其他类型的监听
  ///
  /// Set up SDK listeners, currently there is a license loading listener, and other types of listeners
  /// will be gradually opened in the future.
  ///
  void setSDKListener({FTXLicenceLoadedListener? licenceLoadedListener}) {
    _licenseLoadedListener = licenceLoadedListener;
  }
}
