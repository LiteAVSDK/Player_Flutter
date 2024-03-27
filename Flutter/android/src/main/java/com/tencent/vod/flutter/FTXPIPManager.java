// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.app.Activity;
import android.app.AppOpsManager;
import android.app.PendingIntent;
import android.app.PictureInPictureParams;
import android.app.PictureInPictureParams.Builder;
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
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.os.Parcel;
import android.os.Parcelable;
import android.text.TextUtils;
import android.util.Log;
import android.util.Rational;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXVideoModel;
import com.tencent.vod.flutter.tools.TXCommonUtil;
import com.tencent.vod.flutter.ui.FlutterPipImplActivity;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;

/**
 * Picture-in-picture management.
 *
 * 画中画管理
 */
public class FTXPIPManager {

    private static final String TAG = "FTXPIPManager";

    private boolean misInit = false;
    private final Map<Integer, PipCallback> pipCallbacks = new HashMap<>();

    FTXAudioManager mTxAudioManager;
    private ActivityPluginBinding mActivityBinding;
    private final FlutterPlugin.FlutterAssets mFlutterAssets;
    private final EventChannel mPipEventChannel;
    private final FTXPlayerEventSink mPipEventSink = new FTXPlayerEventSink();
    private boolean mIsInPipMode = false;
    private final BroadcastReceiver mPipBroadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (null != intent) {
                int playerId = intent.getIntExtra(FTXEvent.EXTRA_NAME_PLAYER_ID, -1);
                int pipEventId = intent.getIntExtra(FTXEvent.EVENT_PIP_MODE_NAME, -1);
                Bundle callbackData = new Bundle();
                Bundle data = intent.getExtras();
                if ((pipEventId == FTXEvent.EVENT_PIP_MODE_ALREADY_EXIT
                        || pipEventId == FTXEvent.EVENT_PIP_MODE_RESTORE_UI) && null != data) {
                    TXPipResult pipResult = data.getParcelable(FTXEvent.EXTRA_NAME_RESULT);
                    if (null != pipResult) {
                        callbackData.putDouble(FTXEvent.EVENT_PIP_PLAY_TIME, pipResult.getPlayTime());
                        handlePipResult(pipResult);
                    }
                }
                mPipEventSink.success(TXCommonUtil.getParams(pipEventId, callbackData));
            }
        }
    };

    /**
     * Picture-in-picture management.
     *
     * 画中画管理
     * @param mTxAudioManager Audio management, used to request audio focus in picture-in-picture mode.
     *                        音频管理，用于画中画模式下请求音频焦点
     * @param activityBinding activityBinding
     * @param flutterAssets Flutter resource management.
     *                      flutter资源管理
     */
    public FTXPIPManager(FTXAudioManager mTxAudioManager, @NonNull EventChannel pipEventChannel,
            ActivityPluginBinding activityBinding, FlutterPlugin.FlutterAssets flutterAssets) {
        this.mTxAudioManager = mTxAudioManager;
        this.mPipEventChannel = pipEventChannel;
        this.mActivityBinding = activityBinding;
        this.mFlutterAssets = flutterAssets;
        registerActivityListener();
        initPipEventChannel();
    }

    private void initPipEventChannel() {
        if (null != mPipEventChannel) {
            mPipEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    mPipEventSink.setEventSinkProxy(events);
                }

                @Override
                public void onCancel(Object arguments) {
                    mPipEventSink.setEventSinkProxy(null);
                }
            });
        }
    }

    /**
     * Register `activityResult` callback, <h1>must be called</h1>.
     *
     * 注册activityResult回调，<h1>必须调用</h1>
     */
    public void registerActivityListener() {
        if (!mActivityBinding.getActivity().isDestroyed() && !misInit) {
            IntentFilter intentFilter = new IntentFilter();
            intentFilter.addAction(FTXEvent.EVENT_PIP_ACTION);
            mActivityBinding.getActivity().registerReceiver(mPipBroadcastReceiver, intentFilter);
            misInit = true;
        }
    }

    private void handlePipResult(TXPipResult result) {
        PipCallback pipCallback = pipCallbacks.get(result.getPlayerId());
        if (null != pipCallback) {
            pipCallback.onPipResult(result);
        }
    }

    /**
     * Enter picture-in-picture mode.
     *
     * 进入画中画模式
     *
     * @return {@link FTXEvent} ERROR_PIP
     */
    public int enterPip(PipParams params, TXVideoModel videoModel) {
        int pipResult = isSupportDevice();
        if (pipResult == FTXEvent.NO_ERROR) {
            mPipEventSink.success(TXCommonUtil.getParams(FTXEvent.EVENT_PIP_MODE_REQUEST_START, null));
            Intent intent = new Intent(mActivityBinding.getActivity(), FlutterPipImplActivity.class);
            intent.setAction(FTXEvent.PIP_ACTION_START);
            intent.putExtra(FTXEvent.EXTRA_NAME_PARAMS, params);
            intent.putExtra(FTXEvent.EXTRA_NAME_VIDEO, videoModel);
            mActivityBinding.getActivity().startActivity(intent);
            mIsInPipMode = true;
        }
        return pipResult;
    }

    /**
     * Notify to exit the current picture-in-picture mode.
     *
     * 通知退出当前pip
     */
    public void exitPip() {
        if (mIsInPipMode) {
            Intent intent = new Intent(mActivityBinding.getActivity(), FlutterPipImplActivity.class);
            intent.setAction(FTXEvent.PIP_ACTION_EXIT);
            mActivityBinding.getActivity().startActivity(intent);
            mIsInPipMode = false;
        }
    }

    /**
     * Whether the device supports picture-in-picture mode.
     *
     * 设备是否支持画中画
     */
    public int isSupportDevice() {
        int pipResult = FTXEvent.NO_ERROR;
        Activity activity = mActivityBinding.getActivity();
        if (!activity.isDestroyed()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // check permission
                boolean isSuccess =
                        activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE);
                if (!isSuccess) {
                    pipResult = FTXEvent.ERROR_PIP_DENIED_PERMISSION;
                    Log.e(TAG, "enterPip failed,because PIP feature is disabled");
                } else if (!hasPipPermission(activity)) {
                    pipResult = FTXEvent.ERROR_PIP_DENIED_PERMISSION;
                    Log.e(TAG, "enterPip failed,because PIP has no permission");
                }
            } else {
                pipResult = FTXEvent.ERROR_PIP_LOWER_VERSION;
                Log.e(TAG, "enterPip failed,because android version is too low,Minimum supported version is android "
                        + "24,but current is " + Build.VERSION.SDK_INT);
            }
        } else {
            pipResult = FTXEvent.ERROR_PIP_ACTIVITY_DESTROYED;
            Log.e(TAG, "enterPip failed,because activity is destroyed");
        }
        return pipResult;
    }

    private boolean hasPipPermission(Activity activity) {
        AppOpsManager appOpsManager = (AppOpsManager) activity.getSystemService(Context.APP_OPS_SERVICE);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            int permissionResult = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_PICTURE_IN_PICTURE,
                    android.os.Process.myUid(), activity.getPackageName());
            return permissionResult == AppOpsManager.MODE_ALLOWED;
        } else {
            return false;
        }
    }

    public boolean isInPipMode() {
        return mIsInPipMode;
    }

    /**
     * Set the PIP control callback. If set repeatedly for the same player, it will be overwritten successively.
     *
     * 设置pip控制回调，同一个播放器重复设置，会先后覆盖
     */
    public void addCallback(Integer playerId, PipCallback callback) {
        if (!pipCallbacks.containsValue(callback)) {
            pipCallbacks.put(playerId, callback);
        }
    }

    /**
     * Unregister the broadcast receiver. It must be called when exiting the page to prevent memory leaks.
     *
     * 解注册广播，当退出页面的时候，必须调用，防止内存泄漏
     */
    public void releaseCallback(int playerId) {
        pipCallbacks.remove(playerId);
    }

    public void releaseActivityListener() {
        try {
            if (misInit) {
                mActivityBinding.getActivity().unregisterReceiver(mPipBroadcastReceiver);
            }
        } catch (Exception e) {
            Log.getStackTraceString(e);
        }
    }

    /**
     * Update the PIP floating window button.
     *
     * 更新PIP悬浮框按钮
     */
    public void updatePipActions(PipParams params) {
        Intent intent = new Intent(mActivityBinding.getActivity(), FlutterPipImplActivity.class);
        intent.setAction(FTXEvent.PIP_ACTION_UPDATE);
        intent.putExtra(FTXEvent.EXTRA_NAME_PARAMS, params);
        mActivityBinding.getActivity().startActivity(intent);
    }

    public String toAndroidPath(String path) {
        if (TextUtils.isEmpty(path)) {
            return path;
        }
        return mFlutterAssets.getAssetFilePathByName(path);
    }


    public static class PipParams implements Parcelable {

        private final String mPlayBackAssetPath;
        private final String mPlayResumeAssetPath;
        private final String mPlayPauseAssetPath;
        private final String mPlayForwardAssetPath;
        private final int mCurrentPlayerId;
        private final boolean mIsNeedPlayBack;
        private final boolean mIsNeedPlayForward;
        private final boolean mIsNeedPlayControl;
        private boolean mIsPlaying = false;
        private float mCurrentPlayTime = 0;
        private int mViewWith = 16;
        private int mViewHeight = 9;

        /**
         * PIP parameters.
         * 画中画参数
         * @param mPlayBackAssetPath Back button image resource path. If empty, the default system icon will be used.
         *                           The address must be converted with toAndroidPath.
         *                           回退按钮图片资源路径，传空则使用系统默认图标, 地址必须经过toAndroidPath转换
         * @param mPlayResumeAssetPath Play button image resource path. If empty, the default system icon will be used.
         *                            The address must be converted with toAndroidPath.
         *                             播放按钮图片资源路径，传空则使用系统默认图标, 地址必须经过toAndroidPath转换
         * @param mPlayPauseAssetPath Pause button image resource path. If empty, the default system icon will be used.
         *                           The address must be converted with toAndroidPath.
         *                            暂停按钮图片资源路径，传空则使用系统默认图标, 地址必须经过toAndroidPath转换
         * @param mPlayForwardAssetPath Forward button image resource path. If empty, the default system icon will
         *                              be used. The address must be converted with toAndroidPath.
         *                              前进按钮图片资源路径，传空则使用系统默认图标, 地址必须经过toAndroidPath转换
         * @param mCurrentPlayerId Player ID.
         *                         播放器id
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

        protected PipParams(Parcel in) {
            mPlayBackAssetPath = in.readString();
            mPlayResumeAssetPath = in.readString();
            mPlayPauseAssetPath = in.readString();
            mPlayForwardAssetPath = in.readString();
            mCurrentPlayerId = in.readInt();
            mIsNeedPlayBack = in.readByte() != 0;
            mIsNeedPlayForward = in.readByte() != 0;
            mIsNeedPlayControl = in.readByte() != 0;
            mIsPlaying = in.readByte() != 0;
            mCurrentPlayTime = in.readFloat();
        }

        public static final Creator<PipParams> CREATOR = new Creator<PipParams>() {
            @Override
            public PipParams createFromParcel(Parcel in) {
                return new PipParams(in);
            }

            @Override
            public PipParams[] newArray(int size) {
                return new PipParams[size];
            }
        };

        public void setIsPlaying(boolean isPlay) {
            this.mIsPlaying = isPlay;
        }

        public boolean isPlaying() {
            return mIsPlaying;
        }

        public int getCurrentPlayerId() {
            return mCurrentPlayerId;
        }

        public float getCurrentPlayTime() {
            return mCurrentPlayTime;
        }

        public void setCurrentPlayTime(float mCurrentPlayTime) {
            this.mCurrentPlayTime = mCurrentPlayTime;
        }

        public void setRadio(int width, int height) {
            mViewWith = width;
            mViewHeight = height;
        }

        public int geiRadioWith() {
            return mViewWith;
        }

        public int getRadioHeight() {
            return mViewHeight;
        }

        /**
         * Construct PIP parameters.
         * 构造画中画参数
         */
        @RequiresApi(api = VERSION_CODES.O)
        public PictureInPictureParams buildParams(Activity activity) {
            List<RemoteAction> actions = new ArrayList<>();
            // play back
            if (mIsNeedPlayBack) {
                Bundle backData = new Bundle();
                backData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_BACK);
                backData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentPlayerId);
                Intent backIntent = new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(backData);
                PendingIntent preIntent = PendingIntent.getBroadcast(activity, FTXEvent.EXTRA_PIP_PLAY_BACK, backIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction preAction = new RemoteAction(getBackIcon(activity), "skipPre", "skip pre", preIntent);
                actions.add(preAction);
            }

            // resume or pause
            if (mIsNeedPlayControl) {
                Bundle playOrPauseData = new Bundle();
                playOrPauseData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentPlayerId);
                playOrPauseData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE);
                Intent playOrPauseIntent =
                        new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(playOrPauseData);
                Icon playIcon = mIsPlaying ? getPauseIcon(activity) : getPlayIcon(activity);
                PendingIntent playIntent = PendingIntent.getBroadcast(activity, FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE,
                        playOrPauseIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction playOrPauseAction = new RemoteAction(playIcon, "playOrPause", "play Or Pause", playIntent);
                actions.add(playOrPauseAction);
            }

            // forward
            if (mIsNeedPlayForward) {
                Bundle forwardData = new Bundle();
                forwardData.putInt(FTXEvent.EXTRA_NAME_PLAY_OP, FTXEvent.EXTRA_PIP_PLAY_FORWARD);
                forwardData.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentPlayerId);
                Intent forwardIntent = new Intent(FTXEvent.ACTION_PIP_PLAY_CONTROL).putExtras(forwardData);
                PendingIntent nextIntent = PendingIntent.getBroadcast(activity, FTXEvent.EXTRA_PIP_PLAY_FORWARD,
                        forwardIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                RemoteAction nextAction = new RemoteAction(getForwardIcon(activity), "skipNext", "skip next",
                        nextIntent);
                actions.add(nextAction);
            }

            Builder mPipParams = new Builder();
            mPipParams.setActions(actions);
            mPipParams.setAspectRatio(new Rational(mViewWith, mViewHeight));
            if (Build.VERSION.SDK_INT >= VERSION_CODES.S) {
                mPipParams.setAutoEnterEnabled(false);
                mPipParams.setSeamlessResizeEnabled(false);
            }
            return mPipParams.build();
        }

        @RequiresApi(api = Build.VERSION_CODES.M)
        private Icon getBackIcon(Activity activity) {
            return getIcon(activity, mPlayBackAssetPath, android.R.drawable.ic_media_previous);
        }

        @RequiresApi(api = Build.VERSION_CODES.M)
        private Icon getPlayIcon(Activity activity) {
            return getIcon(activity, mPlayResumeAssetPath, android.R.drawable.ic_media_play);
        }

        @RequiresApi(api = Build.VERSION_CODES.M)
        private Icon getPauseIcon(Activity activity) {
            return getIcon(activity, mPlayPauseAssetPath, android.R.drawable.ic_media_pause);
        }

        @RequiresApi(api = Build.VERSION_CODES.M)
        private Icon getForwardIcon(Activity activity) {
            return getIcon(activity, mPlayForwardAssetPath, android.R.drawable.ic_media_next);
        }

        @RequiresApi(api = Build.VERSION_CODES.M)
        private Icon getIcon(Activity activity, String path, int defaultResId) {
            try {
                if (!TextUtils.isEmpty(path)) {
                    Bitmap iconBitmap = BitmapFactory.decodeStream(activity.getAssets().open(path));
                    return Icon.createWithBitmap(iconBitmap);
                }
            } catch (IOException e) {
                Log.getStackTraceString(e);
            }
            return Icon.createWithResource(activity, defaultResId);
        }

        @Override
        public int describeContents() {
            return 0;
        }

        @Override
        public void writeToParcel(Parcel dest, int flags) {
            dest.writeString(mPlayBackAssetPath);
            dest.writeString(mPlayResumeAssetPath);
            dest.writeString(mPlayPauseAssetPath);
            dest.writeString(mPlayForwardAssetPath);
            dest.writeInt(mCurrentPlayerId);
            dest.writeByte((byte) (mIsNeedPlayBack ? 1 : 0));
            dest.writeByte((byte) (mIsNeedPlayForward ? 1 : 0));
            dest.writeByte((byte) (mIsNeedPlayControl ? 1 : 0));
            dest.writeByte((byte) (mIsPlaying ? 1 : 0));
            dest.writeFloat(mCurrentPlayTime);
        }
    }

    /**
     * PIP control callback.
     * 画中画控制回调
     */
    interface PipCallback {

        /**
         * Close PIP.
         * pip关闭
         */
        void onPipResult(TXPipResult result);
    }
}
