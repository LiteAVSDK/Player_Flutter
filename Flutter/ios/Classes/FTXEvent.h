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


#define VIEW_TYPE_FTX_RENDER_VIEW  @"FTXRenderViewType"

// PIP error event code.
#define NO_ERROR                             0     ///<   No error. 无错误

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
// subtitle data event
// 回调 SubtitleData 事件id
#define EVENT_SUBTITLE_DATA 601
// subtitle data extra key
// 回调 SubtitleData 事件对应的key
#define EXTRA_SUBTITLE_DATA @"subtitleData"
#define EXTRA_SUBTITLE_START_POSITION_MS @"startPositionMs"
#define EXTRA_SUBTITLE_DURATION_MS @"durationMs"
#define EXTRA_SUBTITLE_TRACK_INDEX @"trackIndex"


// player event
#define EVT_KEY_PLAYER_EVENT @"event"
#define EVT_KEY_PLAYER_NET @"net"
#define EVT_KEY_PLAYER_WIDTH @"EVT_WIDTH"
#define EVT_KEY_PLAYER_HEIGHT @"EVT_HEIGHT"
#define EVT_FLUTTER_PLAYABLE_DURATION @"EVT_PLAYABLE_DURATION"
#define EVT_FLUTTER_PLAYABLE_DURATION_MS @"EVT_PLAYABLE_DURATION_MS"
#define EVT_FLUTTER_PROGRESS_MS @"EVT_PLAY_PROGRESS_MS"
#define EVT_FLUTTER_DURATION_MS @"EVT_PLAY_DURATION_MS"


// net event
#define NET_STATUS_SYSTEM_CPU @"SYSTEM_CPU"
#define NET_STATUS_VIDEO_LOSS @"VIDEO_PACKET_LOSS"
#define NET_STATUS_AUDIO_LOSS @"AUDIO_PACKET_LOSS"
#define NET_STATUS_AUDIO_TOTAL_BLOCK_TIME @"AUDIO_TOTAL_BLOCK_TIME"
#define NET_STATUS_VIDEO_TOTAL_BLOCK_TIME @"VIDEO_TOTAL_BLOCK_TIME"
#define NET_STATUS_VIDEO_BLOCK_RATE @"VIDEO_BLOCK_RATE"
#define NET_STATUS_AUDIO_BLOCK_RATE @"AUDIO_BLOCK_RATE"
#define NET_STATUS_RTT @"RTT"

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXEVENT_H_
