// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerValue {
  final TXPlayerState state;

  // The rotation angle of the current video texture.
  final int degree;

  TXPlayerValue.uninitialized() : this();

  TXPlayerValue({
    this.state = TXPlayerState.stopped,
    this.degree = 0,
  });

  TXPlayerValue copyWith({
    TXPlayerState? state,
    int? degree,
  }) {
    return TXPlayerValue(state: state ?? this.state, degree: degree ?? this.degree);
  }
}

///
/// Live stream type.
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
  // Invalid license, call failed.
  // license 不合法，调用失败
  static const PLAY_EVT_ERROR_INVALID_LICENSE = -5;
  // Connected to server.
  // 已经连接服务器
  static const PLAY_EVT_CONNECT_SUCC = 2001;
  // Connected to server, start pulling stream (only for playing RTMP address).
  // 已经连接服务器，开始拉流（仅播放 RTMP 地址时会抛送）
  static const PLAY_EVT_RTMP_STREAM_BEGIN = 2002;
  // Received the first frame of data, the faster you receive this message, the better the link quality.
  // 收到首帧数据，越快收到此消息说明链路质量越好
  static const PLAY_EVT_RCV_FIRST_I_FRAME = 2003;
  // Video playback starts, if you make your own loading, you will need it.
  // 视频播放开始，如果您自己做 loading，会需要它
  static const PLAY_EVT_PLAY_BEGIN = 2004;
  // Video playback progress.
  // 视频播放进度
  static const PLAY_EVT_PLAY_PROGRESS = 2005;
  // Video playback ends.
  // 视频播放结束
  static const PLAY_EVT_PLAY_END = 2006;
  // Video playback enters buffering state, and there will be a PLAY_BEGIN event after buffering ends.
  // 视频播放进入缓冲状态，缓冲结束之后会有 PLAY_BEGIN 事件
  static const PLAY_EVT_PLAY_LOADING = 2007;
  // Video decoder starts to work (added after version 2.0).
  // 视频解码器开始启动（2.0 版本以后新增)
  static const PLAY_EVT_START_VIDEO_DECODER = 2008;
  // Video resolution changes (resolution is in the EVT_PARAM parameter).
  // 视频分辨率发生变化（分辨率在 EVT_PARAM 参数中）
  static const PLAY_EVT_CHANGE_RESOLUTION = 2009;
  // If you receive this message during live streaming, it means that you have used TXVodPlayer incorrectly.
  // 如果您在直播中收到此消息，说明错用成了 TXVodPlayer
  static const PLAY_EVT_GET_PLAYINFO_SUCC = 2010;
  // Get custom SEI message embedded in video stream, message sending needs to use TXLivePusher.
  // 如果您在直播中收到此消息，说明错用成了 TXVodPlayer
  static const PLAY_EVT_CHANGE_ROTATION = 2011;
  // Get custom SEI message embedded in video stream, message sending needs to use TXLivePusher.
  // 如果您在直播中收到此消息，说明错用成了 TXVodPlayer
  static const PLAY_EVT_GET_MESSAGE = 2012;
  // Video loading completed (VOD).
  // 视频加载完毕（点播）
  static const PLAY_EVT_VOD_PLAY_PREPARED = 2013;
  // Loading ends (VOD).
  // loading结束（点播）
  static const PLAY_EVT_VOD_LOADING_END = 2014;
  // Live streaming switch completed.
  // 直播流切换完成
  static const PLAY_EVT_STREAM_SWITCH_SUCC = 2015;
  // View rendering first frame time.
  // View渲染首帧时间
  static const PLAY_EVT_RENDER_FIRST_FRAME_ON_VIEW = 2033;
  // Network disconnected and cannot be restored after multiple reconnections.
  // Please restart the playback by yourself if you want to try again.
  // 网络断连，且经多次重连亦不能恢复，更多重试请自行重启播放
  static const PLAY_ERR_NET_DISCONNECT = -2301;
  // Failed to get accelerated streaming address.
  // 获取加速拉流地址失败
  static const PLAY_ERR_GET_RTMP_ACC_URL_FAIL = -2302;
  // File does not exist.
  // 文件不存在
  static const PLAY_ERR_FILE_NOT_FOUND = -2303;
  // H.265 decoding failed.
  // h265解码失败
  static const PLAY_ERR_HEVC_DECODE_FAIL = -2304;
  // Failed to obtain HLS decryption key.
  // HLS解密key获取失败
  static const PLAY_ERR_HLS_KEY = -2305;
  // Failed to get VOD file information.
  // 获取点播文件信息失败
  static const PLAY_ERR_GET_PLAYINFO_FAIL = -2306;
  // Live streaming quality switch failed.
  // 直播清晰度切换失败
  static const PLAY_ERR_STREAM_SWITCH_FAIL = -2307;
  // Current video frame decoding failed.
  // 当前视频帧解码失败
  static const PLAY_WARNING_VIDEO_DECODE_FAIL = 2101;
  // Current audio frame decoding failed.
  // 当前音频帧解码失败
  static const PLAY_WARNING_AUDIO_DECODE_FAIL = 2102;
  // Network disconnected, and automatic reconnection has been started
  // (if reconnection exceeds three times, PLAY_ERR_NET_DISCONNECT will be thrown directly).
  // 网络断连，已启动自动重连（重连超过三次就直接抛送 PLAY_ERR_NET_DISCONNECT）
  static const PLAY_WARNING_RECONNECT = 2103;
  // Network packet is unstable: it may be due to insufficient downstream bandwidth, or uneven flow from the anchor end.
  // 网络来包不稳：可能是下行带宽不足，或由于主播端出流不均匀
  static const PLAY_WARNING_RECV_DATA_LAG = 2104;
  // Current video playback is stuck.
  // 当前视频播放出现卡顿
  static const PLAY_WARNING_VIDEO_PLAY_LAG = 2105;
  // Hardware decoding failed, using software decoding.
  // 硬解启动失败，采用软解
  static const PLAY_WARNING_HW_ACCELERATION_FAIL = 2106;
  // Current video frame is not continuous, may have dropped frames.
  // 当前视频帧不连续，可能丢帧
  static const PLAY_WARNING_VIDEO_DISCONTINUITY = 2107;
  // RTMP-DNS resolution failed (only for playing RTMP address).
  // RTMP-DNS 解析失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_DNS_FAIL = 3001;
  // RTMP server connection failed (only for playing RTMP address).
  // RTMP 服务器连接失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_SEVER_CONN_FAIL = 3002;
  // RTMP server handshake failed (only for playing RTMP address).
  // RTMP 服务器握手失败（仅播放 RTMP 地址时会抛送）
  static const PLAY_WARNING_SHAKE_FAIL = 3003;
  // RTMP read/write failed.
  // RTMP 读/写失败
  static const PLAY_WARNING_READ_WRITE_FAIL = 3005;
  // Playback device exception.
  // 播放设备异常
  static const PLAY_WARNING_SPEAKER_DEVICE_ABNORMAL = 1205;
  // Seek completed.
  // Seek 完成
  static const VOD_PLAY_EVT_SEEK_COMPLETE = 2019;

  // UTC time
  // UTC时间
  static const EVT_UTC_TIME = "EVT_UTC_TIME";
  // Stuttering time.
  // 卡顿时间
  static const EVT_BLOCK_DURATION = "EVT_BLOCK_DURATION";
  // Event occurrence time.
  // 事件发生时间
  static const EVT_TIME = "EVT_TIME";
  // Event description.
  // 事件说明
  static const EVT_DESCRIPTION = "EVT_MSG";
  // Event parameter 1.
  // 事件参数1
  static const EVT_PARAM1 = "EVT_PARAM1";
  // Event parameter 2.
  // 事件参数2
  static const EVT_PARAM2 = "EVT_PARAM2";
  // Width of resolution.
  // 分辨率之width
  static const EVT_VIDEO_WIDTH = "EVT_WIDTH";
  // Height of resolution.
  // 分辨率之height
  static const EVT_VIDEO_HEIGHT = "EVT_HEIGHT";
  // Message content, use this field to get the message content when receiving PLAY_EVT_GET_MESSAGE event.
  // 消息内容，收到PLAY_EVT_GET_MESSAGE事件时，通过该字段获取消息内容s
  static const EVT_GET_MSG = "EVT_GET_MSG";
  // Video cover
  // 视频封面
  static const EVT_PLAY_COVER_URL = "EVT_PLAY_COVER_URL";
  // Video address.
  // 视频地址
  static const EVT_PLAY_URL = "EVT_PLAY_URL";
  // Video name.
  // 视频名称
  static const EVT_PLAY_NAME = "EVT_PLAY_NAME";
  // Video introduction.
  // 视频简介
  static const EVT_PLAY_DESCRIPTION = "EVT_PLAY_DESCRIPTION";
  // Playback progress (in milliseconds).
  // 播放进度（毫秒）
  static const EVT_PLAY_PROGRESS_MS = "EVT_PLAY_PROGRESS_MS";
  // Total playback time (in milliseconds).
  // 播放总长（毫秒）
  static const EVT_PLAY_DURATION_MS = "EVT_PLAY_DURATION_MS";
  // Playback progress.
  // 播放进度
  static const EVT_PLAY_PROGRESS = "EVT_PLAY_PROGRESS";
  // Total playback time
  // 播放总长
  static const EVT_PLAY_DURATION = "EVT_PLAY_DURATION";
  // Playable duration of VOD (in milliseconds).
  // 点播可播放时长（毫秒）
  static const EVT_PLAYABLE_DURATION_MS = "EVT_PLAYABLE_DURATION_MS";
  // Playback rate.
  // 播放速率
  static const EVT_PLAYABLE_RATE = "EVT_PLAYABLE_RATE";
  // Web VTT description file download URL of sprite map.
  // 雪碧图web vtt描述文件下载URL
  static const EVT_IMAGESPRIT_WEBVTTURL = "EVT_IMAGESPRIT_WEBVTTURL";
  // Download URL of sprite map image.
  // 雪碧图图片下载URL
  static const EVT_IMAGESPRIT_IMAGEURL_LIST = "EVT_IMAGESPRIT_IMAGEURL_LIST";
  // Encryption type.
  // 加密类型
  static const EVT_DRM_TYPE = "EVT_DRM_TYPE";

  /// superplayer plugin event
  // Volume change
  // 音量变化
  static const EVENT_VOLUME_CHANGED = 1;
  // Loss of volume output playback focus (only for Android).
  // 失去音量输出播放焦点 only for android
  static const EVENT_AUDIO_FOCUS_PAUSE = 2;
  // Gain of volume output focus (only for Android).
  // 获得音量输出焦点 only for android
  static const EVENT_AUDIO_FOCUS_PLAY = 3;
  // Brightness change.
  // 亮度发生变化
  static const EVENT_BRIGHTNESS_CHANGED = 4;
  /// pip event
  // Entered picture-in-picture mode.
  // 已经进入画中画模式
  static const EVENT_PIP_MODE_ALREADY_ENTER = 1;
  // Exited picture-in-picture mode.
  // 已经退出画中画模式
  static const EVENT_PIP_MODE_ALREADY_EXIT = 2;
  // Start requesting to enter picture-in-picture mode.
  // 开始请求进入画中画模式
  static const EVENT_PIP_MODE_REQUEST_START = 3;
  // PIP UI status changed (only support Android > 31).
  // pip UI状态发生变动，only support android > 31
  static const EVENT_PIP_MODE_UI_STATE_CHANGED = 4;
  // Reset UI (only support iOS).
  // 重置UI only support iOS
  static const EVENT_IOS_PIP_MODE_RESTORE_UI = 5;
  // Will exit picture-in-picture mode (only support iOS).
  // 将要退出画中画 only support iOS
  static const EVENT_IOS_PIP_MODE_WILL_EXIT = 6;

  // Screen rotation.
  // 屏幕发生旋转
  static const EVENT_ORIENTATION_CHANGED = 401;
  // Screen rotation direction.
  // 屏幕旋转方向
  static const EXTRA_NAME_ORIENTATION = "orientation";
  // Portrait, top on top.
  // 竖屏，顶部在上
  static const ORIENTATION_PORTRAIT_UP = 411;
  // Landscape, top on left, bottom on right.
  // 横屏，顶部在左，底部在右
  static const ORIENTATION_LANDSCAPE_RIGHT = 412;
  // Portrait, top on bottom.
  // 竖屏，顶部在下
  static const ORIENTATION_PORTRAIT_DOWN = 413;
  // Landscape, top on right, bottom on left.
  // 横屏，顶部在右，底部在左
  static const ORIENTATION_LANDSCAPE_LEFT = 414;

  static const NO_ERROR = 0;
  // PIP error, Android version is too low.
  // pip 错误，android版本过低
  static const ERROR_PIP_LOWER_VERSION = -101;
  // PIP error, picture-in-picture permission is turned off/device does not support picture-in-picture.
  // pip 错误，画中画权限关闭/设备不支持画中画
  static const ERROR_PIP_DENIED_PERMISSION = -102;
  // PIP error, current interface has been destroyed.
  // pip 错误，当前界面已销毁
  static const ERROR_PIP_ACTIVITY_DESTROYED = -103;
  // PIP error, device or system version not supported (PIP is only supported on iPad iOS9+)
  // pip 错误，设备或系统版本不支持（iPad iOS9+ 才支持PIP）
  static const ERROR_IOS_PIP_DEVICE_NOT_SUPPORT = -104;
  // PIP error, player does not support (only support iOS).
  // pip 错误，播放器不支持 only support iOS
  static const ERROR_IOS_PIP_PLAYER_NOT_SUPPORT = -105;
  // PIP error, video does not support (only support iOS).
  // pip 错误，视频不支持 only support iOS
  static const ERROR_IOS_PIP_VIDEO_NOT_SUPPORT = -106;
  // PIP error, PIP controller is not available (only support iOS).
  // pip 错误，PIP控制器不可用 only support iOS
  static const ERROR_IOS_PIP_IS_NOT_POSSIBLE = -107;
  // PIP error, PIP controller error (only support iOS).
  // pip 错误，PIP控制器报错 only support iOS
  static const ERROR_IOS_PIP_FROM_SYSTEM = -108;
  // PIP error, player object does not exist (only support iOS).
  // pip 错误，播放器对象不存在 only support iOS
  static const ERROR_IOS_PIP_PLAYER_NOT_EXIST = -109;
  // PIP error, PIP function is already running (only support iOS).
  // pip 错误，PIP功能已经运行 only support iOS
  static const ERROR_IOS_PIP_IS_RUNNING = -110;
  // PIP error, PIP function is not started (only support iOS).
  // pip 错误，PIP功能没有启动 only support iOS
  static const ERROR_IOS_PIP_NOT_RUNNING = -111;
  // PIP error, currently unable to enter PIP mode, such as being in full screen mode.
  // pip 错误，当前不能进入pip模式，例如正处于全屏模式下
  static const ERROR_PIP_CAN_NOT_ENTER = -120;

  /// Video download related events.
  /// 视频下载相关事件
  // Video pre-download completed.
  // 视频预下载完成
  static const EVENT_PREDOWNLOAD_ON_COMPLETE = 200;
  // Error occurred during video pre-download.
  // 视频预下载出错
  static const EVENT_PREDOWNLOAD_ON_ERROR = 201;
  // fileId preload is start, callback url、taskId and other video info
  static const EVENT_PREDOWNLOAD_ON_START = 202;

  // Video download started.
  // 视频下载开始
  static const EVENT_DOWNLOAD_START = 301;
  // Video download progress.
  // 视频下载进度
  static const EVENT_DOWNLOAD_PROGRESS = 302;
  // Video download stopped.
  // 视频下载停止
  static const EVENT_DOWNLOAD_STOP = 303;
  // Video download completed.
  // 视频下载完成
  static const EVENT_DOWNLOAD_FINISH = 304;
  // Error occurred during video download.
  // 视频下载错误
  static const EVENT_DOWNLOAD_ERROR = 305;

  // SDK event
  // onLicenceLoaded
  static const EVENT_ON_LICENCE_LOADED = 503;

  static const EVENT_RESULT = "result";
  static const EVENT_REASON = "reason";
}

