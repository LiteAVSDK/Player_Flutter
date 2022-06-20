// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

/**
 * 通用事件码
 */
public class FTXEvent {
    /*
    音量变化
     */
    public static final int EVENT_VOLUME_CHANGED = 0x01;
    /*
    失去音量输出播放焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PAUSE = 0x02;
    /*
    获得音量输出焦点
     */
    public static final int EVENT_AUDIO_FOCUS_PLAY = 0x03;
}
