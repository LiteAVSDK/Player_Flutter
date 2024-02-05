// Copyright (c) 2022 Tencent. All rights reserved.
// import 'package:pigeon/pigeon.dart';
// import 'package:super_player/super_player.dart';
/// Pigeon original component, used to generate native communication code for `messages`.
/// The generation command is as follows. When using the generation command,
/// the two import statements above need to be implemented or commented out.
///
/// pigeon原始原件，由此文件生成messages原生通信代码
/// 生成命令如下，使用生成命令的时候，需要实现注释掉以上两个import导入
/*
    flutter pub run pigeon \
    --input lib/Core/pigeons/txplayer_message.dart \
    --dart_out lib/Core/txplayer_messages.dart \
    --objc_header_out ios/Classes/messages/FtxMessages.h \
    --objc_source_out ios/Classes/messages/FtxMessages.m \
    --java_out ./android/src/main/java/com/tencent/vod/flutter/messages/FtxMessages.java \
    --java_package "com.tencent.vod.flutter.messages" \
    --copyright_header lib/Core/pigeons/txplayer_copy_right.dart
 */
class PlayerMsg {
  int? playerId;
}

class LicenseMsg {
  String? licenseUrl;
  String? licenseKey;
}

class TXPlayInfoParamsPlayerMsg {
  int? playerId;
  int? appId;
  String? fileId;
  String? psign;
  String? url;
}

class PipParamsPlayerMsg {
  int? playerId;
  String? backIconForAndroid;
  String? playIconForAndroid;
  String? pauseIconForAndroid;
  String? forwardIconForAndroid;
}

class StringListPlayerMsg {
  int? playerId;
  String? vvtUrl;
  List<String?>? imageUrls;
}

class BoolPlayerMsg {
  int? playerId;
  bool? value;
}

class StringIntPlayerMsg {
  int? playerId;
  String? strValue;
  int? intValue;
}

class StringPlayerMsg {
  int? playerId;
  String? value;
}

class DoublePlayerMsg {
  int? playerId;
  double? value;
}

class IntPlayerMsg {
  int? playerId;
  int? value;
}

class FTXVodPlayConfigPlayerMsg {
  int? playerId;

  // 播放器重连次数
  int? connectRetryCount;

  // 播放器重连间隔
  int? connectRetryInterval;

  // 播放器连接超时时间
  int? timeout;

  // 仅iOS平台生效 [PlayerType]
  int? playerType;

  // 自定义http headers
  Map<String?, String?>? headers;

  // 是否精确seek，默认true
  bool? enableAccurateSeek;

  // 播放mp4文件时，若设为true则根据文件中的旋转角度自动旋转。
  // 旋转角度可在PLAY_EVT_CHANGE_ROTATION事件中获得。默认true
  bool? autoRotate;

  // 平滑切换多码率HLS，默认false。设为false时，可提高多码率地址打开速度;
  // 设为true，在IDR对齐时可平滑切换码率
  bool? smoothSwitchBitrate;

  // 缓存mp4文件扩展名,默认mp4
  String? cacheMp4ExtName;

  // 设置进度回调间隔,若不设置，SDK默认间隔0.5秒回调一次,单位毫秒
  int? progressInterval;

  // 最大播放缓冲大小，单位 MB。此设置会影响playableDuration，设置越大，提前缓存的越多
  double? maxBufferSize;

  // 预加载最大缓冲大小，单位：MB
  double? maxPreloadSize;

  // 首缓需要加载的数据时长，单位ms，默认值为100ms
  int? firstStartPlayBufferTime;

  // 缓冲时（缓冲数据不够引起的二次缓冲，或者seek引起的拖动缓冲）
  // 最少要缓存多长的数据才能结束缓冲，单位ms，默认值为250ms
  int? nextStartPlayBufferTime;

  // HLS安全加固加解密key
  String? overlayKey;

  // HLS安全加固加解密Iv
  String? overlayIv;

  // 设置一些不必周知的特殊配置
  Map<String?, Object?>? extInfoMap;

  // 是否允许加载后渲染后处理服务,默认开启，开启后超分插件如果存在，默认加载
  bool? enableRenderProcess;

  // 优先播放的分辨率，preferredResolution = width * height
  int? preferredResolution;
}

class FTXLivePlayConfigPlayerMsg {
  int? playerId;

  // 播放器缓存时间，单位秒，取值需要大于0，默认值：5
  double? cacheTime;

