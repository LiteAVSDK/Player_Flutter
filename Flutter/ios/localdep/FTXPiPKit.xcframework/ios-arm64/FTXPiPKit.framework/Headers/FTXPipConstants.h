// Copyright (c) 2024 Tencent. All rights reserved.
#import "FTXPipLiteAVSDKHeader.h"

#ifndef FTXPipConstants_h
#define FTXPipConstants_h


// 点播高级套餐 Feature
#define TUI_FEATURE_PLAYER_PREMIUM     (0b10000000)
// 点播企业套餐 Feature
#define TUI_FEATURE_PLAYER_ENTERPRISE  (0b100000000)

#define TXC_PIP_START_DELAY_MS          200

// pip status
typedef NS_ENUM(NSInteger, FTX_LIVE_PIP_ERROR) {
    /// 无错误
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_NONE = TX_VOD_PLAYER_PIP_ERROR_TYPE_NONE,

    /// 设备或系统版本不支持（iPad iOS9+ 才支持PIP）
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_DEVICE_NOT_SUPPORT = TX_VOD_PLAYER_PIP_ERROR_TYPE_DEVICE_NOT_SUPPORT,
    
    /// 播放器不支持
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_SUPPORT = TX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_SUPPORT,

    /// 视频不支持
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_VIDEO_NOT_SUPPORT = TX_VOD_PLAYER_PIP_ERROR_TYPE_VIDEO_NOT_SUPPORT,

    /// PIP控制器不可用
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_NOT_POSSIBLE = TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_NOT_POSSIBLE,

    /// PIP控制器报错
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_ERROR_FROM_SYSTEM = TX_VOD_PLAYER_PIP_ERROR_TYPE_ERROR_FROM_SYSTEM,

    /// 播放器对象不存在
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_EXIST = TX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_EXIST,

    /// PIP功能已经运行
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_RUNNING = TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_RUNNING,

    /// PIP功能没有启动
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_NOT_RUNNING = TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_NOT_RUNNING,

    /// PIP启动超时
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_START_TIMEOUT = TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_START_TIMEOUT,

    /// pip 没有 sdk 权限
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_AUTH_DENIED = 101,
    // 缺乏画中画 bundle 资源
    FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_MISS_RESOURCE = 102,
};


// PIP error event code.
#define NO_PIP_ERROR                             0     ///<   No error. 无错误
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
/// PIP  start time out
/// PIP 启动超时
#define ERROR_IOS_PIP_START_TIME_OUT            -112
/// Insufficient permissions, currently only appears in Picture-in-Picture live streaming
/// 权限不足，目前只出现在直播画中画
#define ERROR_PIP_AUTH_DENIED                -201

/**
 后台画中画播放器的播放状态
 */
typedef NS_ENUM(NSInteger, FTXAVPlayerState) {
    FTXAVPlayerStateIdle = 0,     // 初始状态
    FTXAVPlayerStatePrepared,     // 播放准备完毕
    FTXAVPlayerStatePlaying,      // 播放中
    FTXAVPlayerStatePaused,       // 播放暂停
    FTXAVPlayerStateStopped,      // 播放停止
    FTXAVPlayerStateComplete,     // 播放完毕
    FTXAVPlayerStateError,        // 播放失败
};

#endif /* FTXPipConstants_h */
