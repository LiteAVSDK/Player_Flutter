// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerValue {
  final TXPlayerState state;

  TXPlayerValue.uninitialized() : this(state: TXPlayerState.stopped);

  TXPlayerValue({required this.state});

  TXPlayerValue copyWith({TXPlayerState? state}) {
    return TXPlayerValue(state: state ?? this.state);
  }
}

///
/// 直播类型
///
abstract class TXPlayType {
  ///
  /// see: https://cloud.tencent.com/document/product/454/7886
  ///
  static const LIVE_RTMP = 0;
  static const LIVE_FLV = 1;
  static const LIVE_RTMP_ACC = 5;
  static const VOD_HLS = 3;
}

abstract class TXVodPlayEvent {
  static const PLAY_EVT_ERROR_INVALID_LICENSE = -5; // license 不合法，调用失败
  static const PLAY_EVT_CONNECT_SUCC = 2001; // 已经连接服务器
  static const PLAY_EVT_RTMP_STREAM_BEGIN = 2002; // 已经连接服务器，开始拉流（仅播放 RTMP 地址时会抛送）
  static const PLAY_EVT_RCV_FIRST_I_FRAME = 2003; // 收到首帧数据，越快收到此消息说明链路质量越好
  static const PLAY_EVT_PLAY_BEGIN = 2004; // 视频播放开始，如果您自己做 loading，会需要它
  static const PLAY_EVT_PLAY_PROGRESS = 2005; // 视频播放进度
  static const PLAY_EVT_PLAY_END = 2006; // 视频播放结束
  static const PLAY_EVT_PLAY_LOADING = 2007; // 视频播放进入缓冲状态，缓冲结束之后会有 PLAY_BEGIN 事件
  static const PLAY_EVT_START_VIDEO_DECODER = 2008; // 视频解码器开始启动（2.0 版本以后新增)
  static const PLAY_EVT_CHANGE_RESOLUTION = 2009; // 视频分辨率发生变化（分辨率在 EVT_PARAM 参数中）
  static const PLAY_EVT_GET_PLAYINFO_SUCC = 2010; // 如果您在直播中收到此消息，说明错用成了 TXVodPlayer
  static const PLAY_EVT_CHANGE_ROTATION = 2011; // 如果您在直播中收到此消息，说明错用成了 TXVodPlayer
  static const PLAY_EVT_GET_MESSAGE = 2012; // 获取夹在视频流中的自定义 SEI 消息，消息的发送需使用 TXLivePusher
  static const PLAY_EVT_VOD_PLAY_PREPARED = 2013; // 视频加载完毕（点播）
  static const PLAY_EVT_VOD_LOADING_END = 2014; // loading结束（点播）
  static const PLAY_EVT_STREAM_SWITCH_SUCC = 2015; // 直播流切换完成
  static const PLAY_EVT_RENDER_FIRST_FRAME_ON_VIEW = 2033; // View渲染首帧时间
  static const PLAY_ERR_NET_DISCONNECT = -2301; // 网络断连，且经多次重连亦不能恢复，更多重试请自行重启播放
  static const PLAY_ERR_GET_RTMP_ACC_URL_FAIL = -2302; // 获取加速拉流地址失败
  static const PLAY_ERR_FILE_NOT_FOUND = -2303; // 文件不存在
  static const PLAY_ERR_HEVC_DECODE_FAIL = -2304; // h265解码失败
  static const PLAY_ERR_HLS_KEY = -2305; // HLS解密key获取失败
  static const PLAY_ERR_GET_PLAYINFO_FAIL = -2306; // 获取点播文件信息失败
  static const PLAY_ERR_STREAM_SWITCH_FAIL = -2307; // 直播清晰度切换失败
  static const PLAY_WARNING_VIDEO_DECODE_FAIL = 2101; // 当前视频帧解码失败
  static const PLAY_WARNING_AUDIO_DECODE_FAIL = 2102; // 当前音频帧解码失败
  static const PLAY_WARNING_RECONNECT = 2103; // 网络断连，已启动自动重连（重连超过三次就直接抛送 PLAY_ERR_NET_DISCONNECT）
  static const PLAY_WARNING_RECV_DATA_LAG = 2104; // 网络来包不稳：可能是下行带宽不足，或由于主播端出流不均匀
  static const PLAY_WARNING_VIDEO_PLAY_LAG = 2105; // 当前视频播放出现卡顿
  static const PLAY_WARNING_HW_ACCELERATION_FAIL = 2106; // 硬解启动失败，采用软解
  static const PLAY_WARNING_VIDEO_DISCONTINUITY = 2107; // 当前视频帧不连续，可能丢帧
  static const PLAY_WARNING_DNS_FAIL = 3001; // RTMP-DNS 解析失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_SEVER_CONN_FAIL = 3002; // RTMP 服务器连接失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_SHAKE_FAIL = 3003; // RTMP 服务器握手失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_READ_WRITE_FAIL = 3005; // RTMP 读/写失败
  static const PLAY_WARNING_SPEAKER_DEVICE_ABNORMAL = 1205; // 播放设备异常