  // 播放器缓存自动调整的最大时间，单位秒，取值需要大于0，默认值：5
  double? maxAutoAdjustCacheTime;

  // 播放器缓存自动调整的最小时间，单位秒，取值需要大于0，默认值为1
  double? minAutoAdjustCacheTime;

  // 播放器视频卡顿报警阈值，单位毫秒,只有渲染间隔超过这个阈值的卡顿才会有 PLAY_WARNING_VIDEO_PLAY_LAG 通知
  int? videoBlockThreshold;

  // 播放器遭遇网络连接断开时 SDK 默认重试的次数，取值范围1 - 10，默认值：3。
  int? connectRetryCount;

  // 网络重连的时间间隔，单位秒，取值范围3 - 30，默认值：3。
  int? connectRetryInterval;

  // 是否自动调整播放器缓存时间，默认值：true
  // true：启用自动调整，自动调整的最大值和最小值可以分别通过修改 maxCacheTime 和 minCacheTime 来设置
  // false：关闭自动调整，采用默认的指定缓存时间(1s)，可以通过修改 cacheTime 来调整缓存时间
  bool? autoAdjustCacheTime;

  // 是否开启回声消除， 默认值为 false
  bool? enableAec;

  // 是否开启消息通道， 默认值为 true
  bool? enableMessage;

  // 是否开启 MetaData 数据回调，默认值为 NO。
  // true：SDK 通过 EVT_PLAY_GET_METADATA 消息抛出视频流的 MetaData 数据；
  // false：SDK 不抛出视频流的 MetaData 数据。
  // 标准直播流都会在最开始的阶段有一个 MetaData 数据头，该数据头支持定制。
  // 您可以通过 TXLivePushConfig 中的 metaData 属性设置一些自定义数据，再通过 TXLivePlayListener 中的
  // onPlayEvent(EVT_PLAY_GET_METADATA) 消息接收到这些数据。
  //【特别说明】每条音视频流中只能设置一个 MetaData 数据头，除非断网重连，否则 TXLivePlayer 的
  // EVT_PLAY_GET_METADATA 消息也只会收到一次。
  bool? enableMetaData;

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
  String? flvSessionKey;
}

class TXVodDownloadMediaMsg {
  /// 缓存地址
  String? playPath;
  /// 下载进度
  double? progress;
  /// 下载状态
  int? downloadState;
  /// 账户名称,用于url下载设置账户名称
  String? userName;
  /// 总时长
  int? duration;
  /// 已下载的可播放时长
  int? playableDuration;
  /// 文件总大小，单位：byte
  int? size;
  /// 已下载大小，单位：byte
  int? downloadSize;
  /// 需要下载的视频url，url下载必填
  /// <h1>
  /// url下载不支持嵌套m3u8和mp4下载
  /// </h1>
  String? url;
  /// 下载文件对应的appId，fileId下载必填
  int? appId;
  /// 下载文件Id，fileId下载必填
  String? fileId;
  /// 加密签名，加密视频必填
  String? pSign;
  /// 清晰度ID
  int? quality;
  /// 加密token
  String? token;
  /// 下载速度，单位：KByte/秒
  int? speed;
  /// 资源是否已损坏, 如：资源被删除了
  bool? isResourceBroken;
}

class TXDownloadListMsg {
  List<TXVodDownloadMediaMsg?>? infoList;
}

class UInt8ListMsg {
  Uint8List? value;
}

class ListMsg {
  List? value;
}

class BoolMsg {
  bool? value;
}

class IntMsg {
  int? value;
}

class StringMsg {
  String? value;
}

class DoubleMsg {
  double? value;
}

class PreLoadMsg {
  String? playUrl;
  double? preloadSizeMB;
  int? preferredResolution;
}

class PreLoadInfoMsg {
  int? appId;
  String? fileId;
  String? pSign;
  String? playUrl;
  double? preloadSizeMB;
  int? preferredResolution;
  int? tmpPreloadTaskId;
}

class MapMsg {
  Map<String?, String?>? map;
}

@HostApi()
abstract class TXFlutterSuperPlayerPluginAPI {
  StringMsg getPlatformVersion();

  /// 创建点播播放器
  PlayerMsg createVodPlayer();

  /// 创建直播播放器
  PlayerMsg createLivePlayer();

  /// 开关log输出
  void setConsoleEnabled(BoolMsg enabled);

  /// 释放播放器资源
  void releasePlayer(PlayerMsg playerId);