abstract class TXVodNetEvent {
  static const NET_STATUS_CPU_USAGE = "CPU_USAGE"; // CPU usage rate.
  static const NET_STATUS_VIDEO_WIDTH = "VIDEO_WIDTH"; // Width of resolution.
  static const NET_STATUS_VIDEO_HEIGHT = "VIDEO_HEIGHT"; // Height of resolution.
  // Current video frame rate, i.e. the number of frames produced by the video encoder.
  // 当前视频帧率,也就是视频编码器每条生产了多少帧画面
  static const NET_STATUS_VIDEO_FPS = "VIDEO_FPS";
  // Current video GOP, i.e. the time interval between two key frames (I-frames), in seconds.
  // 当前视频GOP,也就是每两个关键帧(I帧)间隔时长，单位s
  static const NET_STATUS_VIDEO_GOP = "VIDEO_GOP";
  // Pushing: video data sending bit rate; pulling: video data receiving bit rate. Unit: kbps.
  // 推流：视频数据发送比特率；拉流：视频数据接收比特率 单位：kbps
  static const NET_STATUS_VIDEO_BITRATE = "VIDEO_BITRATE";
  // Pushing: audio data sending bit rate; pulling: audio data receiving bit rate. Unit: kbps.
  // 推流：音频数据发送比特率；拉流：音频数据接收比特率 单位：kbps
  static const NET_STATUS_AUDIO_BITRATE = "AUDIO_BITRATE";
  // Pushing: total bit rate of audio and video data sent; pulling: total bit rate of audio and video data received. Unit: kbps.
  // 推流：音视频数据发送总比特率；拉流：音视频数据接收总比特率 单位：kbps
  static const NET_STATUS_NET_SPEED = "NET_SPEED";
  // Pushing: number of unsent audio frames in the sender buffer;
  // pulling: total duration of audio frames received but not played in the receiver.
  // 推流：发送端缓存未发送的音频帧数；拉流：接收端已接收但未播放的音频帧总时长
  static const NET_STATUS_AUDIO_CACHE = "AUDIO_CACHE";
  // Pushing: number of unsent video frames in the sender buffer;
  // pulling: total duration of video frames received but not rendered in the receiver.
  // 推流：发送端缓存未发送的视频帧数；拉流：接收端已接收但未渲染的视频帧总时长
  static const NET_STATUS_VIDEO_CACHE = "VIDEO_CACHE";
  // Pushing: number of audio frames dropped by the sender (not used: no audio frame dropping logic in upstream);
  // pulling: number of audio frames dropped by the receiver (not used: audio acceleration in the player, no frame dropping).
  // 推流：发送端音频丢帧数(未用:上行无音频丢帧逻辑)   拉流：接收端音频丢帧数（未用：播放端有音频加速，不丢帧）
  static const NET_STATUS_AUDIO_DROP = "AUDIO_DROP";
  // Pushing: number of video frames dropped by the sender (used: real-time pushing has frame dropping logic);
  // pulling: number of video frames dropped by the receiver (not used: video acceleration in the player, no frame dropping).
  // 推流：发送端视频丢帧数(有用:实时推流有丢帧逻辑)   拉流：接收端视频丢帧数（未用：播放端有视频加速，不丢帧）
  static const NET_STATUS_VIDEO_DROP = "VIDEO_DROP";
  // Pulling only: number of video frames received but not rendered, including the JitterBuffer and decoder buffer.
  // 拉流专用：接收端已接收但未渲染的视频帧数（包括JitterBuffer和解码器两部分缓存）
  static const NET_STATUS_V_SUM_CACHE_SIZE = "V_SUM_CACHE_SIZE";
  // Pulling only: number of video frames cached in the decoder buffer.
  // 拉流专用：接收端解码器里缓存的视频帧数
  static const NET_STATUS_V_DEC_CACHE_SIZE = "V_DEC_CACHE_SIZE";
  // Pulling only: the difference between the timestamp of the current video rendering frame and the timestamp
  // of the current audio playing frame, indicating the synchronization status of audio and video at that time.
  // 拉流专用：视频当前渲染帧的timestamp和音频当前播放帧的timestamp的差值，标示当时音画同步的状态
  static const NET_STATUS_AV_PLAY_INTERVAL = "AV_PLAY_INTERVAL";
  // Pulling only: the difference between the timestamp of the latest received video frame and the timestamp of the latest received
  // audio frame in the JitterBuffer, indicating the synchronization status of packet reception at that time.
  // 拉流专用：jitterbuffer最新收到的视频帧和音频帧的timestamp的差值，标示当时jitterbuffer收包同步的状态
  static const NET_STATUS_AV_RECV_INTERVAL = "AV_RECV_INTERVAL";
  // Pulling only: the threshold of audio cache duration in seconds. When the cached audio duration exceeds this threshold,
  // the JitterBuffer will accelerate the playback to ensure the playback delay.
  // 拉流专用：播放端音频缓存时长阀值，单位：秒，当缓存的音频时长大于该阀值时会触发jitterbuffer的加速播放，以保证播放时延
  static const NET_STATUS_AUDIO_CACHE_THRESHOLD = "AUDIO_CACHE_THRESHOLD";
  // Pulling only: audio stuttering duration, in milliseconds.
  // 拉流专用：音频卡顿时长，单位ms
  static const NET_STATUS_AUDIO_BLOCK_TIME = "AUDIO_BLOCK_TIME";
  // Current audio information of the stream, including sampling rate and number of channels.
  // 当前流的音频信息，包括采样率信息和声道数信息
  static const NET_STATUS_AUDIO_INFO = "AUDIO_PLAY_INFO";
  // Network jitter, the larger the value, the greater the jitter and the more unstable the network.
  // 网络抖动情况，数值越大表示抖动越大，网络越不稳定
  static const NET_STATUS_NET_JITTER = "NET_JITTER";
  // IP address of the connected server.
  // 连接的Server IP地址
  static const NET_STATUS_SERVER_IP = "SERVER_IP";
  // Current decoder output frame rate (VOD).
  // 当前解码器输出帧率（点播）
  static const NET_STATUS_VIDEO_DPS = "VIDEO_DPS";
  // Network quality: 0: undefined, 1: best, 2: good, 3: normal, 4: poor, 5: very poor, 6: unavailable.
  // 网络质量：0：未定义 1：最好 2：好 3：一般 4：差 5：很差 6：不可用
  static const NET_STATUS_QUALITY_LEVEL = "NET_QUALITY_LEVEL";
}

