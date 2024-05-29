// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.ui;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.app.PictureInPictureUiState;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.text.TextUtils;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceHolder.Callback;
import android.view.SurfaceView;
import android.view.View;
import android.widget.ProgressBar;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.rtmp.ITXLivePlayListener;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXVodConstants;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.FTXPIPManager.PipParams;
import com.tencent.vod.flutter.R;
import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXPlayerHolder;
import com.tencent.vod.flutter.tools.TXFlutterEngineHolder;
import com.tencent.vod.flutter.tools.TXSimpleEventBus;


public class FlutterPipImplActivity extends Activity implements Callback, ITXVodPlayListener,
        ITXLivePlayListener, ServiceConnection {

    private static final String TAG = "FlutterPipImplActivity";
    private static TXPlayerHolder pipPlayerHolder;
    private static boolean isInPip = false;

    /**
     * Here, `needToExitPip` is used as a flag. When the `onPictureInPictureModeChanged` callback picture-in-picture
     * state is inconsistent with `isInPictureInPictureMode`, mark it as true. Then, when the width and height of the
     * interface change are detected in `onConfigurationChanged`, the event notification of exiting
     * picture-in-picture mode is performed.
     * for MIUI 12.5.1.
     * <p>
     * 这里使用needToExitPip作为标志位，在出现onPictureInPictureModeChanged回调画中画状态和isInPictureInPictureMode不一致的时候。
     * 标记为true，然后在onConfigurationChanged监听到界面宽高发生变化的时候，进行画中画模式退出的事件通知。
     * for MIUI 12.5.1
     */
    private boolean needToExitPip = false;
    private int configWidth = 0;
    private int configHeight = 0;

    private SurfaceView mVideoSurface;
    private ProgressBar mVideoProgress;

    private boolean mIsSurfaceCreated = false;
    // In picture-in-picture mode, clicking the X in the upper right corner will trigger `onStop` first.
    // Clicking the zoom button will not trigger `onStop`.
    private boolean mIsNeedToStop = false;
    private boolean mIsRegisterReceiver = false;
    private PipParams mCurrentParams;
    private Handler mMainHandler;
    private boolean mIsPipFinishing = false;
    private TXPlayerHolder mPlayerHolder;
    private boolean mIsPlayEnd = false;

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
                            LiteavLog.e(TAG, "unknown control code");
                            break;
                    }
                }
            }
        }
    };

    public static int startPip(Activity activity, PipParams params, TXPlayerHolder playerHolder) {
        if (null == playerHolder) {
            LiteavLog.e(TAG, "startPip failed, playerHolder is null");
            return FTXEvent.ERROR_PIP_MISS_PLAYER;
        }
        if (null == playerHolder.getLivePlayer() && null == playerHolder.getVodPlayer()) {
            LiteavLog.e(TAG, "startPip failed, all player is null");
            return FTXEvent.ERROR_PIP_MISS_PLAYER;
        }
        if (isInPip) {
            LiteavLog.e(TAG, "startPip failed, pip is busy");
            return FTXEvent.ERROR_PIP_IN_BUSY;
        }
        isInPip = true;
        // pause first, resume video after entered pip
        playerHolder.tmpPause();
        pipPlayerHolder = playerHolder;
        Intent intent = new Intent(activity, FlutterPipImplActivity.class);
        intent.setAction(FTXEvent.PIP_ACTION_START);
        intent.putExtra(FTXEvent.EXTRA_NAME_PARAMS, params);
        activity.startActivity(intent);
        return FTXEvent.NO_ERROR;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mMainHandler = new Handler(getMainLooper());
        bindAndroid12BugServiceIfNeed();
        registerPipBroadcast();
        setContentView(R.layout.activity_flutter_pip_impl);
        mVideoSurface = findViewById(R.id.sv_video_container);
        mVideoProgress = findViewById(R.id.pb_video_progress);
        mVideoSurface.getHolder().addCallback(this);
        if (null == pipPlayerHolder) {
            LiteavLog.e(TAG, "lack pipPlayerHolder, please check the pip argument");
            finish();
            return;
        }
        mPlayerHolder = pipPlayerHolder;
        if (null != mPlayerHolder.getVodPlayer()) {
            setVodPlayerListener();
        } else if (null != mPlayerHolder.getLivePlayer()) {
            setLivePlayerListener();
        } else {
            LiteavLog.e(TAG, "lack pipPlayerHolder player, please check the pip argument");
            finish();
        }
        Intent intent = getIntent();
        PipParams params = intent.getParcelableExtra(FTXEvent.EXTRA_NAME_PARAMS);
        if (null == params) {
            LiteavLog.e(TAG, "lack pip params,please check the argument");
            finish();
        } else {
            mCurrentParams = params;
            if (VERSION.SDK_INT >= VERSION_CODES.O) {
                configPipMode(params.buildParams(this));
            } else {
                configPipMode(null);
            }
        }
        handleIntent(intent);
    }


    private void setVodPlayerListener() {
        mPlayerHolder.getVodPlayer().setVodListener(this);
    }

    private void setLivePlayerListener() {
        mPlayerHolder.getLivePlayer().setPlayListener(this);
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
     * <p>
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
                sendPipEvent(FTXEvent.EVENT_PIP_MODE_ALREADY_ENTER, null);
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
        sendPipEvent(FTXEvent.EVENT_PIP_MODE_UI_STATE_CHANGED, null);
    }

    /**
     * Callback notification after `enterPictureInPictureMode` takes effect, only for Android > 31.
     * <p>
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
        mVideoSurface.post(new Runnable() {
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
        });
    }

    private void registerPipBroadcast() {
        if (!mIsRegisterReceiver) {
            IntentFilter pipIntentFilter = new IntentFilter(FTXEvent.ACTION_PIP_PLAY_CONTROL);
            ContextCompat.registerReceiver(this, pipActionReceiver, pipIntentFilter,
                    ContextCompat.RECEIVER_NOT_EXPORTED);
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
        if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
            if (mIsPlayEnd) {
                pipResult.setPlayTime(0F);
            } else {
                Float currentPlayTime = mPlayerHolder.getVodPlayer().getCurrentPlaybackTime();
                pipResult.setPlayTime(currentPlayTime);
            }
            pipResult.setPlaying(mPlayerHolder.getVodPlayer().isPlaying());
            pipResult.setPlayerId(mCurrentParams.getCurrentPlayerId());
            data.putParcelable(FTXEvent.EXTRA_NAME_RESULT, pipResult);
        } else if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_LIVE) {
            pipResult.setPlaying(mPlayerHolder.getLivePlayer().isPlaying());
            pipResult.setPlayerId(mCurrentParams.getCurrentPlayerId());
            data.putParcelable(FTXEvent.EXTRA_NAME_RESULT, pipResult);
        }
        if (null != mPlayerHolder.getVodPlayer()) {
            mPlayerHolder.getVodPlayer().setSurface(null);
        }
        if (null != mPlayerHolder.getLivePlayer()) {
            mPlayerHolder.getLivePlayer().setSurface(null);
        }
        if (null != mPlayerHolder.getVodPlayer()) {
            mPlayerHolder.getVodPlayer().pause();
        } else if (null != mPlayerHolder.getLivePlayer()) {
            mPlayerHolder.getLivePlayer().pause();
        }
        int codeEvent = mIsNeedToStop ? FTXEvent.EVENT_PIP_MODE_ALREADY_EXIT : FTXEvent.EVENT_PIP_MODE_RESTORE_UI;
        sendPipEvent(codeEvent, data);
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
                startPipVideo();
            } else if (TextUtils.equals(action, FTXEvent.PIP_ACTION_EXIT)) {
                exitPip(true);
            } else if (TextUtils.equals(action, FTXEvent.PIP_ACTION_UPDATE)) {
                PipParams pipParams = intent.getParcelableExtra(FTXEvent.EXTRA_NAME_PARAMS);
                updatePip(pipParams);
            } else {
                LiteavLog.e(TAG, "unknown pip action:" + action);
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
    public void movePreActToFront() {
        if (VERSION.SDK_INT == VERSION_CODES.Q) {
            Activity activity = TXFlutterEngineHolder.getInstance().getPreActivity();
            if (null != activity) {
                Intent intent = new Intent(FlutterPipImplActivity.this, activity.getClass());
                intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                startActivity(intent);
            }
        }
    }

    /**
     * Close picture-in-picture mode by using `finish` to close the current interface.
     * <p>
     * 关闭画中画，使用finish当前界面的方式，关闭画中画
     *
     * @param closeImmediately 立刻关闭，不执行延迟，一般关闭画中画为true，还原画中画为false。
     *                         Close immediately without delay. Generally, set it to `true` to close picture-in-picture
     *                         mode and `false` to restore picture-in-picture mode.
     */
    private void exitPip(boolean closeImmediately) {
        if (mIsPipFinishing) {
            return;
        }
        mIsPipFinishing = true;
        if (!isDestroyed() || !isFinishing()) {
            // Due to the foreground service startup restriction in Android 12, if the activity interface is closed
            // too early after returning from picture-in-picture mode, the app cannot be launched normally.
            // Therefore, a delay processing is added here.
            if (!closeImmediately) {
                mVideoSurface.setVisibility(View.GONE);
                mVideoProgress.setVisibility(View.GONE);
                mMainHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        overridePendingTransition(0, 0);
                        finish();
                        mIsPipFinishing = false;
                        movePreActToFront();
                    }
                }, 500);
            } else {
                overridePendingTransition(0, 0);
                finish();
                mIsPipFinishing = false;
            }
        }
    }

    private void startPipVideo() {
        if (mIsSurfaceCreated) {
            attachSurface(mVideoSurface.getHolder().getSurface());
            startPlay();
        }
    }

    private void startPlay() {
        boolean isInitPlaying = pipPlayerHolder.isPlayingWhenCreate();
        if (isInitPlaying) {
            if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
                mPlayerHolder.getVodPlayer().resume();
            } else if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_LIVE) {
                mPlayerHolder.getLivePlayer().resume();
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
        mIsSurfaceCreated = false;
    }

    @Override
    protected void onStop() {
        super.onStop();
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
        mPlayerHolder = null;
        pipPlayerHolder = null;
        isInPip = false;
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
        if (null != mPlayerHolder) {
            if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
                mPlayerHolder.getVodPlayer().setSurface(surface);
            } else if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_LIVE) {
                mPlayerHolder.getLivePlayer().setSurface(surface);
            } else {
                LiteavLog.e(TAG, "unknown player type:" + mPlayerHolder.getPlayerType());
            }
        } else {
            LiteavLog.e(TAG, "pip video model is null");
        }
    }

    private void handlePlayBack() {
        if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
            TXVodPlayer vodPlayer = mPlayerHolder.getVodPlayer();
            if (vodPlayer.isPlaying()) {
                float backPlayTime = vodPlayer.getCurrentPlaybackTime() - 10;
                if (backPlayTime < 0) {
                    backPlayTime = 0;
                }
                vodPlayer.seek(backPlayTime);
            }
        }
    }

    private void handleResumeOrPause() {
        boolean dstPlaying = false;
        if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
            TXVodPlayer vodPlayer = mPlayerHolder.getVodPlayer();
            dstPlaying = !vodPlayer.isPlaying();
            if (dstPlaying) {
                vodPlayer.resume();
            } else {
                vodPlayer.pause();
            }
        } else if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_LIVE) {
            TXLivePlayer livePlayer = mPlayerHolder.getLivePlayer();
            dstPlaying = !livePlayer.isPlaying();
            if (dstPlaying) {
                livePlayer.resume();
            } else {
                livePlayer.pause();
            }
        }
        mCurrentParams.setIsPlaying(dstPlaying);
        updatePip(mCurrentParams);
    }

    private void handlePlayForward() {
        if (mPlayerHolder.getPlayerType() == FTXEvent.PLAYER_VOD) {
            TXVodPlayer vodPlayer = mPlayerHolder.getVodPlayer();
            if (vodPlayer.isPlaying()) {
                float forwardPlayTime = vodPlayer.getCurrentPlaybackTime() + 10;
                float duration = vodPlayer.getDuration();
                if (forwardPlayTime > duration) {
                    forwardPlayTime = duration;
                }
                vodPlayer.seek(forwardPlayTime);
            }
        }
    }

    private void sendPipEvent(int eventCode, Bundle data) {
        if (null == data) {
            data = new Bundle();
        }
        data.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentParams.getCurrentPlayerId());
        data.putInt(FTXEvent.EVENT_PIP_MODE_NAME, eventCode);
        TXSimpleEventBus.getInstance().post(FTXEvent.EVENT_PIP_ACTION, data);
    }

    /**
     * Display component.
     * To prevent the black screen at the moment when picture-in-picture is started,
     * the component is initially in a hidden state, and the component will only be displayed
     * after entering picture-in-picture mode.
     * <p>
     * 显示组件
     * 为了防止画中画启动一瞬间的黑屏，组件一开始为隐藏状态，只有进入画中画之后才会显示组件
     */
    private void showComponent() {
        mVideoSurface.setVisibility(View.VISIBLE);
        mVideoProgress.setVisibility(View.VISIBLE);
        mVideoSurface.setBackgroundColor(Color.parseColor("#33000000"));
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
                    updatePip(mCurrentParams);
                } else if (event == TXLiveConstants.PLAY_EVT_PLAY_BEGIN) {
                    // When playback starts, automatically set the playback button to pause.
                    mCurrentParams.setIsPlaying(true);
                    updatePip(mCurrentParams);
                }
            }
            if (event == TXLiveConstants.PLAY_EVT_PLAY_END) {
                // When playback is complete, automatically set the playback button to play.
                mIsPlayEnd = true;
                controlPipPlayStatus(false);
            } else if (event == TXLiveConstants.PLAY_EVT_PLAY_BEGIN) {
                // When playback starts, automatically set the playback button to pause.
                mIsPlayEnd = false;
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
        sendPlayerEvent(event, bundle);
    }

    @Override
    public void onPlayEvent(int event, Bundle bundle) {
    }

    private void sendPlayerEvent(int eventCode, Bundle data) {
        Bundle params = new Bundle();
        params.putInt(FTXEvent.EXTRA_NAME_PLAYER_ID, mCurrentParams.getCurrentPlayerId());
        params.putInt(FTXEvent.EXTRA_NAME_PIP_PLAYER_EVENT_ID, eventCode);
        params.putBundle(FTXEvent.EXTRA_NAME_PIP_PLAYER_EVENT_PARAMS, data);
        TXSimpleEventBus.getInstance().post(FTXEvent.EVENT_PIP_PLAYER_EVENT_ACTION, params);
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