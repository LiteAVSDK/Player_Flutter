// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// TXLivePlayer config
class FTXLivePlayConfig {

  // The maximum time for automatic adjustment of player cache, in seconds, with a minimum value of 0, default value: 5
  // 播放器缓存自动调整的最大时间，单位秒，取值需要大于0，默认值：5
  double maxAutoAdjustCacheTime = 5.0;

  // The minimum time for automatic adjustment of player cache, in seconds, with a minimum value of 0, default value: 1
  // 播放器缓存自动调整的最小时间，单位秒，取值需要大于0，默认值为1
  double minAutoAdjustCacheTime = 1.0;
  // he number of times the SDK defaults to retry when the player encounters a network disconnection,
  // with a value range of 1-10, default value: 3
  // 播放器遭遇网络连接断开时 SDK 默认重试的次数，取值范围1 - 10，默认值：3。
  int connectRetryCount = 3;

  // The time interval for network reconnection, in seconds, with a value range of 3-30, default value: 3
  // 网络重连的时间间隔，单位秒，取值范围3 - 30，默认值：3。
  int connectRetryInterval = 3;

  // params invalid, it will remove in future version
  @deprecated
  double cacheTime = 5.0;

  // params invalid, it will remove in future version
  @deprecated
  int videoBlockThreshold = 800;

  // params invalid, it will remove in future version
  @deprecated
  bool autoAdjustCacheTime = true;

  // params invalid, it will remove in future version
  @deprecated
  bool enableAec = false;

  // params invalid, it will remove in future version
  @deprecated
  bool enableMessage = true;

  // params invalid, it will remove in future version
  @deprecated
  bool enableMetaData = false;

  // params invalid, it will remove in future version
  @deprecated
  String flvSessionKey = "";

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["maxAutoAdjustCacheTime"] = maxAutoAdjustCacheTime;
    json["minAutoAdjustCacheTime"] = minAutoAdjustCacheTime;
    json["connectRetryCount"] = connectRetryCount;
    json["connectRetryInterval"] = connectRetryInterval;
    return json;
  }

  FTXLivePlayConfigPlayerMsg toMsg() {
    return FTXLivePlayConfigPlayerMsg(
      maxAutoAdjustCacheTime: maxAutoAdjustCacheTime,
      minAutoAdjustCacheTime: minAutoAdjustCacheTime,
      connectRetryCount: connectRetryCount,
      connectRetryInterval: connectRetryInterval,
    );
  }
}
