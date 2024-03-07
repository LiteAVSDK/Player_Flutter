// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.ui;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.PictureInPictureParams;
import android.app.PictureInPictureUiState;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.text.TextUtils;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceHolder.Callback;
import android.view.SurfaceView;
import android.view.View;
import android.widget.ProgressBar;

import androidx.annotation.NonNull;

import com.tencent.rtmp.ITXLivePlayListener;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXPlayInfoParams;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.FTXPIPManager.PipParams;
import com.tencent.vod.flutter.R;
import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXVideoModel;

import java.util.List;
import java.util.Set;

public class FlutterPipImplActivity extends Activity implements Callback, ITXVodPlayListener,
        ITXLivePlayListener, ServiceConnection {

    private static final String TAG = "FlutterPipImplActivity";

    /**
     * Here, `needToExitPip` is used as a flag. When the `onPictureInPictureModeChanged` callback picture-in-picture
     * state is inconsistent with `isInPictureInPictureMode`, mark it as true. Then, when the width and height of the
     * interface change are detected in `onConfigurationChanged`, the event notification of exiting
     * picture-in-picture mode is performed.
     * for MIUI 12.5.1.
     *
     * 这里使用needToExitPip作为标志位，在出现onPictureInPictureModeChanged回调画中画状态和isInPictureInPictureMode不一致的时候。
     * 标记为true，然后在onConfigurationChanged监听到界面宽高发生变化的时候，进行画中画模式退出的事件通知。
     * for MIUI 12.5.1
     */
    private boolean needToExitPip = false;
    private int configWidth = 0;
    private int configHeight = 0;

    private SurfaceView mVideoSurface;
    private ProgressBar mVideoProgress;

    private TXVodPlayer mVodPlayer;
    private TXLivePlayer mLivePlayer;
    private boolean mIsSurfaceCreated = false;
    // In picture-in-picture mode, clicking the X in the upper right corner will trigger `onStop` first.
    // Clicking the zoom button will not trigger `onStop`.
    private boolean mIsNeedToStop = false;
    private TXVideoModel mVideoModel;
    private boolean mIsRegisterReceiver = false;
    private PipParams mCurrentParams;
    private Handler mMainHandler;

    private final BroadcastReceiver pipActionReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Bundle data = intent.getExtras();
            if (null != data && null != mCurrentParams) {
                int playerId = data.getInt(FTXEvent.EXTRA_NAME_PLAYER_ID, -1);
                if (playerId == mCurrentParams.getCurrentPlayerId()) {
                    int controlCode = data.getInt(FTXEvent.EXTRA_NAME_PLAY_OP, -1);
                    switch (controlCode) {
                        case FTXEvent.EXTRA_PIP_PLAY_BACK:
                            handlePlayBack();
                            break;
                        case FTXEvent.EXTRA_PIP_PLAY_RESUME_OR_PAUSE:
                            handleResumeOrPause();
                            break;
                        case FTXEvent.EXTRA_PIP_PLAY_FORWARD:
                            handlePlayForward();
                            break;
                        default:
                            Log.e(TAG, "unknown control code");
                            break;
                    }
                }
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mMainHandler = new Handler(getMainLooper());
        bindAndroid12BugServiceIfNeed();
        registerPipBroadcast();
        setContentView(R.layout.activity_flutter_pip_impl);
        mVodPlayer = new TXVodPlayer(this);
        mLivePlayer = new TXLivePlayer(this);
        mVideoSurface = findViewById(R.id.sv_video_container);
        mVideoProgress = findViewById(R.id.pb_video_progress);
        mVideoSurface.getHolder().addCallback(this);
        Intent intent = getIntent();
        PipParams params = intent.getParcelableExtra(FTXEvent.EXTRA_NAME_PARAMS);
        if (null == params) {
            Log.e(TAG, "lack pip params,please check the intent argument");
            finish();
        } else {
            mCurrentParams = params;
            if (VERSION.SDK_INT >= VERSION_CODES.O) {
                configPipMode(params.buildParams(this));
            } else {
                configPipMode(null);
            }
        }
        setVodPlayerListener();
        setLivePlayerListener();
        handleIntent(intent);
    }

    private void setVodPlayerListener() {
        // set default config
        mVodPlayer.setConfig(new TXVodPlayConfig());
        mVodPlayer.setVodListener(this);
    }

    private void setLivePlayerListener() {
        mLivePlayer.setPlayListener(this);
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            boolean isInPictureInPictureMode = isInPictureInPictureMode();
            if (isInPictureInPictureMode) {
                configWidth = newConfig.screenWidthDp;
                configHeight = newConfig.screenHeightDp;
            } else if (needToExitPip && configWidth != newConfig.screenWidthDp
                    && configHeight != newConfig.screenHeightDp) {
                handlePipExitEvent();
                needToExitPip = false;
            }
        }
    }

    /**
     * To be compatible with MIUI 12.5, in PIP mode, if you open another app and then swipe up to exit,
     * and then click the PIP window, `onPictureInPictureModeChanged` will be abnormally called back to close.
     *
     * 为了兼容MIUI 12.5，PIP模式下，打开其他app然后上滑退出，再点击画中画窗口，onPictureInPictureModeChanged会异常回调关闭的情况
     *
     * @param ignore 校对画中画状态 Verify picture-in-picture status.
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
            if (isInPictureInPictureMode) {
                sendPipBroadCast(FTXEvent.EVENT_PIP_MODE_ALREADY_ENTER, null);
                showComponent();
            } else {
                handlePipExitEvent();
            }
        }
        super.onPictureInPictureModeChanged(isInPictureInPictureMode);
    }

    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
    }

    @Override
    public void onPictureInPictureUiStateChanged(@NonNull PictureInPictureUiState pipState) {
        super.onPictureInPictureUiStateChanged(pipState);
        sendPipBroadCast(FTXEvent.EVENT_PIP_MODE_UI_STATE_CHANGED, null);
    }

    /**
     * Callback notification after `enterPictureInPictureMode` takes effect, only for Android > 31.
     *
     * enterPictureInPictureMode生效后的回调通知，only for android > 31
     */
    @Override
    public boolean onPictureInPictureRequested() {
        return super.onPictureInPictureRequested();
    }

    @Override
    public boolean enterPictureInPictureMode(@NonNull PictureInPictureParams params) {
        return super.enterPictureInPictureMode(params);
    }

    private void configPipMode(PictureInPictureParams params) {
        mVideoSurface.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (VERSION.SDK_INT >= VERSION_CODES.N) {
                    if (VERSION.SDK_INT >= VERSION_CODES.O) {
                        enterPictureInPictureMode(params);
                    } else {
                        enterPictureInPictureMode();
                    }
                }
            }
        }, 200);
    }

    private void registerPipBroadcast() {
        if (!mIsRegisterReceiver) {
            IntentFilter pipIntentFilter = new IntentFilter(FTXEvent.ACTION_PIP_PLAY_CONTROL);
            registerReceiver(pipActionReceiver, pipIntentFilter);
            mIsRegisterReceiver = true;
        }
    }

    private void unRegisterPipBroadcast() {
        if (mIsRegisterReceiver) {
            unregisterReceiver(pipActionReceiver);
        }
    }

    private void handlePipExitEvent() {
        Bundle data = new Bundle();
        TXPipResult pipResult = new TXPipResult();
        if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_VOD) {
            Float currentPlayTime = mVodPlayer.getCurrentPlaybackTime();
            pipResult.setPlayTime(currentPlayTime);
            pipResult.setPlaying(mVodPlayer.isPlaying());
            pipResult.setPlayerId(mCurrentParams.getCurrentPlayerId());
            data.putParcelable(FTXEvent.EXTRA_NAME_RESULT, pipResult);
        } else if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_LIVE) {
            pipResult.setPlaying(mLivePlayer.isPlaying());
            pipResult.setPlayerId(mCurrentParams.getCurrentPlayerId());
            data.putParcelable(FTXEvent.EXTRA_NAME_RESULT, pipResult);
        }
        int codeEvent = mIsNeedToStop ? FTXEvent.EVENT_PIP_MODE_ALREADY_EXIT : FTXEvent.EVENT_PIP_MODE_RESTORE_UI;
        sendPipBroadCast(codeEvent, data);
        exitPip(codeEvent == FTXEvent.EVENT_PIP_MODE_ALREADY_EXIT);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null) {
            String action = intent.getAction();
            if (TextUtils.equals(action, FTXEvent.PIP_ACTION_START)) {
                startPipVideoFromIntent(intent);
            } else if (TextUtils.equals(action, FTXEvent.PIP_ACTION_EXIT)) {
                exitPip(false);
            } else if (TextUtils.equals(action, FTXEvent.PIP_ACTION_UPDATE)) {
                PipParams pipParams = intent.getParcelableExtra(FTXEvent.EXTRA_NAME_PARAMS);
                updatePip(pipParams);
            } else {
                Log.e(TAG, "unknown pip action:" + action);
            }
        }
    }

    private void updatePip(PipParams pipParams) {
        if (null != pipParams) {
            mCurrentParams = pipParams;
            if (VERSION.SDK_INT >= VERSION_CODES.O) {
                setPictureInPictureParams(pipParams.buildParams(this));
            }
        }
    }

    /**
     * move task to from。Prevent the issue of picture-in-picture windows failing to launch the app in certain cases.
     */
    public void moveAppToFront() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return;
        }
        ActivityManager activityManager =
                (ActivityManager) getApplicationContext().getSystemService(Context.ACTIVITY_SERVICE);
        final List<ActivityManager.AppTask> appTasks = activityManager.getAppTasks();
        for (ActivityManager.AppTask task : appTasks) {
            final Intent baseIntent = task.getTaskInfo().baseIntent;
            final Set<String> categories = baseIntent.getCategories();
            if (categories != null && categories.contains(Intent.CATEGORY_LAUNCHER)) {
                task.moveToFront();
                return;
            }
        }
    }

    /**
     * Close picture-in-picture mode by using `finish` to close the current interface.
     *
     * 关闭画中画，使用finish当前界面的方式，关闭画中画
     *
     * @param closeImmediately 立刻关闭，不执行延迟，一般关闭画中画为true，还原画中画为false。
     *                         Close immediately without delay. Generally, set it to `true` to close picture-in-picture
     *                         mode and `false` to restore picture-in-picture mode.
     */
    private void exitPip(boolean closeImmediately) {
        if (!isDestroyed()) {
            // Due to the foreground service startup restriction in Android 12, if the activity interface is closed
            // too early after returning from picture-in-picture mode, the app cannot be launched normally.
            // Therefore, a delay processing is added here.
            if (VERSION.SDK_INT >= VERSION_CODES.S && !closeImmediately) {
                mVodPlayer.stopPlay(true);
                mLivePlayer.stopPlay(true);
                mVideoSurface.setVisibility(View.GONE);
                mVideoProgress.setVisibility(View.GONE);
                mMainHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        overridePendingTransition(0, 0);
                        finishAndRemoveTask();
                    }
                }, 400);
            } else {
                overridePendingTransition(0, 0);
                if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
                    finishAndRemoveTask();
                } else {
                    finish();
                }
            }
        }
        if (closeImmediately) {
            moveAppToFront();
        }
    }

    private void startPipVideoFromIntent(Intent intent) {
        mVideoModel = (TXVideoModel) intent.getParcelableExtra(FTXEvent.EXTRA_NAME_VIDEO);
        if (mIsSurfaceCreated) {
            attachSurface(mVideoSurface.getHolder().getSurface());
            startPlay();
        }
    }

    private void startPlay() {
        if (null != mVideoModel) {
            float playTime = mCurrentParams.getCurrentPlayTime();
            boolean isPlaying = mCurrentParams.isPlaying();
            if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_VOD) {
                mVodPlayer.setStartTime(playTime);
                mVodPlayer.setAutoPlay(isPlaying);
                mVodPlayer.setToken(mVideoModel.getToken());
                if (!TextUtils.isEmpty(mVideoModel.getVideoUrl())) {
                    mVodPlayer.startVodPlay(mVideoModel.getVideoUrl());
                } else if (!TextUtils.isEmpty(mVideoModel.getFileId())) {
                    mVodPlayer.startVodPlay(
                            new TXPlayInfoParams(mVideoModel.getAppId(), mVideoModel.getFileId(),
                                    mVideoModel.getPSign()));
                }
            } else if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_LIVE) {
                mVideoProgress.setProgress(mVideoProgress.getMax());
                mLivePlayer.startLivePlay(mVideoModel.getVideoUrl(), mVideoModel.getLiveType());
                //  Live broadcast does not currently support picture-in-picture mode and
                //  pausing the live broadcast when entering picture-in-picture mode.
                mCurrentParams.setIsPlaying(true);
                if (VERSION.SDK_INT >= VERSION_CODES.O) {
                    setPictureInPictureParams(mCurrentParams.buildParams(this));
                }
            }
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        mIsSurfaceCreated = true;
        holder.setFormat(PixelFormat.TRANSLUCENT);
        attachSurface(holder.getSurface());
        startPlay();
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        mVodPlayer.setSurface(null);
        mLivePlayer.setSurface(null);
        mIsSurfaceCreated = false;
    }

    @Override
    protected void onStop() {
        super.onStop();
        mVodPlayer.stopPlay(true);
        mLivePlayer.stopPlay(true);
        mIsNeedToStop = true;
    }

    @Override
    protected void onResume() {
        super.onResume();
        mIsNeedToStop = false;
    }

    @Override
    protected void onDestroy() {
        unRegisterPipBroadcast();
        if (Build.VERSION.SDK_INT >= VERSION_CODES.S) {
            unbindService(this);
        }
        super.onDestroy();
    }


    private void bindAndroid12BugServiceIfNeed() {
        if (Build.VERSION.SDK_INT >= VERSION_CODES.S) {
            Intent serviceIntent = new Intent(this, TXAndroid12BridgeService.class);
            startService(serviceIntent);
            bindService(serviceIntent, this, Context.BIND_AUTO_CREATE);
        }
    }

    private void attachSurface(Surface surface) {
        if (null != mVideoModel) {
            if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_VOD) {
                mVodPlayer.setSurface(surface);
            } else if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_LIVE) {
                mLivePlayer.setSurface(surface);
            } else {
                Log.e(TAG, "unknown player type:" + mVideoModel.getPlayerType());
            }
        } else {
            Log.e(TAG, "pip video model is null");
        }
    }

    private void handlePlayBack() {
        if (mVodPlayer.isPlaying()) {
            float backPlayTime = mVodPlayer.getCurrentPlaybackTime() - 10;
            if (backPlayTime < 0) {
                backPlayTime = 0;
            }
            mVodPlayer.seek(backPlayTime);
        }
    }

    private void handleResumeOrPause() {
        boolean dstPlaying = !mVodPlayer.isPlaying();
        if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_VOD) {
            if (dstPlaying) {
                mVodPlayer.resume();
            } else {
                mVodPlayer.pause();
            }
        } else if (mVideoModel.getPlayerType() == FTXEvent.PLAYER_LIVE) {
            if (dstPlaying) {
                mLivePlayer.resume();
            } else {
                mLivePlayer.pause();
            }
        }
        mCurrentParams.setIsPlaying(dstPlaying);
        updatePip(mCurrentParams);
    }

    private void handlePlayForward() {
        if (mVodPlayer.isPlaying()) {
            float forwardPlayTime = mVodPlayer.getCurrentPlaybackTime() + 10;
            float duration = mVodPlayer.getDuration();
            if (forwardPlayTime > duration) {
                forwardPlayTime = duration;
            }
            mVodPlayer.seek(forwardPlayTime);
        }
    }

    private void sendPipBroadCast(int eventCode, Bundle data) {
        Intent intent = new Intent();
        intent.setAction(FTXEvent.EVENT_PIP_ACTION);
        intent.putExtra(FTXEvent.EVENT_PIP_MODE_NAME, eventCode);
        intent.putExtra(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentParams.getCurrentPlayerId());
        if (null != data) {
            intent.putExtras(data);
        }
        sendBroadcast(intent);
    }

    /**
     * Display component.
     * To prevent the black screen at the moment when picture-in-picture is started,
     * the component is initially in a hidden state, and the component will only be displayed
     * after entering picture-in-picture mode.
     *
     * 显示组件
     * 为了防止画中画启动一瞬间的黑屏，组件一开始为隐藏状态，只有进入画中画之后才会显示组件
     */
    private void showComponent() {
        mVideoSurface.setVisibility(View.VISIBLE);
        mVideoProgress.setVisibility(View.VISIBLE);
    }

    private void controlPipPlayStatus(boolean isPlaying) {
        if (null != mCurrentParams) {
            mCurrentParams.setIsPlaying(isPlaying);
            updatePip(mCurrentParams);
        }
    }

    @Override
    public void onPlayEvent(TXVodPlayer txVodPlayer, int event, Bundle bundle) {
        if (VERSION.SDK_INT >= VERSION_CODES.N && isInPictureInPictureMode()) {
            if (null != mCurrentParams) {
                if (event == TXLiveConstants.PLAY_EVT_PLAY_END) {
                    // When playback is complete, automatically set the playback button to play.
                    mCurrentParams.setIsPlaying(false);
                } else if (event == TXLiveConstants.PLAY_EVT_PLAY_BEGIN) {
                    // When playback starts, automatically set the playback button to pause.
                    mCurrentParams.setIsPlaying(true);
                }
                updatePip(mCurrentParams);
            }
            if (event == TXLiveConstants.PLAY_EVT_PLAY_END) {
                // When playback is complete, automatically set the playback button to play.
                controlPipPlayStatus(false);
            } else if (event == TXLiveConstants.PLAY_EVT_PLAY_BEGIN) {
                // When playback starts, automatically set the playback button to pause.
                controlPipPlayStatus(true);
            } else if (event == TXLiveConstants.PLAY_EVT_PLAY_PROGRESS) {
                int progress = bundle.getInt(TXLiveConstants.EVT_PLAY_PROGRESS_MS);
                int duration = bundle.getInt(TXLiveConstants.EVT_PLAY_DURATION_MS);
                float percentage = (progress / 1000F) / (duration / 1000F);
                final int progressToShow = Math.round(percentage * mVideoProgress.getMax());
                if (null != mVideoProgress) {
                    mVideoProgress.post(new Runnable() {
                        @Override
                        public void run() {
                            mVideoProgress.setProgress(progressToShow);
                        }
                    });
                }
            }
        }
    }

    @Override
    public void onPlayEvent(int event, Bundle bundle) {
    }

    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {
    }

    @Override
    public void onNetStatus(Bundle bundle) {
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
    }

}