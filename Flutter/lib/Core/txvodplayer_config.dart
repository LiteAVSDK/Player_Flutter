part of SuperPlayer;

/// TXVodPlayer config
class FTXVodPlayConfig {
  // 最大重连次数
  int connectRetryCount = 3;
  // 重连周期
  int connectRetryInterval = 3;

  int timeout = 10;

  String cacheFolderPath = "";

  int maxCacheItems = 0;

  int playerType = 0;

  Map<String, String> headers = {};

  // 精准seek
  bool enableAccurateSeek = true;

  bool autoRotate = true;

  bool smoothSwitchBitrate = false;

  String cacheMp4ExtName = "mp4";

  int progressInterval = 0;

  int maxBufferSize = 0;

  int maxPreloadSize = 0;

  int firstStartPlayBufferTime = 0;

  int nextStartPlayBufferTime = 0;

  String overlayKey = ""; // HLS安全加固加解密key
  String overlayIv = ""; // HLS安全加固加解密Iv

  Map<String, Object> extInfoMap = {}; // 设置一些不必周知的特殊配置

  /// 是否允许加载后渲染后处理服务
  /// 默认开启，开启后超分插件如果存在，默认加载
  bool enableRenderProcess = true;

  /// 优先播放的分辨率，preferredResolution = width * height
  int preferredResolution = -1;


  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["connectRetryCount"] = connectRetryCount;
    json["connectRetryInterval"] = connectRetryInterval;
    json["timeout"] = timeout;
    json["cacheFolderPath"] = cacheFolderPath;
    json["maxCacheItems"] = maxCacheItems;
    json["headers"] = headers;
    json["playerType"] = playerType;
    json["enableAccurateSeek"] = enableAccurateSeek;
    json["autoRotate"] = autoRotate;
    json["smoothSwitchBitrate"] = smoothSwitchBitrate;
    json["cacheMp4ExtName"] = cacheMp4ExtName;
    json["progressInterval"] = progressInterval;
    json["maxBufferSize"] = maxBufferSize;
    json["maxPreloadSize"] = maxPreloadSize;
    json["firstStartPlayBufferTime"] = firstStartPlayBufferTime;
    json["nextStartPlayBufferTime"] = nextStartPlayBufferTime;
    json["overlayKey"] = overlayKey;
    json["overlayIv"] = overlayIv;
    json["extInfoMap"] = extInfoMap;
    json["enableRenderProcess"] = enableRenderProcess;
    json["preferredResolution"] = preferredResolution;
    return json;
  }
}