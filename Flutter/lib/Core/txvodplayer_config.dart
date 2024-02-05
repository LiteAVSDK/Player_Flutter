// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// TXVodPlayer config
class FTXVodPlayConfig {
  // Player reconnection count.
  // 播放器重连次数
  int connectRetryCount = 3;

  // Player reconnection interval.
  // 播放器重连间隔
  int connectRetryInterval = 3;

  // Player connection timeout.
  // 播放器连接超时时间
  int timeout = 10;

  // Effective only on iOS platform [PlayerType].
  // 仅iOS平台生效 [PlayerType]
  int playerType = PlayerType.THUMB_PLAYER;

  // Custom HTTP headers.
  // 自定义http headers
  Map<String, String> headers = {};

  // Whether to perform accurate seek, default true.
  // 是否精确seek，默认true
  bool enableAccurateSeek = true;

  // When playing MP4 files, if set to true, the player will automatically rotate according to the rotation angle in the file,
  // which can be obtained in the PLAY_EVT_CHANGE_ROTATION event. Default true.
  // 播放mp4文件时，若设为true则根据文件中的旋转角度自动旋转。
  // 旋转角度可在PLAY_EVT_CHANGE_ROTATION事件中获得。默认true
  bool autoRotate = true;

  // Smooth switching of multiple bitrates for HLS, default false. When set to false,
  // the speed of opening multiple bitrate addresses can be improved; when set to true,
  // the bitrate can be smoothly switched when IDR is aligned.
  // 平滑切换多码率HLS，默认false。设为false时，可提高多码率地址打开速度;
  // 设为true，在IDR对齐时可平滑切换码率
  bool smoothSwitchBitrate = false;

  // Extension name for caching MP4 files, default mp4.
  // 缓存mp4文件扩展名,默认mp4
  String cacheMp4ExtName = "mp4";

  // Set the progress callback interval. If not set, the SDK will callback every 0.5 seconds by default, in milliseconds.
  // 设置进度回调间隔,若不设置，SDK默认间隔0.5秒回调一次,单位毫秒
  int progressInterval = 0;

  // Maximum playback buffer size, in MB. This setting will affect playableDuration.
  // The larger the setting, the more data will be cached in advance.
  // 最大播放缓冲大小，单位 MB。此设置会影响playableDuration，设置越大，提前缓存的越多
  double maxBufferSize = 10;

  // Maximum preloading buffer size, in MB.
  // 预加载最大缓冲大小，单位：MB
  double maxPreloadSize = 1;

  // Duration of data to be loaded for the first buffering, in milliseconds. The default value is 100ms.
  // 首缓需要加载的数据时长，单位ms，默认值为100ms
  int firstStartPlayBufferTime = 0;

  // During buffering (secondary buffering caused by insufficient buffered data or dragging buffering caused by seek),
  // how much data needs to be cached at least to end buffering, in milliseconds. The default value is 250ms.
  // 缓冲时（缓冲数据不够引起的二次缓冲，或者seek引起的拖动缓冲）
  // 最少要缓存多长的数据才能结束缓冲，单位ms，默认值为250ms
  int nextStartPlayBufferTime = 0;

  // HLS security reinforcement and decryption key.
  // HLS安全加固加解密key
  String overlayKey = "";

  // HLS security reinforcement and decryption IV.
  // HLS安全加固加解密Iv
  String overlayIv = "";

  // Set some special configurations that are not widely known.
  // 设置一些不必周知的特殊配置
  Map<String, Object> extInfoMap = {};

  // Whether to allow loading and rendering post-processing services, default is enabled,
  // and if super-resolution plug-ins exist, they will be loaded by default.
  // 是否允许加载后渲染后处理服务,默认开启，开启后超分插件如果存在，默认加载
  bool enableRenderProcess = true;

  // Preferred resolution for playback, preferredResolution = width * height.
  // 优先播放的分辨率，preferredResolution = width * height
  int preferredResolution = 720 * 1280;

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

  FTXVodPlayConfigPlayerMsg toMsg() {
    return FTXVodPlayConfigPlayerMsg(
      connectRetryCount: connectRetryCount,
      connectRetryInterval: connectRetryInterval,
      timeout: timeout,
      playerType: playerType,
      headers: headers,
      enableAccurateSeek: enableAccurateSeek,
      autoRotate: autoRotate,
      smoothSwitchBitrate: smoothSwitchBitrate,
      cacheMp4ExtName: cacheMp4ExtName,
      progressInterval: progressInterval,
      maxBufferSize: maxBufferSize,
      maxPreloadSize: maxPreloadSize,
      firstStartPlayBufferTime: firstStartPlayBufferTime,
      nextStartPlayBufferTime: nextStartPlayBufferTime,
      overlayKey: overlayKey,
      overlayIv: overlayIv,
      extInfoMap: extInfoMap,
      enableRenderProcess: enableRenderProcess,
      preferredResolution: preferredResolution,
    );
  }
}

/// Effective only on iOS platform.
///
/// 仅iOS平台有效
class PlayerType {
  // System player.
  // 系统播放器
  static const int AVPLAYER = 0;
  // ThumbPlayer player.
  // ThumbPlayer播放器
  static const int THUMB_PLAYER = 1;
}