enum TXPlayerLiveMode {
  // Auto mode.
  // 自动模式
  Automatic,
  // Ultra-fast mode.
  // 极速模式
  Speed,
  // Smooth mode.
  // 流畅模式
  Smooth
}

enum TXPlayerState {
  // Playback paused.
  // 暂停播放
  paused,
  // Playback failed.
  // 播放失败
  failed,
  // Buffering.
  // 缓冲中
  buffering,
  // Playing.
  // 播放中
  playing,
  // Playback stopped.
  // 停止播放
  stopped,
  // Control released.
  // 控件释放了
  disposed
}

enum TXPlayerEvent {
  // Network interrupted, reconnecting automatically.
  // 网络中断，自动重连中
  reconnect,
  // Network interrupted, reconnection failed.
  // 网络中断，重连失败
  disconnect,
  // RTMP-DNS resolution failed.
  // RTMP-DNS 解析失败
  dnsFail,
  // RTMP server connection failed.
  // RTMP 服务器连接失败
  severConnFail,
  // RTMP server handshake failed.
  // RTMP 服务器握手失败
  shakeFail,
  // Progress.
  // 进度
  progress
}

class TXLogLevel {
  // Output all levels of logs.
  // 输出所有级别的log
  static const LOG_LEVEL_VERBOSE = 0;
  // Output DEBUG, INFO, WARNING, ERROR, and FATAL level logs.
  // 输出 DEBUG,INFO,WARNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_DEBUG = 1;
  // Output INFO, WARNING, ERROR, and FATAL level logs.
  // 输出 INFO,WARNNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_INFO = 2;
  // Output WARNING, ERROR, and FATAL level logs.
  // 输出WARNNING,ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_WARN = 3;
  // Output ERROR and FATAL level logs.
  // 输出ERROR 和 FATAL 级别的log
  static const LOG_LEVEL_ERROR = 4;
  // Only output FATAL level logs.
  // 只输出FATAL 级别的log
  static const LOG_LEVEL_FATAL = 5;
  // Do not output any SDK logs.
  // 不输出任何sdk log
  static const LOG_LEVEL_NULL = 6;
}