  /// 设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件
  /// @param size 最大缓存大小（单位：MB)
  void setGlobalMaxCacheSize(IntMsg size);

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
  BoolMsg setGlobalCacheFolderPath(StringMsg postfixPath);

  /// 设置全局license
  void setGlobalLicense(LicenseMsg licenseMsg);

  /// 设置log输出级别 [TXLogLevel]
  void setLogLevel(IntMsg logLevel);

  /// 获取依赖Native端的 LiteAVSDK 的版本
  StringMsg getLiteAVSDKVersion();

  ///
  /// 设置 liteav SDK 接入的环境。
  /// 腾讯云在全球各地区部署的环境，按照各地区政策法规要求，需要接入不同地区接入点。
  ///
  /// @param envConfig 需要接入的环境，SDK 默认接入的环境是：默认正式环境。
  /// @return 0：成功；其他：错误
  /// @note 目标市场为中国大陆的客户请不要调用此接口，如果目标市场为海外用户，请通过技术支持联系我们，了解 env_config 的配置方法，以确保 App 遵守 GDPR 标准。
  ///
  IntMsg setGlobalEnv(StringMsg envConfig);

  ///
  /// 开始监听设备旋转方向，开启之后，如果设备自动旋转打开，播放器会自动根据当前设备方向来旋转视频方向。
  /// <h1>该接口目前只适用安卓端，IOS端会自动开启该能力</h1>
  /// 在调用该接口前，请务必向用户告知隐私风险。
  /// 如有需要，请确认是否有获取旋转sensor的权限。
  /// @return true : 开启成功
  ///         false : 开启失败，如开启过早，还未等到上下文初始化、获取sensor失败等原因
  BoolMsg startVideoOrientationService();
}

@HostApi()
abstract class TXFlutterNativeAPI {
  /// 修改当前界面亮度
  void setBrightness(DoubleMsg brightness);

  /// 恢复当前界面亮度
  void restorePageBrightness();

  /// 获得当前界面亮度 0.0 ~ 1.0
  DoubleMsg getBrightness();

  /// 获取系统界面亮度，IOS系统与界面亮度一致，安卓可能会有差异
  DoubleMsg getSysBrightness();

  /// 设置当前系统音量，0.0 ~ 1.0
  void setSystemVolume(DoubleMsg volume);

  /// 获得当前系统音量，范围：0.0 ~ 1.0
  DoubleMsg getSystemVolume();

  /// 释放音频焦点，只用于安卓端
  void abandonAudioFocus();

  /// 请求获得音频焦点，只用于安卓端
  void requestAudioFocus();

  /// 当前设备是否支持画中画模式
  /// @return [TXVodPlayEvent]
  ///  0 可开启画中画模式
  ///  -101  android版本过低
  ///  -102  画中画权限关闭/设备不支持画中画
  ///  -103  当前界面已销毁
  IntMsg isDeviceSupportPip();

  ///
  /// register or unregister system brightness
  ///
  void registerSysBrightness(BoolMsg isRegister);
}

@HostApi()
abstract class TXFlutterVodPlayerApi {
  /// 播放器初始化，创建共享纹理、初始化播放器
  ///
  /// To initialize the player, you would need to create a shared texture and initialize the player.
  /// @param onlyAudio 是否是纯音频模式 if pure audio mode
  IntMsg initialize(BoolPlayerMsg onlyAudio);

