// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

/**
 * 通用事件码
 */
public class FTXEvent {

    /*
    Volume change.
    音量变化
     */
    public static final int EVENT_VOLUME_CHANGED = 1;
    /*
    Lost audio output playback focus.
    失去音量输出播放焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PAUSE = 2;
    /*
    Obtained audio output focus.
    获得音量输出焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PLAY = 3;
    /*
    Brightness change.
    亮度发生变化
     */
    public static final int EVENT_BRIGHTNESS_CHANGED = 4;

    // Video pre-download completed.
    // 视频预下载完成
    public static final int EVENT_PREDOWNLOAD_ON_COMPLETE = 200;

    // Video pre-download error.
    // 视频预下载出错
    public static final int EVENT_PREDOWNLOAD_ON_ERROR = 201;

    // fileId preload is start, callback url、taskId and other video info
    public static final int EVENT_PREDOWNLOAD_ON_START = 202;

    // Video download started.
    // 视频下载开始
    public static final int EVENT_DOWNLOAD_START = 301;
    // Video download progress.
    // 视频下载进度
    public static final int EVENT_DOWNLOAD_PROGRESS = 302;
    // Video download stopped.
    // 视频下载停止
    public static final int EVENT_DOWNLOAD_STOP = 303;
    // Video download completed.
    // 视频下载完成
    public static final int EVENT_DOWNLOAD_FINISH = 304;
    // Video download error.
    // 视频下载错误
    public static final int EVENT_DOWNLOAD_ERROR = 305;

    public static final int NO_ERROR = 0;
    /**
     * PIP event.
     * pip 事件
     */
    public static final String PIP_CHANNEL_NAME = "cloud.tencent.com/playerPlugin/componentEvent";
    // PIP broadcast action.
    // pip广播action
    public static final String ACTION_PIP_PLAY_CONTROL = "vodPlayControl";
    // PIP operation.
    // pip 操作
    public static final String EXTRA_NAME_PLAY_OP = "vodPlayOp";
    // Player to be operated on PIP
    // pip需要操作的播放器
    public static final String EXTRA_NAME_PLAYER_ID = "vodPlayerId";
    // pip player event id
    // 画中画播放器事件的事件id
    public static final String EXTRA_NAME_PIP_PLAYER_EVENT_ID = "pipPlayerEventId";
    // pip player event params
    // 画中画播放器事件的事件参数
    public static final String EXTRA_NAME_PIP_PLAYER_EVENT_PARAMS = "pipPlayerEventParams";
    // Progress rewind.
    // 进度回退
    public static final int EXTRA_PIP_PLAY_BACK = 101;
    // Resume/pause.
    // 继续/暂停
    public static final int EXTRA_PIP_PLAY_RESUME_OR_PAUSE = 102;
    // Progress forward.
    // 进度前进
    public static final int EXTRA_PIP_PLAY_FORWARD = 103;
    // PIP error, Android version is too low.
    // pip 错误，android版本过低
    public static final int ERROR_PIP_LOWER_VERSION = -101;
    // PIP error, picture-in-picture permission is turned off.
    // pip 错误，画中画权限关闭
    public static final int ERROR_PIP_DENIED_PERMISSION = -102;
    // PIP error, current interface has been destroyed.
    // pip 错误，当前界面已销毁
    public static final int ERROR_PIP_ACTIVITY_DESTROYED = -103;
    // PIP error, miss player
    // pip 错误，丢失播放器
    public static final int ERROR_PIP_MISS_PLAYER = -109;
    // PIP error, pip is busy
    // pip 错误，已经存在画中画窗口
    public static final int ERROR_PIP_IN_BUSY = -110;
    // PIP error, device does not support picture-in-picture.
    // pip 错误，设备不支持画中画
    public static final int ERROR_PIP_FEATURE_NOT_SUPPORT = -104;
    // Event from PIP container,eventBus key value
    // 来自画中画容器的事件，eventBus键值
    public static final String EVENT_PIP_ACTION = "com.tencent.flutter.pipevent";
    // Player event from PIP players,eventBus key value
    // 来自画中画容器的事件，eventBus键值
    public static final String EVENT_PIP_PLAYER_EVENT_ACTION = "com.tencent.flutter.pipplayerevent";
    // Event from PIP container,eventBus key value
    // 来自画中画容器的事件，事件键值
    public static final String EVENT_PIP_MODE_NAME = "pipEventName";
    // Current PIP playback time.
    // 画中画当前播放时间
    public static final String EVENT_PIP_PLAY_TIME = "playTime";
    // Event from PIP container, entered PIP.
    // 来自画中画容器的事件，已经进入画中画
    public static final int EVENT_PIP_MODE_ALREADY_ENTER = 1;
    // Event from PIP container, exited PIP.
    // 来自画中画容器的事件，已经退出画中画
    public static final int EVENT_PIP_MODE_ALREADY_EXIT = 2;
    // Event from PIP container, started entering PIP.
    // 来自画中画容器的事件，开始进入画中画
    public static final int EVENT_PIP_MODE_REQUEST_START = 3;
    // Event from PIP container, PIP UI has changed, > Android 31.
    // 来自画中画容器的事件，画中画UI发生变动，> android 31
    public static final int EVENT_PIP_MODE_UI_STATE_CHANGED = 4;
    // PIP interface is restored, i.e. click the enlarge button.
    // 画中画界面恢复，即点击放大按钮
    public static final int EVENT_PIP_MODE_RESTORE_UI = 5;

