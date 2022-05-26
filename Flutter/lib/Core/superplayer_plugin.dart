part of SuperPlayer;

class SuperPlayerPlugin {
  static const MethodChannel _channel = const MethodChannel('flutter_super_player');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int?> createLivePlayer() async {
    return await _channel.invokeMethod('createLivePlayer');
  }

  static Future<int?> createVodPlayer() async {
    return await _channel.invokeMethod('createVodPlayer');
  }

  static Future<int?> setConsoleEnabled(bool enabled) async {
    return await _channel.invokeMethod('setConsoleEnabled', {"enabled": enabled});
  }

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
}