class DownloadQuality {
  @deprecated
  static const QUALITY_OD = 0;
  @deprecated
  static const QUALITY_FLU = 1;
  @deprecated
  static const QUALITY_SD = 2;
  @deprecated
  static const QUALITY_HD = 3;
  @deprecated
  static const QUALITY_FHD = 4;

  static const int QUALITY_2K = 5;
  static const int QUALITY_4K = 6;
  static const int QUALITY_UNK = 1000;
  static const int QUALITY_240P = 240;
  static const int QUALITY_360P = 360;
  static const int QUALITY_480P = 480;
  static const int QUALITY_540P = 540;
  static const int QUALITY_720P = 720;
  static const int QUALITY_1080P = 1080;
}

class TXPlayInfoParams {
  final int appId; // Tencent Cloud video appId, required
  final String fileId; // Tencent Cloud video fileId, required
  final String? psign; // Tencent cloud video encryption signature, required for encrypted video
  // video url, only applicable for preloading. When using it, you only need to fill in either the url or fileId.
  // The priority of the url is higher than that of the fileId.
  final String? url;

  const TXPlayInfoParams({required this.appId, required this.fileId, this.psign = "", this.url = ""});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["appId"] = appId;
    json["fileId"] = fileId;
    json["psign"] = psign;
    json["url"] = url;
    return json;
  }
}