  static const EVT_UTC_TIME = "EVT_UTC_TIME"; // UTC时间
  static const EVT_BLOCK_DURATION = "EVT_BLOCK_DURATION"; // 卡顿时间
  static const EVT_TIME = "EVT_TIME"; // 事件发生时间
  static const EVT_DESCRIPTION = "EVT_MSG"; // 事件说明
  static const EVT_PARAM1 = "EVT_PARAM1"; // 事件参数1
  static const EVT_PARAM2 = "EVT_PARAM2"; // 事件参数2
  static const EVT_GET_MSG = "EVT_GET_MSG"; // 消息内容，收到PLAY_EVT_GET_MESSAGE事件时，通过该字段获取消息内容
  static const EVT_PLAY_COVER_URL = "EVT_PLAY_COVER_URL"; // 视频封面
  static const EVT_PLAY_URL = "EVT_PLAY_URL"; // 视频地址
  static const EVT_PLAY_NAME = "EVT_PLAY_NAME"; // 视频名称
  static const EVT_PLAY_DESCRIPTION = "EVT_PLAY_DESCRIPTION"; // 视频简介
  static const EVT_PLAY_PROGRESS_MS = "EVT_PLAY_PROGRESS_MS"; // 播放进度（毫秒）
  static const EVT_PLAY_DURATION_MS = "EVT_PLAY_DURATION_MS"; // 播放总长（毫秒）
  static const EVT_PLAY_PROGRESS = "EVT_PLAY_PROGRESS"; // 播放进度
  static const EVT_PLAY_DURATION = "EVT_PLAY_DURATION"; // 播放总长
  static const EVT_PLAYABLE_DURATION_MS = "EVT_PLAYABLE_DURATION_MS"; // 点播可播放时长（毫秒）
  static const EVT_PLAYABLE_RATE = "EVT_PLAYABLE_RATE"; //播放速率
  static const EVT_IMAGESPRIT_WEBVTTURL = "EVT_IMAGESPRIT_WEBVTTURL"; // 雪碧图web vtt描述文件下载URL
  static const EVT_IMAGESPRIT_IMAGEURL_LIST = "EVT_IMAGESPRIT_IMAGEURL_LIST"; // 雪碧图图片下载URL
  static const EVT_DRM_TYPE = "EVT_DRM_TYPE"; // 加密类型

