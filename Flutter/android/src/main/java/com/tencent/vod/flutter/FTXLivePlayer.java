// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.util.Log;
import android.view.Surface;
import androidx.annotation.NonNull;
import com.tencent.rtmp.ITXLivePlayListener;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoublePlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXLivePlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringIntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterLivePlayerApi;
import com.tencent.vod.flutter.model.PipResult;
import com.tencent.vod.flutter.model.VideoModel;
import com.tencent.vod.flutter.tools.CommonUtil;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.view.TextureRegistry;

/**
 * live player processor
 */
public class FTXLivePlayer extends FTXBasePlayer implements ITXLivePlayListener, TXFlutterLivePlayerApi {

    private static final String TAG = "FTXLivePlayer";
    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    private final EventChannel mEventChannel;
    private final EventChannel mNetChannel;

    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    private final FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    private final FTXPlayerEventSink mNetStatusSink = new FTXPlayerEventSink();

    private TXLivePlayer mLivePlayer;
    private static final int Uninitialized = -101;
    private boolean mEnableHardwareDecode = true;
    private boolean mHardwareDecodeFail = false;
    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;

    private int mSurfaceWidth = 0;
    private int mSurfaceHeight = 0;

    private final FTXPIPManager mPipManager;
    private FTXPIPManager.PipParams mPipParams;
    private VideoModel mVideoModel;
    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(PipResult result) {
            // 启动pip的时候，当前player已经暂停，pip退出之后，如果退出的时候pip还处于播放状态，那么当前player也置为播放状态
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                resumePlayer();
            }
        }
    };

    /**
     * 直播播放器
     */
    public FTXLivePlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;
        mPipManager = pipManager;
        mVideoModel = new VideoModel();
        mVideoModel.setPlayerType(FTXEvent.PLAYER_LIVE);

        mSurfaceTextureEntry = mFlutterPluginBinding.getTextureRegistry().createSurfaceTexture();
        mSurfaceTexture = mSurfaceTextureEntry.surfaceTexture();
        mSurface = new Surface(mSurfaceTexture);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
                "cloud.tencent.com/txliveplayer/event/" + super.getPlayerId());
        mEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink.setEventSinkProxy(eventSink);
            }

            @Override
            public void onCancel(Object o) {
                mEventSink.setEventSinkProxy(null);
            }
        });

        mNetChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
                "cloud.tencent.com/txliveplayer/net/" + super.getPlayerId());
        mNetChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mNetStatusSink.setEventSinkProxy(eventSink);
            }

            @Override
            public void onCancel(Object o) {
                mNetStatusSink.setEventSinkProxy(null);
            }
        });
    }

    @Override
    public void destroy() {
        if (mLivePlayer != null) {
            mLivePlayer.stopPlay(true);
            mLivePlayer = null;
        }

        if (mSurfaceTextureEntry != null) {
            mSurfaceTextureEntry.release();
            mSurfaceTextureEntry = null;
        }

        if (mSurfaceTexture != null) {
            mSurfaceTexture.release();
            mSurfaceTexture = null;
        }

        if (mSurface != null) {
            mSurface.release();
            mSurface = null;
        }

        mEventChannel.setStreamHandler(null);
        mNetChannel.setStreamHandler(null);
    }

    @Override
    public void onPlayEvent(int event, Bundle bundle) {
        if (event == TXLiveConstants.PLAY_EVT_CHANGE_RESOLUTION) {
            int width = bundle.getInt(TXLiveConstants.EVT_PARAM1, 0);
            int height = bundle.getInt(TXLiveConstants.EVT_PARAM2, 0);
            if (!mEnableHardwareDecode || mHardwareDecodeFail) {
                setDefaultBufferSizeForSoftDecode(width, height);
            }
        } else if (event == TXLiveConstants.PLAY_WARNING_HW_ACCELERATION_FAIL) {
            mHardwareDecodeFail = true;
        }
        mEventSink.success(CommonUtil.getParams(event, bundle));
    }

    @Override
    public void onNetStatus(Bundle bundle) {
        mNetStatusSink.success(CommonUtil.getParams(0, bundle));
    }

    // surface 的大小默认是宽高为1，当硬解失败时或使用软解时，软解会依赖surface的窗口渲染，不更新会导致只有1px的内容
    private void setDefaultBufferSizeForSoftDecode(int width, int height) {
        if (mSurfaceTextureEntry != null) {
            mSurfaceTextureEntry.surfaceTexture();
            SurfaceTexture surfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            surfaceTexture.setDefaultBufferSize(width, height);
            if (mSurface != null) {
                mSurface.release();
            }
            mSurface = new Surface(surfaceTexture);
            mLivePlayer.setSurface(mSurface);
        }
    }

    protected long init(boolean onlyAudio) {
        if (mLivePlayer == null) {
            mLivePlayer = new TXLivePlayer(mFlutterPluginBinding.getApplicationContext());
            mLivePlayer.setPlayListener(this);
        }
        Log.d("AndroidLog", "textureId :" + mSurfaceTextureEntry.id());
        return mSurfaceTextureEntry == null ? -1 : mSurfaceTextureEntry.id();
    }

    int startPlayerLivePlay(String url, Integer type) {
        Log.d(TAG, "startLivePlay:");
        if (null == type) {
            type = TXLivePlayer.PLAY_TYPE_LIVE_FLV;
        }
        mVideoModel.setVideoUrl(url);
        mVideoModel.setLiveType(type);
        if (mLivePlayer != null) {
            mLivePlayer.setSurface(mSurface);
            mLivePlayer.setPlayListener(this);
            TXLivePlayConfig config = new TXLivePlayConfig();
            config.setEnableMessage(true);

            mLivePlayer.setVideoRenderListener(new TXLivePlayer.ITXLivePlayVideoRenderListener() {
                @Override
                public void onRenderVideoFrame(TXLivePlayer.TXLiteAVTexture texture) {
                    int width = texture.width;
                    int height = texture.height;
                    if (width != mSurfaceWidth || height != mSurfaceHeight) {
                        Log.d(TAG, "onRenderVideoFrame: width=" + texture.width + ",height=" + texture.height);
                        mLivePlayer.setSurfaceSize(width, height);
                        mSurfaceTexture.setDefaultBufferSize(width, height);
                        mSurfaceWidth = width;
                        mSurfaceHeight = height;
                    }
                }
            }, null);
            return mLivePlayer.startLivePlay(url, type);
        }
        return Uninitialized;
    }

    int stopPlay(boolean isNeedClearLastImg) {
        if (mLivePlayer != null) {
            return mLivePlayer.stopPlay(isNeedClearLastImg);
        }
        mHardwareDecodeFail = false;
        return Uninitialized;
    }

    boolean isPlayerPlaying() {
        if (mLivePlayer != null) {
            return mLivePlayer.isPlaying();
        }
        return false;
    }

    void pausePlayer() {
        if (mLivePlayer != null) {
            mLivePlayer.pause();
        }
    }

    void resumePlayer() {
        if (mLivePlayer != null) {
            mLivePlayer.resume();
        }
    }

    void setPlayerMute(boolean mute) {
        if (mLivePlayer != null) {
            mLivePlayer.setMute(mute);
        }
    }

    void setPlayerVolume(int volume) {
        if (mLivePlayer != null) {
            mLivePlayer.setVolume(volume);
        }
    }

    void setPlayerAutoPlay(boolean isAutoPlay) {
        if (mLivePlayer != null) {
            mLivePlayer.setAutoPlay(isAutoPlay);
        }
    }

    void seekPlayer(float progress) {
        if (mLivePlayer != null) {
            mLivePlayer.seek((int) progress);
        }
    }

    void setPlayerRate(float rate) {
        if (mLivePlayer != null) {
            mLivePlayer.setRate(rate);
        }
    }

    void setPlayerLiveMode(int type) {
        if (mLivePlayer != null) {
            TXLivePlayConfig config = new TXLivePlayConfig();
            if (type == 0) {
                //自动模式
                config.setAutoAdjustCacheTime(true);
                config.setMinAutoAdjustCacheTime(1);
                config.setMaxAutoAdjustCacheTime(3);
            } else if (type == 1) {
                //极速模式
                config.setAutoAdjustCacheTime(true);
                config.setMinAutoAdjustCacheTime(1);
                config.setMaxAutoAdjustCacheTime(1);
            } else {
                //流畅模式
                config.setAutoAdjustCacheTime(false);
                config.setCacheTime(5);
            }

            mLivePlayer.setConfig(config);
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

    private int preparePlayerLiveSeek(String domain, int bizId) {
        if (mLivePlayer != null) {
            return mLivePlayer.prepareLiveSeek(domain, bizId);
        }
        return Uninitialized;
    }

    private int resumePlayerLive() {
        if (mLivePlayer != null) {
            return mLivePlayer.resumeLive();
        }
        return Uninitialized;
    }

    private boolean enablePlayerHardwareDecode(Boolean enable) {
        if (mLivePlayer != null) {
            mEnableHardwareDecode = enable;
            return mLivePlayer.enableHardwareDecode(enable);
        }
        return false;
    }

    void setPlayerConfig(FTXLivePlayConfigPlayerMsg config) {
        if (mLivePlayer != null) {
            TXLivePlayConfig playConfig = FTXTransformation.transformToLiveConfig(config);
            mLivePlayer.setConfig(playConfig);
        }
    }


    @NonNull
    @Override
    public IntMsg initialize(@NonNull BoolPlayerMsg onlyAudio) {
        long textureId = init(onlyAudio.getValue() != null ? onlyAudio.getValue() : false);
        return CommonUtil.intMsgWith(textureId);
    }

    @NonNull
    @Override
    public BoolMsg startLivePlay(@NonNull StringIntPlayerMsg playerMsg) {
        int r = startPlayerLivePlay(playerMsg.getStrValue(),
                null != playerMsg.getIntValue() ? playerMsg.getIntValue().intValue() : null);
        return CommonUtil.boolMsgWith(r == 1);
    }

    @Override
    public void setAutoPlay(@NonNull BoolPlayerMsg isAutoPlay) {
        if (null != isAutoPlay.getValue()) {
            setPlayerAutoPlay(isAutoPlay.getValue());
        }
    }

    @NonNull
    @Override
    public BoolMsg stop(@NonNull BoolPlayerMsg isNeedClear) {
        boolean flag = null != isNeedClear.getValue() ? isNeedClear.getValue() : false;
        return CommonUtil.boolMsgWith(stopPlay(flag) == 1);
    }

    @NonNull
    @Override
    public BoolMsg isPlaying(@NonNull PlayerMsg playerMsg) {
        return CommonUtil.boolMsgWith(isPlayerPlaying());
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
            setPlayerMute(mute.getValue());
        }
    }

    @NonNull
    @Override
    public IntMsg switchStream(@NonNull StringPlayerMsg url) {
        return CommonUtil.intMsgWith((long) switchPlayerStream(url.getValue()));
    }

    @Override
    public void seek(@NonNull DoublePlayerMsg progress) {
        if (progress.getValue() != null) {
            seekPlayer(progress.getValue().floatValue());
        }
    }

    @Override
    public void setAppID(@NonNull StringPlayerMsg appId) {
        if (null != appId.getValue()) {
            setPlayerAppID(appId.getValue());
        }
    }

    @Override
    public void prepareLiveSeek(@NonNull StringIntPlayerMsg playerMsg) {
        preparePlayerLiveSeek(playerMsg.getStrValue(),
                null != playerMsg.getIntValue() ? playerMsg.getIntValue().intValue() : 0);
    }

    @NonNull
    @Override
    public IntMsg resumeLive(@NonNull PlayerMsg playerMsg) {
        return CommonUtil.intMsgWith((long) resumePlayerLive());
    }

    @Override
    public void setRate(@NonNull DoublePlayerMsg rate) {
        if (null != rate.getValue()) {
            setPlayerRate(rate.getValue().floatValue());
        }
    }

    @Override
    public void setConfig(@NonNull FTXLivePlayConfigPlayerMsg config) {
        setPlayerConfig(config);
    }

    @NonNull
    @Override
    public BoolMsg enableHardwareDecode(@NonNull BoolPlayerMsg enable) {
        if (null != enable.getValue()) {
            return CommonUtil.boolMsgWith(enablePlayerHardwareDecode(enable.getValue()));
        }
        return CommonUtil.boolMsgWith(false);
    }

    @NonNull
    @Override
    public IntMsg enterPictureInPictureMode(@NonNull PipParamsPlayerMsg pipParamsMsg) {
        mPipManager.addCallback(getPlayerId(), pipCallback);
        mPipParams = new FTXPIPManager.PipParams(
                mPipManager.toAndroidPath(pipParamsMsg.getBackIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPlayIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPauseIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getForwardIconForAndroid()),
                getPlayerId(), false, false, true);
        mPipParams.setIsPlaying(isPlayerPlaying());
        int pipResult = mPipManager.enterPip(mPipParams, mVideoModel);
        // 启动成功之后，暂停当前界面视频
        if (pipResult == FTXEvent.NO_ERROR) {
            pausePlayer();
        }
        return CommonUtil.intMsgWith((long) pipResult);
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        mPipManager.exitPip();
    }
}