/// File ID storage.
/// fileId存储
class TXVodDownloadDataSource {
  /// App ID corresponding to the downloaded file, required for file ID download.
  /// 下载文件对应的appId，fileId下载必填
  int? appId;

  /// Downloaded file ID, required for fileId download.
  /// 下载文件Id，fileId下载必填
  String? fileId;

  /// Encryption signature, required for encrypted video.
  /// 加密签名，加密视频必填
  String? pSign;

  /// Quality ID, required for file ID download, converted through [CommonUtils.getDownloadQualityBySize].
  /// 清晰度ID,fileId下载必传，通过[CommonUtils.getDownloadQualityBySize]进行转换
  int? quality;

  /// Encryption token.
  /// 加密token
  String? token;

  /// Account name, used to set the account name for URL download.
  /// It is not recommended to set a string that is too long,
  /// Otherwise, it may lead to unforeseen problems.
  /// 账户名称,用于url下载设置账户名称。不建议设置比较长的字符串，否则可能会导致不可预料的问题。
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

/// Video download information.
/// 视频下载信息
class TXVodDownloadMediaInfo {
  /// Cache address.
  /// 缓存地址
  String? playPath;

  /// Download progress.
  /// 下载进度
  double? progress;

  /// Download status.
  /// 下载状态
  int? downloadState;

