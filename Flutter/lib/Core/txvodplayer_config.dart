// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// TXVodPlayer config
class FTXVodPlayConfig {
  // 播放器重连次数
  int connectRetryCount = 3;
  // 播放器重连间隔
  int connectRetryInterval = 3;
  // 播放器连接超时时间
  int timeout = 10;
  // 仅iOS平台生效 [PlayerType]
  int playerType = PlayerType.THUMB_PLAYER;
  // 自定义http headers
  Map<String, String> headers = {};
  // 是否精确seek，默认true
  bool enableAccurateSeek = true;
  // 播放mp4文件时，若设为true则根据文件中的旋转角度自动旋转。
  // 旋转角度可在PLAY_EVT_CHANGE_ROTATION事件中获得。默认true
  bool autoRotate = true;
  // 平滑切换多码率HLS，默认false。设为false时，可提高多码率地址打开速度;
  // 设为true，在IDR对齐时可平滑切换码率
  bool smoothSwitchBitrate = false;
  // 缓存mp4文件扩展名,默认mp4
  String cacheMp4ExtName = "mp4";
  // 设置进度回调间隔,若不设置，SDK默认间隔0.5秒回调一次,单位毫秒
  int progressInterval = 0;
  // 最大播放缓冲大小，单位 MB。此设置会影响playableDuration，设置越大，提前缓存的越多
  int maxBufferSize = 0;
  // 预加载最大缓冲大小，单位：MB
  int maxPreloadSize = 0;
  // 首缓需要加载的数据时长，单位ms，默认值为100ms
  int firstStartPlayBufferTime = 0;
  // 缓冲时（缓冲数据不够引起的二次缓冲，或者seek引起的拖动缓冲）
  // 最少要缓存多长的数据才能结束缓冲，单位ms，默认值为250ms
  int nextStartPlayBufferTime = 0;
  // HLS安全加固加解密key
  String overlayKey = "";
  // HLS安全加固加解密Iv
  String overlayIv = "";
  // 设置一些不必周知的特殊配置
  Map<String, Object> extInfoMap = {};
  // 是否允许加载后渲染后处理服务,默认开启，开启后超分插件如果存在，默认加载
  bool enableRenderProcess = true;
  // 优先播放的分辨率，preferredResolution = width * height
  int preferredResolution =  720 * 1280;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["connectRetryCount"] = connectRetryCount;
    json["connectRetryInterval"] = connectRetryInterval;
    json["timeout"] = timeout;
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
    json["preferredResolution"] = preferredResolution.toString();
    return json;
  }
}

/// 仅iOS平台有效
class PlayerType {
  static const int AVPLAYER = 0; // 系统播放
  static const int THUMB_PLAYER = 1; // ThumbPlayer播放器
}