// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.app.Activity;
import android.app.AppOpsManager;
import android.app.PendingIntent;
import android.app.PictureInPictureParams;
import android.app.RemoteAction;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.RequiresApi;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * 画中画管理
 */
public class FTXPIPManager {
    private final static String TAG = "FTXPIPManager";

    private       boolean                   isRegisterReceiver = false;
    private final Map<Integer, PipCallback> pipCallbacks       = new HashMap<>();

    FTXAudioManager mTxAudioManager;
    private Activity                    mActivity;
    private FlutterPlugin.FlutterAssets mFlutterAssets;

    private final BroadcastReceiver pipActionReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Bundle data = intent.getExtras();
            if (null != data) {
                int controlCode = data.getInt(FTXEvent.EXTRA_NAME_PLAY_OP, -1);
                int playerId = data.getInt(FTXEvent.EXTRA_NAME_PLAYER_ID, -1);
                switch (controlCode) {
                    case FTXEvent.EXTRA_PIP_PLAY_BACK:
                        handlePlayBack(playerId);
                        break;
                    case FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE:
                        handleResumeOrPause(playerId);
                        break;
                    case FTXEvent.EXTRA_PIP_PLAY_FORWARD:
                        handlePlayForward(playerId);
                        break;
                }
            }
        }
    };

    /**
     * @param mTxAudioManager 音频管理，用于画中画模式下请求音频焦点
     * @param mActivity activity
     * @param flutterAssets flutter资源管理
     */
    public FTXPIPManager(FTXAudioManager mTxAudioManager,
                         Activity mActivity, FlutterPlugin.FlutterAssets flutterAssets) {
        this.mTxAudioManager = mTxAudioManager;
        this.mActivity = mActivity;
        this.mFlutterAssets = flutterAssets;
        initPipReceiver();
    }

    private void handlePlayBack(Integer playerId) {
        PipCallback pipCallback = pipCallbacks.get(playerId);
        if (null != pipCallback) {
            pipCallback.onPlayBack();
        }
    }

    private void handleResumeOrPause(Integer playerId) {
        PipCallback pipCallback = pipCallbacks.get(playerId);
        if (null != pipCallback) {
            pipCallback.onResumeOrPlay();
        }
    }

    private void handlePlayForward(Integer playerId) {
        PipCallback pipCallback = pipCallbacks.get(playerId);
        if (null != pipCallback) {
            pipCallback.onPlayForward();
        }
    }

    /**
     * 进入画中画模式
     *
     * @param isPlaying 当前视频是否处于播放状态
     * @return {@link FTXEvent} ERROR_PIP
     */
    public int enterPip(boolean isPlaying, PipParams params) {
        int pipResult = isSupportDevice();
        if (pipResult == FTXEvent.NO_ERROR) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    params.mPipParams = new PictureInPictureParams.Builder();
                    updatePipActions(isPlaying, params);
                    boolean enterResult = mActivity.enterPictureInPictureMode(params.mPipParams.build());
                    if(!enterResult) {
                        pipResult = FTXEvent.ERROR_PIP_DENIED_PERMISSION;
                    }
                } else {
                    mActivity.enterPictureInPictureMode();
                }
            }
        }
        return pipResult;
    }

    public int isSupportDevice() {
        int pipResult = FTXEvent.NO_ERROR;
        if (null != mActivity && !mActivity.isDestroyed()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // check permission
                boolean isSuccess =
                        mActivity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE);
                if (!isSuccess) {
                    pipResult = FTXEvent.ERROR_PIP_DENIED_PERMISSION;
                    Log.e(TAG, "enterPip failed,because PIP feature is disabled");
                } else if(!hasPipPermission()) {
                    pipResult = FTXEvent.ERROR_PIP_DENIED_PERMISSION;
                    Log.e(TAG, "enterPip failed,because PIP has no permission");
                }
            } else {
                pipResult = FTXEvent.ERROR_PIP_LOWER_VERSION;
                Log.e(TAG, "enterPip failed,because android version is too low,Minimum supported version is android " +
                        "24,but current is " + Build.VERSION.SDK_INT);
            }
        } else {
            pipResult = FTXEvent.ERROR_PIP_ACTIVITY_DESTROYED;
            Log.e(TAG, "enterPip failed,because activity is destroyed");
        }
        return pipResult;
    }

    private boolean hasPipPermission() {
        AppOpsManager appOpsManager = (AppOpsManager) mActivity.getSystemService(Context.APP_OPS_SERVICE);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            int permissionResult = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
                    android.os.Process.myUid(),mActivity.getPackageName());
            return permissionResult == AppOpsManager.MODE_ALLOWED;
        } else {
            return false;
        }
    }

    public boolean isInPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return mActivity.isInPictureInPictureMode();
        }
        return false;
    }

    /**
     * 设置pip控制回调，同一个播放器重复设置，会先后覆盖
     */
    public void addCallback(Integer playerId, PipCallback callback) {
        if (!pipCallbacks.containsValue(callback)) {
            pipCallbacks.put(playerId, callback);
        }
    }

    /**
     * 解注册广播，当退出页面的时候，必须调用，防止内存泄漏
     */
    public void releaseCallback(int playerId) {
        pipCallbacks.remove(playerId);
    }

    private void initPipReceiver() {
        if (!isRegisterReceiver) {
            IntentFilter pipIntentFilter = new IntentFilter(FTXEvent.ACTION_PIP_PLAY_CONTROL);
            mActivity.registerReceiver(pipActionReceiver, pipIntentFilter);
            isRegisterReceiver = true;
        }
    }

    public void releaseReceiver() {
        mActivity.unregisterReceiver(pipActionReceiver);
    }

    /**
     * 更新PIP悬浮框按钮
     *
     * @param isPlaying 是否正在播放
     */
    public void updatePipActions(boolean isPlaying, PipParams params) {
        if (null == params.mPipParams) {
            return;
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            List<RemoteAction> actions = new ArrayList<>();
            // play back
            if(params.mIsNeedPlayBack) {
                Bundle backData = new Bundle();
                backData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_BACK);
                backData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, params.mCurrentPlayerId);
                Intent backIntent = new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(backData);
                PendingIntent preIntent = PendingIntent.getBroadcast(mActivity, FTXEvent.EXTRA_PIP_PLAY_BACK, backIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction preAction = new RemoteAction(getBackIcon(params), "skipPre", "skip pre", preIntent);
                actions.add(preAction);
            }

            // resume or pause
            if(params.mIsNeedPlayControl) {
                Bundle playOrPauseData = new Bundle();
                playOrPauseData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, params.mCurrentPlayerId);
                playOrPauseData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE);
                Intent playOrPauseIntent =
                        new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(playOrPauseData);
                Icon playIcon = isPlaying ? getPauseIcon(params) : getPlayIcon(params);
                PendingIntent playIntent = PendingIntent.getBroadcast(mActivity, FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE,
                        playOrPauseIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction playOrPauseAction = new RemoteAction(playIcon, "playOrPause", "play Or Pause", playIntent);
                actions.add(playOrPauseAction);
            }

            // forward
            if(params.mIsNeedPlayForward) {
                Bundle forwardData = new Bundle();
                forwardData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_FORWARD);
                forwardData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, params.mCurrentPlayerId);
                Intent forwardIntent = new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(forwardData);
                PendingIntent nextIntent = PendingIntent.getBroadcast(mActivity, FTXEvent.EXTRA_PIP_PLAY_FORWARD,
                        forwardIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction nextAction = new RemoteAction(getForwardIcon(params), "skipNext", "skip next", nextIntent);
                actions.add(nextAction);
            }

            params.mPipParams.setActions(actions);
            mActivity.setPictureInPictureParams(params.mPipParams.build());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private Icon getBackIcon(PipParams params) {
        return getIcon(params.mPlayBackAssetPath, android.R.drawable.ic_media_previous);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private Icon getPlayIcon(PipParams params) {
        return getIcon(params.mPlayResumeAssetPath, android.R.drawable.ic_media_play);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private Icon getPauseIcon(PipParams params) {
        return getIcon(params.mPlayPauseAssetPath, android.R.drawable.ic_media_pause);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private Icon getForwardIcon(PipParams params) {
        return getIcon(params.mPlayForwardAssetPath, android.R.drawable.ic_media_next);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private Icon getIcon(String path, int defaultResId) {
        try {
            if (!TextUtils.isEmpty(path)) {
                String iconPath = mFlutterAssets.getAssetFilePathByName(path);
                Bitmap iconBitmap = BitmapFactory.decodeStream(mActivity.getAssets().open(iconPath));
                return Icon.createWithBitmap(iconBitmap);
            }
        } catch (IOException ignored) {
        }
        return Icon.createWithResource(mActivity, defaultResId);
    }

    static class PipParams {
        String mPlayBackAssetPath;
        String mPlayResumeAssetPath;
        String mPlayPauseAssetPath;
        String mPlayForwardAssetPath;
        int    mCurrentPlayerId;
        protected PictureInPictureParams.Builder mPipParams;
        private   boolean                        mIsNeedPlayBack    = true;
        private   boolean                        mIsNeedPlayForward = true;
        private   boolean                        mIsNeedPlayControl = true;

        /**
         * @param mPlayBackAssetPath 回退按钮图片资源路径，传空则使用系统默认图标
         * @param mPlayResumeAssetPath 播放按钮图片资源路径，传空则使用系统默认图标
         * @param mPlayPauseAssetPath 暂停按钮图片资源路径，传空则使用系统默认图标
         * @param mPlayForwardAssetPath 前进按钮图片资源路径，传空则使用系统默认图标
         * @param mCurrentPlayerId 播放器id
         */
        public PipParams(String mPlayBackAssetPath, String mPlayResumeAssetPath, String mPlayPauseAssetPath,
                         String mPlayForwardAssetPath, int mCurrentPlayerId) {
            this(mPlayBackAssetPath, mPlayResumeAssetPath, mPlayPauseAssetPath, mPlayForwardAssetPath,
                    mCurrentPlayerId, true, true, true);
        }

        public PipParams(String mPlayBackAssetPath, String mPlayResumeAssetPath, String mPlayPauseAssetPath,
                         String mPlayForwardAssetPath, int mCurrentPlayerId, boolean isNeedPlayBack,
                         boolean isNeedPlayForward, boolean isNeedPlayControl) {
            this.mPlayBackAssetPath = mPlayBackAssetPath;
            this.mPlayResumeAssetPath = mPlayResumeAssetPath;
            this.mPlayPauseAssetPath = mPlayPauseAssetPath;
            this.mPlayForwardAssetPath = mPlayForwardAssetPath;
            this.mCurrentPlayerId = mCurrentPlayerId;
            this.mIsNeedPlayBack = isNeedPlayBack;
            this.mIsNeedPlayForward = isNeedPlayForward;
            this.mIsNeedPlayControl = isNeedPlayControl;
        }
    }

    /**
     * 画中画控制回调
     */
    interface PipCallback {
        /**
         * 回退
         */
        void onPlayBack();

        /**
         * 继续/暂停
         */
        void onResumeOrPlay();

        /**
         * 前进
         */
        void onPlayForward();
    }
}
