// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef FTXEvent_h
#define FTXEvent_h

// 音频变化事件code
#define EVENT_VOLUME_CHANGED 0x01
#define EVENT_AUDIO_FOCUS_PAUSE 0x02
#define EVENT_AUDIO_FOCUS_PLAY 0x03

// 画中画事件code
#define EVENT_PIP_MODE_ALREADY_ENTER    1
#define EVENT_PIP_MODE_ALREADY_EXIT     2
#define EVENT_PIP_MODE_REQUEST_START    3
#define EVENT_PIP_MODE_UI_STATE_CHANGED 4
#define EVENT_PIP_MODE_RESTORE_UI       5
#define EVENT_PIP_MODE_WILL_EXIT        6

// 画中画错误事件code
#define NO_ERROR                             0     ///<   无错误
#define ERROR_IOS_PIP_DEVICE_NOT_SUPPORT     -104  ///<   设备或系统版本不支持（iPad iOS9+ 才支持PIP）
#define ERROR_IOS_PIP_PLAYER_NOT_SUPPORT     -105  ///<   播放器不支持
#define ERROR_IOS_PIP_VIDEO_NOT_SUPPORT      -106  ///<   视频不支持
#define ERROR_IOS_PIP_IS_NOT_POSSIBLE        -107  ///<   PIP控制器不可用
#define ERROR_IOS_PIP_FROM_SYSTEM            -108  ///<   PIP控制器报错
#define ERROR_IOS_PIP_PLAYER_NOT_EXIST       -109  ///<   播放器对象不存在
#define ERROR_IOS_PIP_IS_RUNNING             -110  ///<   PIP功能已经运行
#define ERROR_IOS_PIP_NOT_RUNNING            -111  ///<   PIP功能没有启动



// 视频预下载完成
#define EVENT_PREDOWNLOAD_ON_COMPLETE 200
// 视频预下载出错
#define EVENT_PREDOWNLOAD_ON_ERROR 201
#endif /* FTXEvent_h */
