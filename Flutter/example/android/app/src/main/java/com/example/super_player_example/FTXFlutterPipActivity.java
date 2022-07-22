// Copyright (c) 2022 Tencent. All rights reserved.
package com.example.super_player_example;

import android.app.PictureInPictureParams;
import android.app.PictureInPictureUiState;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.EventChannel;

/**
 * 画中画模式activity父类，使用画中画模式，需要将自己项目中的activity修改为继承该类
 */
public class FTXFlutterPipActivity extends FlutterActivity {
    private static final String PIP_CHANNEL_NAME                = "cloud.tencent.com/playerPlugin/pipEvent";
    private static final int    EVENT_PIP_MODE_ALREADY_ENTER    = 1;
    private static final int    EVENT_PIP_MODE_ALREADY_EXIT     = 2;
    private static final int    EVENT_PIP_MODE_REQUEST_START    = 3;
    private static final int    EVENT_PIP_MODE_UI_STATE_CHANGED = 4;

    private EventChannel           mPipEventChannel;
    private EventChannel.EventSink mEventSink;

    /**
     * 这里使用needToExitPip作为标志位，在出现onPictureInPictureModeChanged回调画中画状态和isInPictureInPictureMode不一致的时候。
     * 标志位true，然后在onConfigurationChanged监听到界面宽高发生变化的时候，进行画中画模式退出的事件通知。
     * for MIUI 12.5.1
     */
    private boolean needToExitPip = false;
    private int     configWidth   = 0;
    private int     configHeight  = 0;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initPipEventChannel();
    }

    private void initPipEventChannel() {
        if (null == mPipEventChannel && null != getFlutterEngine()) {
            mPipEventChannel = new EventChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(),
                    PIP_CHANNEL_NAME);
            mPipEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    mEventSink = events;
                }

                @Override
                public void onCancel(Object arguments) {
                }
            });
        }
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            boolean isInPictureInPictureMode = isInPictureInPictureMode();
            if (isInPictureInPictureMode) {
                configWidth = newConfig.screenWidthDp;
                configHeight = newConfig.screenHeightDp;
            } else if (needToExitPip && configWidth != newConfig.screenWidthDp && configHeight != newConfig.screenHeightDp) {
                if (null != mEventSink) {
                    mEventSink.success(getParams(EVENT_PIP_MODE_ALREADY_EXIT, null));
                }
                needToExitPip = false;
            }
        }
    }

    /**
     * 为了兼容MIUI 12.5，PIP模式下，打开其他app然后上滑退出，再点击画中画窗口，onPictureInPictureModeChanged会异常回调关闭的情况
     *
     * @param ignore 校对画中画状态
     */
    @Override
    public void onPictureInPictureModeChanged(boolean ignore) {
        boolean isInPictureInPictureMode = ignore;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            isInPictureInPictureMode = isInPictureInPictureMode();
        }
        if (isInPictureInPictureMode != ignore) {
            needToExitPip = true;
        } else {
            if (null != mEventSink) {
                if (isInPictureInPictureMode) {
                    mEventSink.success(getParams(EVENT_PIP_MODE_ALREADY_ENTER, null));
                } else {
                    mEventSink.success(getParams(EVENT_PIP_MODE_ALREADY_EXIT, null));
                }
            }
        }
        super.onPictureInPictureModeChanged(isInPictureInPictureMode);
    }

    @Override
    public void onPictureInPictureUiStateChanged(@NonNull PictureInPictureUiState pipState) {
        super.onPictureInPictureUiStateChanged(pipState);
        if (null != mEventSink) {
            mEventSink.success(getParams(EVENT_PIP_MODE_UI_STATE_CHANGED, null));
        }
    }

    /**
     * enterPictureInPictureMode生效后的回调通知，only for android > 31
     */
    @Override
    public boolean onPictureInPictureRequested() {
        return super.onPictureInPictureRequested();
    }

    @Override
    public boolean enterPictureInPictureMode(@NonNull PictureInPictureParams params) {
        boolean enterResult = super.enterPictureInPictureMode(params);
        if (enterResult && null != mEventSink) {
            mEventSink.success(getParams(EVENT_PIP_MODE_REQUEST_START, null));
        }
        return enterResult;
    }

    private Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap<>();
        if (event != 0) {
            param.put("event", event);
        }

        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }
        return param;
    }
}