  /// superplayer plugin volume event
  static const EVENT_VOLUME_CHANGED = 1; // 音量变化
  static const EVENT_AUDIO_FOCUS_PAUSE = 2; // 失去音量输出播放焦点 only for android
  static const EVENT_AUDIO_FOCUS_PLAY = 3; // 获得音量输出焦点 only for android
  /// pip event
  static const    EVENT_PIP_MODE_ALREADY_ENTER    = 1; // 已经进入画中画模式
  static const    EVENT_PIP_MODE_ALREADY_EXIT     = 2; // 已经退出画中画模式
  static const    EVENT_PIP_MODE_REQUEST_START    = 3; // 开始请求进入画中画模式
  static const    EVENT_PIP_MODE_UI_STATE_CHANGED = 4; // pip UI状态发生变动，only support android > 31
  static const    EVENT_IOS_PIP_MODE_RESTORE_UI   = 5; // 重置UI only support iOS
  static const    EVENT_IOS_PIP_MODE_WILL_EXIT    = 6; // 将要退出画中画 only support iOS

  static const EVENT_ORIENTATION_CHANGED = 401; // 屏幕发生旋转
  static const EXTRA_NAME_ORIENTATION = "orientation"; // 屏幕旋转方向
  static const ORIENTATION_PORTRAIT_UP = 411; // 竖屏，顶部在上
  static const ORIENTATION_LANDSCAPE_RIGHT = 412; // 横屏，顶部在左，底部在右
  static const ORIENTATION_PORTRAIT_DOWN = 413; // 竖屏，顶部在下
  static const ORIENTATION_LANDSCAPE_LEFT = 414; // 横屏，顶部在右，底部在左

  static const NO_ERROR = 0;
  static const ERROR_PIP_LOWER_VERSION            = -101; // pip 错误，android版本过低
  static const ERROR_PIP_DENIED_PERMISSION        = -102; // pip 错误，画中画权限关闭/设备不支持画中画
  static const ERROR_PIP_ACTIVITY_DESTROYED       = -103; // pip 错误，当前界面已销毁
  static const ERROR_IOS_PIP_DEVICE_NOT_SUPPORT   = -104; // pip 错误，设备或系统版本不支持（iPad iOS9+ 才支持PIP）
  static const ERROR_IOS_PIP_PLAYER_NOT_SUPPORT   = -105; // pip 错误，播放器不支持 only support iOS
  static const ERROR_IOS_PIP_VIDEO_NOT_SUPPORT    = -106; // pip 错误，视频不支持 only support iOS
  static const ERROR_IOS_PIP_IS_NOT_POSSIBLE      = -107; // pip 错误，PIP控制器不可用 only support iOS
  static const ERROR_IOS_PIP_FROM_SYSTEM          = -108; // pip 错误，PIP控制器报错 only support iOS
  static const ERROR_IOS_PIP_PLAYER_NOT_EXIST     = -109; // pip 错误，播放器对象不存在 only support iOS
  static const ERROR_IOS_PIP_IS_RUNNING           = -110; // pip 错误，PIP功能已经运行 only support iOS
  static const ERROR_IOS_PIP_NOT_RUNNING          = -111; // pip 错误，PIP功能没有启动 only support iOS
  static const ERROR_PIP_CAN_NOT_ENTER            = -120; // pip 错误，当前不能进入pip模式，例如正处于全屏模式下

  /// 视频下载相关事件
  static const EVENT_PREDOWNLOAD_ON_COMPLETE = 200;  // 视频预下载完成
  static const EVENT_PREDOWNLOAD_ON_ERROR = 201;  // 视频预下载出错

  static const EVENT_DOWNLOAD_START    = 301; // 视频下载开始
  static const EVENT_DOWNLOAD_PROGRESS = 302; // 视频下载进度
  static const EVENT_DOWNLOAD_STOP     = 303; // 视频下载停止
  static const EVENT_DOWNLOAD_FINISH   = 304; // 视频下载完成
  static const EVENT_DOWNLOAD_ERROR    = 305; // 视频下载错误
}