    // Start PIP.
    // 启动画中画
    public static final String PIP_ACTION_START = "com.tencent.flutter.startPip";
    // Exit PIP.
    // 退出画中画
    public static final String PIP_ACTION_EXIT = "com.tencent.flutter.exitPip";
    // Update PIP.
    // 更新画中画
    public static final String PIP_ACTION_UPDATE = "com.tencent.flutter.updatePip";
    // PIP parameters.
    // 画中画参数
    public static final String EXTRA_NAME_PARAMS = "pipParams";
    // End parameters of PIP.
    // 画中画结束参数
    public static final String EXTRA_NAME_RESULT = "pipResult";
    // End parameters of PIP.
    // 画中画结束参数
    public static final String EXTRA_NAME_IS_PLAYING = "isPlaying";

    // VOD player.
    // 点播播放器
    public static final int PLAYER_VOD = 1;
    // Live player.
    // 直播播放器
    public static final int PLAYER_LIVE = 2;


    // Screen rotation event.
    // 屏幕旋转事件
    public static final int EVENT_ORIENTATION_CHANGED = 401;
    // Screen rotation direction.
    // 屏幕旋转方向
    public static final String EXTRA_NAME_ORIENTATION = "orientation";
    // Portrait.
    // 正竖屏
    public static final int ORIENTATION_PORTRAIT_UP = 411;
    // Landscape, bottom on the right.
    // 横屏，底部在右
    public static final int ORIENTATION_LANDSCAPE_RIGHT = 412;
    // Portrait, top at the bottom.
    // 竖屏，顶部在下
    public static final int ORIENTATION_PORTRAIT_DOWN = 413;
    // Landscape, bottom on the left.
    // 横屏，底部在左
    public static final int ORIENTATION_LANDSCAPE_LEFT = 414;


    // SDK event
    // onLog
    public static final int EVENT_ON_LOG = 501;
    // onUpdateNetworkTime
    public static final int EVENT_ON_UPDATE_NETWORK_TIME = 502;
    // onLicenceLoaded
    public static final int EVENT_ON_LICENCE_LOADED = 503;
    // onCustomHttpDNS
    public static final int EVENT_ON_CUSTOM_HTTP_DNS = 504;

    // this events may be common,so remove the specific field identifier
    public static final String EVENT_LOG_LEVEL = "logLevel";
    public static final String EVENT_LOG_MODULE = "logModule";
    public static final String EVENT_LOG_MSG = "logMsg";
    public static final String EVENT_ERR_CODE = "errCode";
    public static final String EVENT_ERR_MSG = "errMsg";
    public static final String EVENT_RESULT = "result";
    public static final String EVENT_REASON = "reason";
    public static final String EVENT_HOST_NAME = "hostName";
    public static final String EVENT_IPS = "ips";

    // subtitle data event
    // 回调 SubtitleData 事件id
    public static final int EVENT_SUBTITLE_DATA = 601;
    // subtitle data extra key
    // 回调 SubtitleData 事件对应的key
    public static final String EXTRA_SUBTITLE_DATA = "subtitleData";
    public static final String EXTRA_SUBTITLE_START_POSITION_MS = "startPositionMs";
    public static final String EXTRA_SUBTITLE_DURATION_MS = "durationMs";
    public static final String EXTRA_SUBTITLE_TRACK_INDEX = "trackIndex";
}