  /// Account name, used to set the account name for URL download.
  /// It is not recommended to set a string that is too long,
  /// Otherwise, it may lead to unforeseen problems.
  /// 账户名称,用于url下载设置账户名称。不建议设置比较长的字符串，否则可能会导致不可预料的问题。
  String? userName;

  /// Total duration.
  /// 总时长
  int? duration;

  /// Downloaded playable duration
  /// 已下载的可播放时长
  int? playableDuration;

  /// Total file size, in bytes.
  /// 文件总大小，单位：byte
  int? size;

  /// Downloaded size, in bytes.
  /// 已下载大小，单位：byte
  int? downloadSize;

  /// Video URL to be downloaded, required for URL download.
  /// 需要下载的视频url，url下载必填
  String? url;

  /// Download speed, in KBytes/second.
  /// 下载速度，单位：KByte/秒
  int? speed;

  /// Whether the resource is damaged, such as being deleted.
  /// 资源是否已损坏, 如：资源被删除了
  bool? isResourceBroken;

  /// File ID storage
  /// fileId 存储
  TXVodDownloadDataSource? dataSource;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (null != dataSource) {
      json.addAll(dataSource!.toJson());
    }
    json["url"] = url;
    json["downloadState"] = downloadState;
    json["progress"] = progress;
    json["playPath"] = playPath;
    json["userName"] = userName;
    json["duration"] = duration;
    json["playableDuration"] = playableDuration;
    json["size"] = size;
    json["downloadSize"] = downloadSize;
    json["speed"] = speed;
    json["isResourceBroken"] = isResourceBroken;
    return json;
  }

