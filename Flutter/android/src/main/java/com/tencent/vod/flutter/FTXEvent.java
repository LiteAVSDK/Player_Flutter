// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

/**
 * 通用事件码
 */
public class FTXEvent {
    /*
    音量变化
     */
    public static final int EVENT_VOLUME_CHANGED    = 1;
    /*
    失去音量输出播放焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PAUSE = 2;
    /*
    获得音量输出焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PLAY  = 3;

    // 视频预下载完成
    public static final int EVENT_PREDOWNLOAD_ON_COMPLETE = 200;

    // 视频预下载出错
    public static final int EVENT_PREDOWNLOAD_ON_ERROR = 201;

    // 视频下载开始
    public static final int EVENT_DOWNLOAD_START    = 301;
    // 视频下载进度
    public static final int EVENT_DOWNLOAD_PROGRESS = 302;
    // 视频下载停止
    public static final int EVENT_DOWNLOAD_STOP     = 303;
    // 视频下载完成
    public static final int EVENT_DOWNLOAD_FINISH   = 304;
    // 视频下载错误
    public static final int EVENT_DOWNLOAD_ERROR    = 305;

    public static final int NO_ERROR                = 0;
    /**
     * pip 事件
     */
    public static final String PIP_CHANNEL_NAME              = "cloud.tencent.com/playerPlugin/componentEvent";
    // pip广播action
    public static final String ACTION_PIP_PLAY_CONTROL        = "vodPlayControl";
    // pip 操作
    public static final String EXTRA_NAME_PLAY_OP             = "vodPlayOp";
    // pip需要操作的播放器
    public static final String EXTRA_NAME_PLAYER_ID           = "vodPlayerId";
    // 进度回退
    public static final int    EXTRA_PIP_PLAY_BACK            = 101;
    // 继续/暂停
    public static final int    EXTRA_PIP_PLAY_RESUME_OR_PAUSE = 102;
    // 进度前进
    public static final int    EXTRA_PIP_PLAY_FORWARD         = 103;
    // pip 错误，android版本过低
    public static final int    ERROR_PIP_LOWER_VERSION        = -101;
    // pip 错误，画中画权限关闭/设备不支持画中画
    public static final int    ERROR_PIP_DENIED_PERMISSION    = -102;
    // pip 错误，当前界面已销毁
    public static final int    ERROR_PIP_ACTIVITY_DESTROYED   = -103;
    // 来自画中画容器的事件，广播键值
    public static final String EVENT_PIP_ACTION               = "com.tencent.flutter.pipevent";
    // 来自画中画容器的事件，事件键值
    public static final String EVENT_PIP_MODE_NAME            = "pipEventName";
    // 画中画当前播放时间
    public static final String EVENT_PIP_PLAY_TIME            = "playTime";
    // 来自画中画容器的事件，已经进入画中画
    public static final int    EVENT_PIP_MODE_ALREADY_ENTER    = 1;
    // 来自画中画容器的事件，已经退出画中画
    public static final int    EVENT_PIP_MODE_ALREADY_EXIT     = 2;
    // 来自画中画容器的事件，开始进入画中画
    public static final int    EVENT_PIP_MODE_REQUEST_START    = 3;
    // 来自画中画容器的事件，画中画UI发生变动，> android 31
    public static final int    EVENT_PIP_MODE_UI_STATE_CHANGED = 4;
    // 画中画界面恢复，即点击放大按钮
    public static final int    EVENT_PIP_MODE_RESTORE_UI       = 5;

    // 启动画中画
    public static final String PIP_ACTION_START = "com.tencent.flutter.startPip";
    // 退出画中画
    public static final String PIP_ACTION_EXIT = "com.tencent.flutter.exitPip";
    // 更新画中画
    public static final String PIP_ACTION_UPDATE = "com.tencent.flutter.updatePip";
    // 画中画参数
    public static final String EXTRA_NAME_PARAMS = "pipParams";
    // 视频源
    public static final String EXTRA_NAME_VIDEO = "videoModel";
    // 画中画结束参数
    public static final String EXTRA_NAME_RESULT = "pipResult";

    // 点播播放器
    public static final int PLAYER_VOD = 1;
    // 直播播放器
    public static final int PLAYER_LIVE = 2;


    // 屏幕旋转事件
    public static final int EVENT_ORIENTATION_CHANGED = 401;
    // 屏幕旋转方向
    public static final String EXTRA_NAME_ORIENTATION = "orientation";
    // 正竖屏
    public static final int ORIENTATION_PORTRAIT_UP = 411;
    // 横屏，底部在右
    public static final int ORIENTATION_LANDSCAPE_RIGHT = 412;
    // 竖屏，顶部在下
    public static final int ORIENTATION_PORTRAIT_DOWN = 413;
    // 横屏，底部在左
    public static final int ORIENTATION_LANDSCAPE_LEFT = 414;

}
