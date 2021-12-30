
part of SuperPlayer;

class SuperPlayerPlugin {
  static const MethodChannel _channel =
  const MethodChannel('super_player');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int?> createLivePlayer() async{
    return await _channel.invokeMethod('createLivePlayer');
  }

  static Future<int?> createVodPlayer() async{
    return await _channel.invokeMethod('createVodPlayer');
  }

  static Future<int?> setConsoleEnabled(bool enabled) async{
    return await _channel.invokeMethod('setConsoleEnabled',{"enabled":enabled});
  }

  static Future<int?> releasePlayer(int? playerId) async{
    return await _channel.invokeMethod('releasePlayer',{"playerId":playerId});
  }

}