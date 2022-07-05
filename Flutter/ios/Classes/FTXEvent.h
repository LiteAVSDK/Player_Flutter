// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef FTXEvent_h
#define FTXEvent_h

// 音频变化事件code
#define EVENT_VOLUME_CHANGED 1
#define EVENT_AUDIO_FOCUS_PAUSE 2
#define EVENT_AUDIO_FOCUS_PLAY 3

// 视频预下载完成
#define EVENT_PREDOWNLOAD_ON_COMPLETE 200
// 视频预下载出错
#define EVENT_PREDOWNLOAD_ON_ERROR 201

// 视频下载开始
#define EVENT_DOWNLOAD_START 301
// 视频下载进度
#define EVENT_DOWNLOAD_PROGRESS 302
// 视频下载停止
#define EVENT_DOWNLOAD_STOP 303
// 视频下载完成
#define EVENT_DOWNLOAD_FINISH 304
// 视频下载错误
#define EVENT_DOWNLOAD_ERROR 305

#endif /* FTXEvent_h */
