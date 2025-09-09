// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.live2.V2TXLiveDef;
import com.tencent.live2.V2TXLivePlayer;
import com.tencent.live2.V2TXLivePlayerObserver;
import com.tencent.live2.impl.V2TXLivePlayerImpl;
import com.tencent.live2.impl.V2TXLiveProperty;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.FTXPIPManager;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.messages.FtxMessages;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXLivePlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterLivePlayerApi;
import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXPlayerHolder;
import com.tencent.vod.flutter.player.render.FTXLivePlayerRenderHost;
import com.tencent.vod.flutter.tools.FTXV2LiveTools;
import com.tencent.vod.flutter.tools.TXCommonUtil;
import com.tencent.vod.flutter.tools.TXFlutterEngineHolder;
import com.tencent.vod.flutter.ui.render.FTXRenderView;
import com.tencent.vod.flutter.ui.render.FTXRenderViewFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * live player processor
 */
public class FTXLivePlayer extends FTXLivePlayerRenderHost implements TXFlutterLivePlayerApi, FtxMessages.VoidResult {

    private static final String TAG = "FTXLivePlayer";
    private final FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    private V2TXLivePlayer mLivePlayer;
    private static final int Uninitialized = -101;

    private final FTXPIPManager mPipManager;
    private boolean mNeedPipResume = false;
    private final FTXV2LiveObserver mObserver;
    private int mLastPlayEvent = -1;
    private boolean mIsPaused = false;
    private final FtxMessages.TXLivePlayerFlutterAPI mLiveFlutterApi;
    private final FTXRenderViewFactory mRenderViewFactory;
    private final Handler mUIHandler = new Handler(Looper.getMainLooper());
    private boolean mIsMute = false;
    private int mCurrentVideoWidth = 0;
    private int mCurrentVideoHeight = 0;
    private long mCurrentRenderMode = FTXPlayerConstants.FTXRenderMode.ADJUST_RESOLUTION;

    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(TXPipResult result) {
            if (mLivePlayer != null) {
                mLivePlayer.setObserver(mObserver);
                setRenderView(mCurRenderView.getRenderView());
            }
            // When starting PIP, the current player has been paused. After PIP exits,
            // if PIP is still in playing state, the current player will also be set to playing state.
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                if (TXFlutterEngineHolder.getInstance().isInForeground()) {
                    resumePlayer();
                } else {
                    mNeedPipResume = true;
                }
            }
        }

        @Override
        public void onPipPlayerEvent(int event, Bundle bundle) {
            // live not have pip play event
        }
    };

    private final TXFlutterEngineHolder.TXAppStatusListener mAppLifeListener
            = new TXFlutterEngineHolder.TXAppStatusListener() {
        @Override
        public void onResume() {
            if (mNeedPipResume) {
                mNeedPipResume = false;
                resumePlayer();
            }
        }

        @Override
        public void onEnterBack() {
        }
    };

    /**
     * Live streaming player.
     * <p>
     * 直播播放器
     */
    public FTXLivePlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager,
                         FTXRenderViewFactory renderViewFactory, boolean onlyAudio) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;
        mPipManager = pipManager;
        mRenderViewFactory = renderViewFactory;
        FtxMessages.TXFlutterLivePlayerApi.setUp(flutterPluginBinding.getBinaryMessenger(),
                String.valueOf(getPlayerId()), this);
        mLiveFlutterApi = new FtxMessages.TXLivePlayerFlutterAPI(flutterPluginBinding.getBinaryMessenger(),
                String.valueOf(getPlayerId()));
        TXFlutterEngineHolder.getInstance().addAppLifeListener(mAppLifeListener);
        mObserver = new FTXV2LiveObserver(this);
        init(onlyAudio);
    }

    @Override
    public void destroy() {
        if (mLivePlayer != null) {
            stopPlay(true);
            setRenderView(null);
            mLivePlayer = null;
        }
        mCurRenderView = null;
        mUIHandler.removeCallbacksAndMessages(null);

        TXFlutterEngineHolder.getInstance().removeAppLifeListener(mAppLifeListener);
    }

    protected long init(boolean onlyAudio) {
        if (mLivePlayer == null) {
            mLivePlayer = new V2TXLivePlayerImpl(mFlutterPluginBinding.getApplicationContext());
            mLivePlayer.setObserver(mObserver);
            applyRenderMode();
            if (!onlyAudio) {
                if (null != mCurRenderView) {
                    mCurRenderView.setPlayer(this);
                }
            }
        }
        return FTXEvent.NO_ERROR;
    }

    int startPlayerLivePlay(String url) {
        LiteavLog.i(TAG, "startLivePlay:");
        if (null != mLivePlayer) {
            if (null != mCurRenderView) {
                mCurRenderView.setPlayer(this);
            }
            mLivePlayer.resumeVideo();
            if (!mIsMute) {
                mLivePlayer.resumeAudio();
            }
            mLastPlayEvent = -1;
            mIsPaused = false;
            mLivePlayer.startLivePlay(url);
            return 0;
        }
        return Uninitialized;
    }

    int stopPlay(boolean isNeedClearLastImg) {
        LiteavLog.i(TAG, "called stopPlay isNeedClearLastImg:" + isNeedClearLastImg);
        int result = Uninitialized;
        if (mLivePlayer != null) {
            mLastPlayEvent = -1;
            mIsPaused = false;
            result =  mLivePlayer.stopPlay();
        }
        mUIHandler.removeCallbacksAndMessages(null);
        mCurrentVideoWidth = 0;
        mCurrentVideoHeight = 0;
        if (isNeedClearLastImg && null != mCurRenderView) {
            LiteavLog.i(TAG, "stopPlay target clear last img, player:" + hashCode());
            mCurRenderView.clearTexture();
        }
        return result;
    }

    boolean isPlayerPlaying() {
        if (mLivePlayer != null) {
            return !mIsPaused;
        }
        return false;
    }

    void pausePlayer() {
        LiteavLog.i(TAG, "called pausePlayer");
        if (mLivePlayer != null) {
            mLivePlayer.pauseVideo();
            mLivePlayer.pauseAudio();
            mIsPaused = true;
            if (mPipManager.isInPipMode()) {
                mPipManager.notifyCurrentPipPlayerPlayState(getPlayerId(), isPlayerPlaying());
            }
        }
    }

    void resumePlayer() {
        if (mLivePlayer != null) {
            mLivePlayer.resumeVideo();
            if (!mIsMute) {
                mLivePlayer.resumeAudio();
            }
            mIsPaused = false;
            int evtID = TXLiveConstants.PLAY_EVT_PLAY_BEGIN;
            Bundle bundle = new Bundle();
            notifyPlayerEvent(evtID, bundle);
        }
    }

    void setPlayerMute(boolean mute) {
        if (mLivePlayer != null) {
            mIsMute = mute;
            if (mute) {
                mLivePlayer.pauseAudio();
            } else if (!mIsPaused) {
                mLivePlayer.resumeAudio();
            }
        }
    }

    void setPlayerVolume(int volume) {
        if (mLivePlayer != null) {
            mLivePlayer.setPlayoutVolume(volume);
        }
    }

    void setPlayerLiveMode(int type) {
        if (mLivePlayer != null) {
            if (type == 0) {
                // Auto mode
                mLivePlayer.setCacheParams(1.0f, 5.0f);
            } else if (type == 1) {
                // Ultra-fast mode.
                mLivePlayer.setCacheParams(1.0f, 1.0f);
            } else {
                // Smooth mode.
                mLivePlayer.setCacheParams(5.0f, 5.0f);
            }
        }
    }

    int switchPlayerStream(String url) {
        if (mLivePlayer != null) {
            return mLivePlayer.switchStream(url);
        }
        return -1;
    }

    private void setPlayerAppID(String appId) {
        TXLiveBase.setAppID(appId);
    }

    void setPlayerConfig(FTXLivePlayConfigPlayerMsg config) {
        if (mLivePlayer != null) {
            if (config.getMinAutoAdjustCacheTime() != null && config.getMaxAutoAdjustCacheTime() != null) {
                mLivePlayer.setCacheParams(config.getMinAutoAdjustCacheTime().floatValue()
                        , config.getMaxAutoAdjustCacheTime().floatValue());
            }
            if (config.getConnectRetryCount() != null) {
                mLivePlayer.setProperty(V2TXLiveProperty.kV2MaxNumberOfReconnection,
                        config.getConnectRetryCount().intValue());
            }
            if (config.getConnectRetryInterval() != null) {
                mLivePlayer.setProperty(V2TXLiveProperty.kV2SecondsBetweenReconnection,
                        config.getConnectRetryInterval().intValue());
            }
        }
    }

    @NonNull
    @Override
    public IntMsg initialize(@NonNull BoolPlayerMsg onlyAudio) {
        long textureId = init(onlyAudio.getValue() != null ? onlyAudio.getValue() : false);
        return TXCommonUtil.intMsgWith(textureId);
    }

    @NonNull
    @Override
    public BoolMsg startLivePlay(@NonNull StringPlayerMsg playerMsg) {
        int r = startPlayerLivePlay(playerMsg.getValue());
        return TXCommonUtil.boolMsgWith(r == 1);
    }

    @NonNull
    @Override
    public BoolMsg stop(@NonNull BoolPlayerMsg isNeedClear) {
        boolean flag = null != isNeedClear.getValue() ? isNeedClear.getValue() : false;
        return TXCommonUtil.boolMsgWith(stopPlay(flag) == 1);
    }

    @NonNull
    @Override
    public BoolMsg isPlaying(@NonNull PlayerMsg playerMsg) {
        return TXCommonUtil.boolMsgWith(isPlayerPlaying());
    }

    @Override
    public void pause(@NonNull PlayerMsg playerMsg) {
        pausePlayer();
    }

    @Override
    public void resume(@NonNull PlayerMsg playerMsg) {
        resumePlayer();
    }

    @Override
    public void setLiveMode(@NonNull IntPlayerMsg mode) {
        if (null != mode.getValue()) {
            setPlayerLiveMode(mode.getValue().intValue());
        }
    }

    @Override
    public void setVolume(@NonNull IntPlayerMsg volume) {
        if (null != volume.getValue()) {
            setPlayerVolume(volume.getValue().intValue());
        }
    }

    @Override
    public void setMute(@NonNull BoolPlayerMsg mute) {
        if (null != mute.getValue()) {
            LiteavLog.i(TAG, "set player mute:" + mute + ",player:" + hashCode());
            setPlayerMute(mute.getValue());
        }
    }

    @NonNull
    @Override
    public IntMsg switchStream(@NonNull StringPlayerMsg url) {
        return TXCommonUtil.intMsgWith((long) switchPlayerStream(url.getValue()));
    }

    @Override
    public void setAppID(@NonNull StringPlayerMsg appId) {
        if (null != appId.getValue()) {
            setPlayerAppID(appId.getValue());
        }
    }

    @Override
    public void setConfig(@NonNull FTXLivePlayConfigPlayerMsg config) {
        setPlayerConfig(config);
    }

    @NonNull
    @Override
    public BoolMsg enableHardwareDecode(@NonNull BoolPlayerMsg enable) {
        // live auto handle this in v2 live player
        return TXCommonUtil.boolMsgWith(false);
    }

    @NonNull
    @Override
    public IntMsg enterPictureInPictureMode(@NonNull PipParamsPlayerMsg pipParamsMsg) {
        mPipManager.addCallback(getPlayerId(), pipCallback);
        FTXPIPManager.PipParams pipParams = new FTXPIPManager.PipParams(
                mPipManager.toAndroidPath(pipParamsMsg.getBackIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPlayIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPauseIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getForwardIconForAndroid()),
                getPlayerId(), false, false, true);
        int pipResult = FTXEvent.ERROR_PIP_MISS_PLAYER;
        if (null != mLivePlayer) {
            pipParams.setIsPlaying(isPlayerPlaying());
            if (mCurrentVideoWidth > 0 && mCurrentVideoHeight > 0) {
                pipParams.setRadio(mCurrentVideoWidth, mCurrentVideoHeight);
            } else {
                LiteavLog.e(TAG, "miss video size when enter PIP");
            }
            pipResult = mPipManager.enterPip(pipParams, new TXPlayerHolder(mLivePlayer, mIsPaused));
            // After the startup is successful, pause the video on the current interface.
            if (pipResult == FTXEvent.NO_ERROR) {
                pausePlayer();
            }
        }
        return TXCommonUtil.intMsgWith((long) pipResult);
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        mPipManager.exitPipByPlayerId(getPlayerId());
    }

    @NonNull
    @Override
    public Long enableReceiveSeiMessage(@NonNull PlayerMsg playerMsg,
                                        @NonNull Boolean isEnabled, @NonNull Long payloadType) {
        if (null != mLivePlayer) {
            return (long) mLivePlayer.enableReceiveSeiMessage(isEnabled, payloadType.intValue());
        }
        return -1L;
    }

    @Override
    public void showDebugView(@NonNull PlayerMsg playerMsg, @NonNull Boolean isShow) {
        if (null != mLivePlayer) {
            mLivePlayer.showDebugView(isShow);
        }
    }

    @NonNull
    @Override
    public Long setProperty(@NonNull PlayerMsg playerMsg, @NonNull String key, @NonNull Object value) {
        if (null != mLivePlayer) {
            return (long) mLivePlayer.setProperty(key, value);
        }
        return -1L;
    }

    @NonNull
    @Override
    public FtxMessages.ListMsg getSupportedBitrate(@NonNull PlayerMsg playerMsg) {
        if (null != mLivePlayer) {
            List<V2TXLiveDef.V2TXLiveStreamInfo> streamInfos = mLivePlayer.getStreamList();
            List<Object> jsons = new ArrayList<>();
            for (V2TXLiveDef.V2TXLiveStreamInfo item : streamInfos) {
                Map<Object, Object> map = new HashMap<>();
                map.put("bitrate", item.bitrate);
                map.put("width", item.width);
                map.put("height", item.height);
                map.put("framerate", item.framerate);
                map.put("url", item.url);
                jsons.add(map);
            }
            return TXCommonUtil.listMsgWith(jsons);
        }
        return TXCommonUtil.listMsgWith(new ArrayList<>());
    }

    @NonNull
    @Override
    public Long setCacheParams(@NonNull PlayerMsg playerMsg, @NonNull Double minTime, @NonNull Double maxTime) {
        if (null != mLivePlayer) {
            mLivePlayer.setCacheParams(minTime.floatValue(), maxTime.floatValue());
        }
        return -1L;
    }

    @NonNull
    @Override
    public Long enablePictureInPicture(@NonNull BoolPlayerMsg msg) {
        return -1L;
    }

    @Override
    public void setPlayerView(@NonNull Long renderViewId) {
        int viewId = renderViewId.intValue();
        FTXRenderView renderView = mRenderViewFactory.findViewById(viewId);
        if (null == renderView) {
            LiteavLog.e(TAG, "setPlayerView can not find renderView by id:"
                    + viewId + ", release player's renderView");
        }
        setUpPlayerView(renderView);
    }

    @Override
    public void setRenderMode(@NonNull Long renderMode) {
        if (mCurrentRenderMode != renderMode) {
            mCurrentRenderMode = renderMode;
            applyRenderMode();
        }
    }

    private void applyRenderMode() {
        if (null != mLivePlayer) {
            if (mCurrentRenderMode == FTXPlayerConstants.FTXRenderMode.ADJUST_RESOLUTION) {
                mLivePlayer.setRenderFillMode(V2TXLiveDef.V2TXLiveFillMode.V2TXLiveFillModeFit);
            } else if (mCurrentRenderMode == FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER) {
                mLivePlayer.setRenderFillMode(V2TXLiveDef.V2TXLiveFillMode.V2TXLiveFillModeFill);
            } else if (mCurrentRenderMode == FTXPlayerConstants.FTXRenderMode.SCALE_FULL_FILL_CONTAINER) {
                mLivePlayer.setRenderFillMode(V2TXLiveDef.V2TXLiveFillMode.V2TXLiveFillModeScaleFill);
            }
        }
    }

    private void notifyPlayerEvent(int evtId, Bundle bundle) {
        mUIHandler.post(new Runnable() {
            @Override
            public void run() {
                mLastPlayEvent = evtId;
                mLiveFlutterApi.onPlayerEvent(TXCommonUtil.getParams(evtId, bundle), FTXLivePlayer.this);
                LiteavLog.e(TAG, "onLivePlayEvent:" + evtId
                        + "," + bundle.getString(TXLiveConstants.EVT_DESCRIPTION));
            }
        });
    }

    @Override
    public void success() {

    }

    @Override
    public void error(@NonNull Throwable error) {
        LiteavLog.e(TAG, "callback message error:" + error);
    }

    @Override
    protected V2TXLivePlayer getLivePlayer() {
        return mLivePlayer;
    }

    private static class FTXV2LiveObserver extends V2TXLivePlayerObserver implements FtxMessages.VoidResult {

        private static final String TAG = "FTXV2LiveObserver";

        private final FTXLivePlayer mLivePlayer;
        private final FtxMessages.TXLivePlayerFlutterAPI mLiveFlutterApi;

        public FTXV2LiveObserver(FTXLivePlayer livePlayer) {
            mLivePlayer = livePlayer;
            mLiveFlutterApi = livePlayer.mLiveFlutterApi;
        }

        @Override
        public void onRenderVideoFrame(V2TXLivePlayer player, V2TXLiveDef.V2TXLiveVideoFrame videoFrame) {
            super.onRenderVideoFrame(player, videoFrame);
        }

        @Override
        public void onError(V2TXLivePlayer player, int code, String msg, Bundle extraInfo) {
            super.onError(player, code, msg, extraInfo);
            Bundle params = new Bundle(extraInfo);
            params.putString(TXLiveConstants.EVT_DESCRIPTION, msg);
            mLivePlayer.notifyPlayerEvent(code, params);
        }

        @Override
        public void onWarning(V2TXLivePlayer player, int code, String msg, Bundle extraInfo) {
            super.onWarning(player, code, msg, extraInfo);
            Bundle params = new Bundle(extraInfo);
            params.putString(TXLiveConstants.EVT_DESCRIPTION, msg);
            mLivePlayer.notifyPlayerEvent(code, params);
        }

        @Override
        public void onVideoResolutionChanged(V2TXLivePlayer player, int width, int height) {
            super.onVideoResolutionChanged(player, width, height);
            Bundle bundle = new Bundle();
            bundle.putInt(FTXEvent.EVT_KEY_PLAYER_WIDTH, width);
            bundle.putInt(FTXEvent.EVT_KEY_PLAYER_HEIGHT, height);
            bundle.putInt(TXLiveConstants.EVT_PARAM1, width);
            bundle.putInt(TXLiveConstants.EVT_PARAM2, height);
            bundle.putString(TXLiveConstants.EVT_DESCRIPTION,
                    String.format(Locale.ROOT, "Resolution changed. resolution:%1$dx%2$d, (long)width, (long)height",
                    width, height));
            int code = TXLiveConstants.PLAY_EVT_CHANGE_RESOLUTION;
            mLivePlayer.notifyPlayerEvent(code, bundle);
            mLivePlayer.mCurrentVideoWidth = width;
            mLivePlayer.mCurrentVideoHeight = height;
        }

        @Override
        public void onConnected(V2TXLivePlayer player, Bundle extraInfo) {
            super.onConnected(player, extraInfo);
            int evtID = TXLiveConstants.PLAY_EVT_CONNECT_SUCC;
            Bundle bundle = new Bundle(extraInfo);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onVideoPlaying(V2TXLivePlayer player, boolean firstPlay, Bundle extraInfo) {
            super.onVideoPlaying(player, firstPlay, extraInfo);
            // loading
            if (mLivePlayer.mLastPlayEvent == TXLiveConstants.PLAY_EVT_PLAY_LOADING) {
                int evtID = TXLiveConstants.PLAY_EVT_VOD_LOADING_END;
                Bundle bundle = new Bundle(extraInfo);
                mLivePlayer.notifyPlayerEvent(evtID, bundle);
            }
            // begin
            {
                int evtID = TXLiveConstants.PLAY_EVT_PLAY_BEGIN;
                Bundle bundle = new Bundle(extraInfo);
                mLivePlayer.notifyPlayerEvent(evtID, bundle);
            }
            // first frame
            if (firstPlay) {
                int evtID = TXLiveConstants.PLAY_EVT_RCV_FIRST_I_FRAME;
                Bundle bundle = new Bundle(extraInfo);
                mLivePlayer.notifyPlayerEvent(evtID, bundle);
            }
        }

        @Override
        public void onAudioPlaying(V2TXLivePlayer player, boolean firstPlay, Bundle extraInfo) {
            super.onAudioPlaying(player, firstPlay, extraInfo);
            int evtID = TXLiveConstants.PLAY_EVT_RCV_FIRST_AUDIO_FRAME;
            Bundle bundle = new Bundle(extraInfo);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onVideoLoading(V2TXLivePlayer player, Bundle extraInfo) {
            super.onVideoLoading(player, extraInfo);
            int evtID = TXLiveConstants.PLAY_EVT_PLAY_LOADING;
            Bundle bundle = new Bundle(extraInfo);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onAudioLoading(V2TXLivePlayer player, Bundle extraInfo) {
            super.onAudioLoading(player, extraInfo);
            int evtID = TXLiveConstants.PLAY_EVT_PLAY_LOADING;
            Bundle bundle = new Bundle(extraInfo);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onPlayoutVolumeUpdate(V2TXLivePlayer player, int volume) {
            super.onPlayoutVolumeUpdate(player, volume);
        }

        @Override
        public void onStatisticsUpdate(V2TXLivePlayer player, V2TXLiveDef.V2TXLivePlayerStatistics statistics) {
            super.onStatisticsUpdate(player, statistics);
            mLivePlayer.mUIHandler.post(new Runnable() {
                @Override
                public void run() {
                    Bundle bundle = FTXV2LiveTools.buildNetBundle(statistics);
                    mLiveFlutterApi.onNetEvent(TXCommonUtil.getParams(0, bundle), FTXV2LiveObserver.this);
                }
            });
        }

        @Override
        public void onSnapshotComplete(V2TXLivePlayer player, Bitmap image) {
            super.onSnapshotComplete(player, image);
        }

        @Override
        public void onPlayoutAudioFrame(V2TXLivePlayer player, V2TXLiveDef.V2TXLiveAudioFrame audioFrame) {
            super.onPlayoutAudioFrame(player, audioFrame);
        }

        @Override
        public void onReceiveSeiMessage(V2TXLivePlayer player, int payloadType, byte[] data) {
            super.onReceiveSeiMessage(player, payloadType, data);
            int evtID = TXLiveConstants.PLAY_EVT_GET_MESSAGE;
            Bundle bundle = new Bundle();
            bundle.putByteArray(TXLiveConstants.EVT_GET_MSG, data);
            bundle.putInt(TXLiveConstants.EVT_GET_MSG_TYPE, payloadType);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onStreamSwitched(V2TXLivePlayer player, String url, int code) {
            super.onStreamSwitched(player, url, code);
            int evtID = TXLiveConstants.PLAY_EVT_STREAM_SWITCH_SUCC;
            String msg = "Switch stream success.";
            if (code != 0) {
                evtID = TXLiveConstants.PLAY_ERR_STREAM_SWITCH_FAIL;
                msg = "Switch stream failed.";
            }
            Bundle bundle = new Bundle();
            bundle.putString(TXLiveConstants.EVT_DESCRIPTION, msg);
            mLivePlayer.notifyPlayerEvent(evtID, bundle);
        }

        @Override
        public void onLocalRecordBegin(V2TXLivePlayer player, int code, String storagePath) {
            super.onLocalRecordBegin(player, code, storagePath);
        }

        @Override
        public void onLocalRecording(V2TXLivePlayer player, long durationMs, String storagePath) {
            super.onLocalRecording(player, durationMs, storagePath);
        }

        @Override
        public void onLocalRecordComplete(V2TXLivePlayer player, int code, String storagePath) {
            super.onLocalRecordComplete(player, code, storagePath);
        }

        @Override
        public void success() {

        }

        @Override
        public void error(@NonNull Throwable error) {
            LiteavLog.e(TAG, "callback message error:" + error);
        }
    }
}
