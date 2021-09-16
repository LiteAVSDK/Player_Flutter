// @dart = 2.7
part of SuperPlayer;

class SuperPlayerViewConfig {
  bool mirror = false;
  bool hwAcceleration = true;
  double playRate = 1.0;
  bool mute = false;
  int renderMode = 0;
  Map headers = {};
  int maxCacheItem = 0;
  String playShiftDomain = "liteavapp.timeshift.qcloud.com";
  bool enableLog = false;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["mirror"] = mirror;
    json["hwAcceleration"] = hwAcceleration;
    json["playRate"] = playRate;
    json["mute"] = mute;
    json["renderMode"] = renderMode;
    json["headers"] = headers;
    json["maxCacheItem"] = maxCacheItem;
    json["playShiftDomain"] = playShiftDomain;
    json["enableLog"] = enableLog;
    return json;
  }
}