  TXVodDownloadMediaMsg toMsg() {
    TXVodDownloadMediaMsg msg = TXVodDownloadMediaMsg();
    if (null != dataSource) {
      msg.appId = dataSource!.appId;
      msg.fileId = dataSource!.fileId;
      msg.pSign = dataSource!.pSign;
      msg.quality = dataSource!.quality;
      msg.token = dataSource!.token;
      msg.userName = dataSource!.userName ?? "default";
    }
    msg.url = url;
    msg.downloadState = downloadState;
    msg.progress = progress;
    msg.playPath = playPath;
    msg.userName = userName ?? "default";
    msg.duration = duration;
    msg.playableDuration = playableDuration;
    msg.size = size;
    msg.downloadSize = downloadSize;
    msg.speed = speed;
    msg.isResourceBroken = isResourceBroken;
    return msg;
  }
}

/// Player type.
///
/// 播放器类型
abstract class TXPlayerType {
  static const VOD_PLAY = 0;
  static const LIVE_PLAY = 1;
}

// Video pre-download event callback listener.
// 视频预下载事件回调Listener
// onStartListener, just for fileId preload
typedef FTXPredownlodOnStartListener = void Function(int taskId, String fileId, String url, Map<dynamic, dynamic> params);
typedef FTXPredownlodOnCompleteListener = void Function(int taskId, String url);
typedef FTXPredownlodOnErrorListener = void Function(int taskId, String url, int code, String msg);
// Video download time callback listener.
// 视频下载时间回调Listener
typedef FTXDownlodOnStateChangeListener = void Function(int event, TXVodDownloadMediaInfo info);
typedef FTXDownlodOnErrorListener = void Function(int errorCode, String errorMsg, TXVodDownloadMediaInfo info);

typedef FTXLicenceLoadedListener = void Function(int result, String reason);
