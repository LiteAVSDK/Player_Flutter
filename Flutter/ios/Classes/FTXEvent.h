// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXEVENT_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXEVENT_H_

// Event code.
#define EVENT_VOLUME_CHANGED 1
#define EVENT_AUDIO_FOCUS_PAUSE 2
#define EVENT_AUDIO_FOCUS_PLAY 3
// Volume change.
#define EVENT_BRIGHTNESS_CHANGED 4

// PIP event code.
#define EVENT_PIP_MODE_ALREADY_ENTER    1
#define EVENT_PIP_MODE_ALREADY_EXIT     2
#define EVENT_PIP_MODE_REQUEST_START    3
#define EVENT_PIP_MODE_UI_STATE_CHANGED 4
#define EVENT_PIP_MODE_RESTORE_UI       5
#define EVENT_PIP_MODE_WILL_EXIT        6

#define EVENT_PIP_PLAY_TIME             @"playTime"

// PIP error event code.
#define NO_ERROR                             0     ///<   No error. 无错误
/// Device or system version is not supported (PIP is only supported on iPad iOS9+).
/// 设备或系统版本不支持（iPad iOS9+ 才支持PIP）
#define ERROR_IOS_PIP_DEVICE_NOT_SUPPORT     -104
/// Player not supported.
/// 播放器不支持
#define ERROR_IOS_PIP_PLAYER_NOT_SUPPORT     -105
/// Video not supported.
/// 视频不支持
#define ERROR_IOS_PIP_VIDEO_NOT_SUPPORT      -106
/// PIP controller not available
/// PIP控制器不可用
#define ERROR_IOS_PIP_IS_NOT_POSSIBLE        -107
/// PIP controller error.
/// PIP控制器报错
#define ERROR_IOS_PIP_FROM_SYSTEM            -108
/// Player object does not exist.
/// 播放器对象不存在
#define ERROR_IOS_PIP_PLAYER_NOT_EXIST       -109
/// PIP function is already running.
/// PIP功能已经运行
#define ERROR_IOS_PIP_IS_RUNNING             -110
/// PIP function is not started.
/// PIP功能没有启动
#define ERROR_IOS_PIP_NOT_RUNNING            -111



// Video pre-download completed.
// 视频预下载完成
#define EVENT_PREDOWNLOAD_ON_COMPLETE 200
// Video pre-download error.
// 视频预下载出错
#define EVENT_PREDOWNLOAD_ON_ERROR 201
// fileId preload is start, callback url、taskId and other video info
#define EVENT_PREDOWNLOAD_ON_START 202

// Video download started.
// 视频下载开始
#define EVENT_DOWNLOAD_START 301
// Video download progress.
// 视频下载进度
#define EVENT_DOWNLOAD_PROGRESS 302
// Video download stopped.
// 视频下载停止
#define EVENT_DOWNLOAD_STOP 303
// Video download completed.
// 视频下载完成
#define EVENT_DOWNLOAD_FINISH 304
// Video download error.
// 视频下载错误
#define EVENT_DOWNLOAD_ERROR 305

// Screen rotation event.
// 屏幕旋转事件
#define EVENT_ORIENTATION_CHANGED 401
// Screen rotation direction.
// 屏幕旋转方向
#define EXTRA_NAME_ORIENTATION @"orientation"
// Portrait.
// 正竖屏
#define ORIENTATION_PORTRAIT_UP 411
// Landscape, bottom on the right.
// 横屏，底部在右
#define ORIENTATION_LANDSCAPE_RIGHT 412
// Portrait, top at the bottom.
// 竖屏，顶部在下
#define ORIENTATION_PORTRAIT_DOWN 413
// Landscape, bottom on the left.
// 横屏，底部在左
#define ORIENTATION_LANDSCAPE_LEFT 414

// SDK event
// onLog
#define EVENT_ON_LOG 501
// onUpdateNetworkTime
#define EVENT_ON_UPDATE_NETWORK_TIME 502
// onLicenceLoaded
#define EVENT_ON_LICENCE_LOADED 503
// onCustomHttpDNS
#define EVENT_ON_CUSTOM_HTTP_DNS 504

// this events may be common,so remove the specific field identifier
#define EVENT_LOG_LEVEL "logLevel"
#define EVENT_LOG_MODULE "logModule"
#define EVENT_LOG_MSG "logMsg"
#define EVENT_ERR_CODE "errCode"
#define EVENT_ERR_MSG "errMsg"
#define EVENT_RESULT "result"
#define EVENT_REASON "reason"
#define EVENT_HOST_NAME "hostName"
#define EVENT_IPS "ips"

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXEVENT_H_