  /// 通过url开始播放视频
  /// 10.7版本开始，startPlay变更为startVodPlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  ///
  /// Starting from version 10.7, the method `startPlay` has been changed to `startVodPlay` for playing videos via a URL.
  /// To play videos successfully, it is necessary to set the license by using the method `SuperPlayerPlugin#setGlobalLicense`.
  /// Failure to set the license will result in video playback failure (a black screen).
  /// Live streaming, short video, and video playback licenses can all be used. If you do not have any of the above licenses,
  /// you can apply for a free trial license to play videos normally[Quickly apply for a free trial version Licence]
  /// (https://cloud.tencent.com/act/event/License).Official licenses can be purchased
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).
  /// @param url : 视频播放地址 video playback address
  /// return 是否播放成功 if play successfully
  BoolMsg startVodPlay(StringPlayerMsg url);

  /// 通过fileId播放视频
  /// 10.7版本开始，startPlayWithParams变更为startVodPlayWithParams，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  ///
  /// Starting from version 10.7, the method "startPlayWithParams" has been changed to "startVodPlayWithParams" for playing videos using fileId.
  /// To play the video successfully, you need to set the Licence using "SuperPlayerPlugin#setGlobalLicense" method before playing the video.
  /// If you do not set the Licence, the video will not play (black screen). The Licence for live streaming,
  /// short video, and video playback can all be used. If you have not obtained the Licence, you can apply for a free trial version [here]
  /// (https://cloud.tencent.com/act/event/License) for normal playback. To use the official version, you need to [purchase]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).
  /// @params : see[TXPlayInfoParams]
  /// return 是否播放成功  if play successful
  void startVodPlayWithParams(TXPlayInfoParamsPlayerMsg params);

  /// 设置是否自动播放
  ///
  /// set autoplay
  void setAutoPlay(BoolPlayerMsg isAutoPlay);

  /// 停止播放
  ///
  /// Stop playback
  /// return 是否停止成功 if stop successful
  BoolMsg stop(BoolPlayerMsg isNeedClear);

  /// 视频是否处于正在播放中
  ///
  /// Is the video currently playing
  BoolMsg isPlaying(PlayerMsg playerMsg);

  /// 视频暂停，必须在播放器开始播放的时候调用
  ///
  /// pause video, it must be called when the player starts playing
  void pause(PlayerMsg playerMsg);

  /// 继续播放，在暂停的时候调用
  ///
  /// resume playback, it should be called when the video is paused
  void resume(PlayerMsg playerMsg);

  /// 设置是否静音
  ///
  /// Set whether to mute or not
  void setMute(BoolPlayerMsg mute);

  /// 设置是否循环播放
  ///
  /// Set whether to loop playback or not
  void setLoop(BoolPlayerMsg loop);

  /// 将视频播放进度定位到指定的进度进行播放
  ///
  /// Set the video playback progress to a specific time and start playing.
  /// progress 要定位的视频时间，单位 秒 The video playback time to be located, in seconds
  void seek(DoublePlayerMsg progress);

  /// 设置播放速率，默认速率 1
  ///
  /// Set the playback speed, with a default speed of 1.
  void setRate(DoublePlayerMsg rate);

  /// 获得播放视频解析出来的码率信息
  ///
  /// get the bitrate information extracted from playing a video
  /// return List<Map>
  /// Bitrate：index 码率序号，
  ///         width 码率对应视频宽度，
  ///         height 码率对应视频高度,
  ///         bitrate 码率值
  ///
  /// Bitrate：index:bitrate index，
  ///         width:the video with of this bitrate，
  ///         height:the video height of this bitrate,
  ///         bitrate:bitrate value
  ListMsg getSupportedBitrate(PlayerMsg playerMsg);

  /// 获得当前设置的码率序号
  ///
  /// Get the index of the current bitrate setting
  IntMsg getBitrateIndex(PlayerMsg playerMsg);

  /// 设置码率序号
  ///
  /// Set the index of the bitrate setting.
  void setBitrateIndex(IntPlayerMsg index);

  /// 设置视频播放开始时间，单位 秒
  ///
  /// Set the start time of the video playback, in seconds.
  void setStartTime(DoublePlayerMsg startTime);

  /// 设置视频声音 0~100
  ///
  /// Set the volume of the video, ranging from 0 to 100.
  void setAudioPlayOutVolume(IntPlayerMsg volume);

  /// 请求获得音频焦点
  ///
  /// Request audio focus.
  BoolMsg setRequestAudioFocus(BoolPlayerMsg focus);

  /// 设置播放器配置
  ///
  /// Set player configuration
  /// config @see [FTXVodPlayConfig]
  void setConfig(FTXVodPlayConfigPlayerMsg config);

  /// 获得当前已经播放的时间，单位 秒
  ///
  /// Get the current playback time, in seconds.
  DoubleMsg getCurrentPlaybackTime(PlayerMsg playerMsg);

  /// 获得当前视频已缓存的时间
  ///
  /// Get the current amount of video that has been buffered.
  DoubleMsg getBufferDuration(PlayerMsg playerMsg);

  /// 获得当前视频的可播放时间
  ///
  /// Get the current playable duration of the video.
  DoubleMsg getPlayableDuration(PlayerMsg playerMsg);

  /// 获得当前播放视频的宽度
  ///
  /// Get the width of the currently playing video.
  IntMsg getWidth(PlayerMsg playerMsg);

  /// 获得当前播放视频的高度
  ///
  /// Get the height of the currently playing video.
  IntMsg getHeight(PlayerMsg playerMsg);

  /// 设置播放视频的token
  ///
  /// Set the token for playing the video.
  void setToken(StringPlayerMsg token);

  /// 当前播放的视频是否循环播放
  ///
  /// Is the currently playing video set to loop
  BoolMsg isLoop(PlayerMsg playerMsg);

  /// 开启/关闭硬件编码
  ///
  /// Enable/Disable hardware encoding.
  BoolMsg enableHardwareDecode(BoolPlayerMsg enable);

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  IntMsg enterPictureInPictureMode(PipParamsPlayerMsg pipParamsMsg);

  /// 退出画中画，如果该播放器处于画中画模式
  ///
  /// Exit picture-in-picture mode if the video player is in picture-in-picture mode.
  void exitPictureInPictureMode(PlayerMsg playerMsg);

  void initImageSprite(StringListPlayerMsg spriteInfo);

  UInt8ListMsg getImageSprite(DoublePlayerMsg time);

  /// 获取总时长
  ///
  /// To get the total duration
  DoubleMsg getDuration(PlayerMsg playerMsg);
}