abstract class TXVodNetEvent {
  static const NET_STATUS_CPU_USAGE = "CPU_USAGE"; // CPU使用率
  static const NET_STATUS_VIDEO_WIDTH = "VIDEO_WIDTH"; // 分辨率之width
  static const NET_STATUS_VIDEO_HEIGHT = "VIDEO_HEIGHT"; // 分辨率之height
  static const NET_STATUS_VIDEO_FPS = "VIDEO_FPS"; // 当前视频帧率,也就是视频编码器每条生产了多少帧画面
  static const NET_STATUS_VIDEO_GOP = "VIDEO_GOP"; // 当前视频GOP,也就是每两个关键帧(I帧)间隔时长，单位s
  static const NET_STATUS_VIDEO_BITRATE = "VIDEO_BITRATE"; // 推流：视频数据发送比特率；拉流：视频数据接收比特率 单位：kbps
  static const NET_STATUS_AUDIO_BITRATE = "AUDIO_BITRATE"; // 推流：音频数据发送比特率；拉流：音频数据接收比特率 单位：kbps
  static const NET_STATUS_NET_SPEED = "NET_SPEED"; // 推流：音视频数据发送总比特率；拉流：音视频数据接收总比特率 单位：kbps
  static const NET_STATUS_AUDIO_CACHE = "AUDIO_CACHE"; // 推流：发送端缓存未发送的音频帧数；拉流：接收端已接收但未播放的音频帧总时长
  static const NET_STATUS_VIDEO_CACHE = "VIDEO_CACHE"; // 推流：发送端缓存未发送的视频帧数；拉流：接收端已接收但未渲染的视频帧总时长
  static const NET_STATUS_AUDIO_DROP = "AUDIO_DROP"; // 推流：发送端音频丢帧数(未用:上行无音频丢帧逻辑)   拉流：接收端音频丢帧数（未用：播放端有音频加速，不丢帧）
  static const NET_STATUS_VIDEO_DROP = "VIDEO_DROP"; // 推流：发送端视频丢帧数(有用:实时推流有丢帧逻辑)   拉流：接收端视频丢帧数（未用：播放端有视频加速，不丢帧）
  static const NET_STATUS_V_SUM_CACHE_SIZE = "V_SUM_CACHE_SIZE"; // 拉流专用：接收端已接收但未渲染的视频帧数（包括JitterBuffer和解码器两部分缓存）
  static const NET_STATUS_V_DEC_CACHE_SIZE = "V_DEC_CACHE_SIZE"; // 拉流专用：接收端解码器里缓存的视频帧数
  static const NET_STATUS_AV_PLAY_INTERVAL =
      "AV_PLAY_INTERVAL"; // 拉流专用：视频当前渲染帧的timestamp和音频当前播放帧的timestamp的差值，标示当时音画同步的状态
  static const NET_STATUS_AV_RECV_INTERVAL =
      "AV_RECV_INTERVAL"; // 拉流专用：jitterbuffer最新收到的视频帧和音频帧的timestamp的差值，标示当时jitterbuffer收包同步的状态
  static const NET_STATUS_AUDIO_CACHE_THRESHOLD =
      "AUDIO_CACHE_THRESHOLD"; // 拉流专用：播放端音频缓存时长阀值，单位：秒，当缓存的音频时长大于该阀值时会触发jitterbuffer的加速播放，以保证播放时延
  static const NET_STATUS_AUDIO_BLOCK_TIME = "AUDIO_BLOCK_TIME"; // 拉流专用：音频卡顿时长，单位ms
  static const NET_STATUS_AUDIO_INFO = "AUDIO_PLAY_INFO"; // 当前流的音频信息，包括采样率信息和声道数信息
  static const NET_STATUS_NET_JITTER = "NET_JITTER"; // 网络抖动情况，数值越大表示抖动越大，网络越不稳定
  static const NET_STATUS_SERVER_IP = "SERVER_IP"; // 连接的Server IP地址
  static const NET_STATUS_VIDEO_DPS = "VIDEO_DPS"; // 当前解码器输出帧率（点播）
  static const NET_STATUS_QUALITY_LEVEL = "NET_QUALITY_LEVEL"; // 网络质量：0：未定义 1：最好 2：好 3：一般 4：差 5：很差 6：不可用
}

