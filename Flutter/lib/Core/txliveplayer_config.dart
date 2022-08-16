// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// TXLivePlayer config
class FTXLivePlayConfig {
  // 播放器缓存时间，单位秒，取值需要大于0，默认值：5
  double cacheTime = 5.0;
  // 播放器缓存自动调整的最大时间，单位秒，取值需要大于0，默认值：5
  double maxAutoAdjustCacheTime = 5.0;
  // 播放器缓存自动调整的最小时间，单位秒，取值需要大于0，默认值为1
  double minAutoAdjustCacheTime = 1.0;
  // 播放器视频卡顿报警阈值，单位毫秒,只有渲染间隔超过这个阈值的卡顿才会有 PLAY_WARNING_VIDEO_PLAY_LAG 通知
  int videoBlockThreshold = 800;
  // 播放器遭遇网络连接断开时 SDK 默认重试的次数，取值范围1 - 10，默认值：3。
  int connectRetryCount = 3;
  // 网络重连的时间间隔，单位秒，取值范围3 - 30，默认值：3。
  int connectRetryInterval = 3;
  // 是否自动调整播放器缓存时间，默认值：true
  // true：启用自动调整，自动调整的最大值和最小值可以分别通过修改 maxCacheTime 和 minCacheTime 来设置
  // false：关闭自动调整，采用默认的指定缓存时间(1s)，可以通过修改 cacheTime 来调整缓存时间
  bool autoAdjustCacheTime = true;
  // 是否开启回声消除， 默认值为 false
  bool enableAec = false;
  // 是否开启消息通道， 默认值为 true
  bool enableMessage = true;
  // 是否开启 MetaData 数据回调，默认值为 NO。
  // true：SDK 通过 EVT_PLAY_GET_METADATA 消息抛出视频流的 MetaData 数据；
  // false：SDK 不抛出视频流的 MetaData 数据。
  // 标准直播流都会在最开始的阶段有一个 MetaData 数据头，该数据头支持定制。
  // 您可以通过 TXLivePushConfig 中的 metaData 属性设置一些自定义数据，再通过 TXLivePlayListener 中的
  // onPlayEvent(EVT_PLAY_GET_METADATA) 消息接收到这些数据。
  //【特别说明】每条音视频流中只能设置一个 MetaData 数据头，除非断网重连，否则 TXLivePlayer 的
  // EVT_PLAY_GET_METADATA 消息也只会收到一次。
  bool enableMetaData = false;
  // 是否开启 HTTP 头信息回调，默认值为 “”
  // HTTP
  // 响应头中除了“content-length”、“content-type”等标准字段，不同云服务商还可能会添加一些非标准字段。
  // 比如腾讯云会在直播 CDN 的 HTTP-FLV 格式的直播流中增加 “X-Tlive-SpanId”
  // 响应头，并在其中设置一个随机字符串，用来唯一标识一次直播。
  //
  // 如果您在使用腾讯云的直播 CDN，可以设置 flvSessionKey 为 “X-Tlive-SpanId”，SDK 会在 HTTP
  // 响应头里解析这个字段， 并通过 TXLivePlayListener 中的 onPlayEvent(EVT_PLAY_GET_FLVSESSIONKEY)
  // 事件通知给您的 App。
  //
  //【特别说明】每条音视频流中只能解析一个 flvSessionKey，除非断网重连，否则
  // EVT_PLAY_GET_FLVSESSIONKEY 只会抛送一次。
  String flvSessionKey = "";

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["cacheTime"] = cacheTime;
    json["maxAutoAdjustCacheTime"] = maxAutoAdjustCacheTime;
    json["minAutoAdjustCacheTime"] = minAutoAdjustCacheTime;
    json["videoBlockThreshold"] = videoBlockThreshold;
    json["connectRetryCount"] = connectRetryCount;
    json["connectRetryInterval"] = connectRetryInterval;
    json["autoAdjustCacheTime"] = autoAdjustCacheTime;
    json["enableAec"] = enableAec;
    json["enableMessage"] = enableMessage;
    json["enableMetaData"] = enableMetaData;
    json["flvSessionKey"] = flvSessionKey;
    return json;
  }
}