@HostApi()
abstract class TXFlutterLivePlayerApi {
  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  IntMsg initialize(BoolPlayerMsg onlyAudio);

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  /// 10.7版本开始，startPlay变更为startLivePlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  BoolMsg startLivePlay(StringIntPlayerMsg playerMsg);

  /// 停止播放
  /// return 是否停止成功
  BoolMsg stop(BoolPlayerMsg isNeedClear);

  /// 视频是否处于正在播放中
  BoolMsg isPlaying(PlayerMsg playerMsg);

  /// 视频暂停，必须在播放器开始播放的时候调用
  void pause(PlayerMsg playerMsg);

  /// 继续播放，在暂停的时候调用
  void resume(PlayerMsg playerMsg);

  /// 设置直播模式，see TXPlayerLiveMode
  void setLiveMode(IntPlayerMsg mode);

  /// 设置视频声音 0~100
  void setVolume(IntPlayerMsg volume);

  /// 设置是否静音
  void setMute(BoolPlayerMsg mute);

  /// 切换播放流
  IntMsg switchStream(StringPlayerMsg url);

  /// 设置appId
  void setAppID(StringPlayerMsg appId);

  /// 设置播放器配置
  /// config @see [FTXLivePlayConfig]
  void setConfig(FTXLivePlayConfigPlayerMsg config);

  /// 开启/关闭硬件编码
  BoolMsg enableHardwareDecode(BoolPlayerMsg enable);

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，仅适用于android，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  IntMsg enterPictureInPictureMode(PipParamsPlayerMsg pipParamsMsg);

  /// 退出画中画，如果该播放器处于画中画模式
  void exitPictureInPictureMode(PlayerMsg playerMsg);
}

@HostApi()
abstract class TXFlutterDownloadApi {
  /// 启动预下载。
  /// playUrl: 要预下载的url
  /// preloadSizeMB: 预下载的大小（单位：MB）
  /// preferredResolution 期望分辨率，long类型，值为高x宽。可参考如720*1080。不支持多分辨率或不需指定时，传-1。
  /// 返回值：任务ID，可用这个任务ID停止预下载 [stopPreload]
  IntMsg startPreLoad(PreLoadMsg msg);

  void startPreLoadByParams(PreLoadInfoMsg msg);

  /// 停止预下载。
  /// taskId： 任务id
  void stopPreLoad(IntMsg msg);

  /// 开始下载
  /// videoDownloadModel: 下载构造体
  void startDownload(TXVodDownloadMediaMsg msg);

  /// 继续下载，与开始下载接口有区别，该接口会寻找对应的缓存，复用之前的缓存来续点下载，
  /// 而开始下载接口会启动一个全新的下载
  /// videoDownloadModel: 下载构造体
  void resumeDownload(TXVodDownloadMediaMsg msg);

  /// 停止下载
  /// videoDownloadModel: 下载构造体
  void stopDownload(TXVodDownloadMediaMsg msg);

  /// 设置下载请求头
  void setDownloadHeaders(MapMsg headers);

  /// 获取所有视频下载列表
  TXDownloadListMsg getDownloadList();

  /// 获得指定视频的下载信息
  TXVodDownloadMediaMsg getDownloadInfo(TXVodDownloadMediaMsg msg);

  /// 删除下载任务
  BoolMsg deleteDownloadMediaInfo(TXVodDownloadMediaMsg msg);
}