enum TXPlayerLiveMode {
  Automatic, // 自动模式
  Speed, // 极速模式
  Smooth // 流畅模式
}

enum TXPlayerState {
  paused, // 暂停播放
  failed, // 播放失败
  buffering, // 缓冲中
  playing, // 播放中
  stopped, // 停止播放
  disposed // 控件释放了
}

enum TXPlayerEvent {
  reconnect, // 网络中断，自动重连中
  disconnect, // 网络中断，重连失败
  dnsFail, // RTMP-DNS 解析失败
  severConnFail, // RTMP 服务器连接失败
  shakeFail, // RTMP 服务器握手失败
  progress // 进度
}

class TXLogLevel {
  static const LOG_LEVEL_VERBOSE = 0; // 输出所有级别的log
  static const LOG_LEVEL_DEBUG = 1; // 输出 DEBUG,INFO,WARNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_INFO = 2; // 输出 INFO,WARNNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_WARN = 3; // 输出WARNNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_ERROR = 4; // 输出ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_FATAL = 5; // 只输出FATAL 级别的log
  static const LOG_LEVEL_NULL = 6; // 不输出任何sdk log
}

class DownloadQuality {
  static const QUALITY_OD = 0;
  static const QUALITY_FLU = 1;
  static const QUALITY_SD = 2;
  static const QUALITY_HD = 3;
  static const QUALITY_FHD = 4;
  static const QUALITY_2K = 5;
  static const QUALITY_4K = 6;
  static const QUALITY_UNK = 1000;
}

class TXPlayInfoParams {
  final int appId; // Tencent Cloud video appId, required
  final String fileId; // Tencent Cloud video fileId, required
  final String? psign; // encent cloud video encryption signature, required for encrypted video

  const TXPlayInfoParams({required this.appId, required this.fileId, this.psign});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["appId"] = appId;
    json["fileId"] = fileId;
    json["psign"] = psign;
    return json;
  }
}


/// fileId存储
class TXVodDownloadDataSource {
  /// 下载文件对应的appId，fileId下载必填
  int? appId;
  /// 下载文件Id，fileId下载必填
  String? fileId;
  /// 加密签名，加密视频必填
  String? pSign;
  /// 清晰度ID,fileId下载必传，通过[CommonUtils.getDownloadQualityBySize]进行转换
  int? quality;
  /// 加密token
  String? token;
  /// 账户名称,用于url下载设置账户名称
  String? userName;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["appId"] = appId;
    json["fileId"] = fileId;
    json["pSign"] = pSign;
    json["quality"] = quality;
    json["token"] = token;
    json["userName"] = userName;
    return json;
  }
}

/// 视频下载信息
class TXVodDownloadMedialnfo {
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
  /// fileId 存储
  TXVodDownloadDataSource? dataSource;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["url"] = url;
    json["downloadState"] = downloadState;
    json["progress"] = progress;
    json["playPath"] = playPath;
    json["userName"] = userName;
    json["duration"] = duration;
    json["playableDuration"] = playableDuration;
    json["size"] = size;
    json["downloadSize"] = downloadSize;
    if(null != dataSource) {
      json.addAll(dataSource!.toJson());
    }
    return json;
  }
}

//视频预下载事件回调Listener
typedef FTXPredownlodOnCompleteListener = void Function(int taskId, String url);
typedef FTXPredownlodOnErrorListener = void Function(int taskId, String url, int code, String msg);
// 视频下载时间回调Listener
typedef FTXDownlodOnStateChangeListener = void Function(int event, TXVodDownloadMedialnfo info);
typedef FTXDownlodOnErrorListener = void Function(int errorCode, String errorMsg,TXVodDownloadMedialnfo info);

