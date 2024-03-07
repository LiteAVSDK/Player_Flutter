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
import com.tencent.rtmp.TXVodConstants;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXLivePlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringIntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterLivePlayerApi;
import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXVideoModel;
import com.tencent.vod.flutter.tools.TXCommonUtil;

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
    private TXVideoModel mVideoModel;
    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(TXPipResult result) {
            // When starting PIP, if the current player is paused and PIP is still playing when exiting,
            // the current player will also be set to playing state upon exiting PIP.
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                resumePlayer();
            }
        }
    };

    /**
     * Live streaming player.
     *
     * 直播播放器
     */
    public FTXLivePlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;
        mPipManager = pipManager;
        mVideoModel = new TXVideoModel();
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
        if (event != TXVodConstants.VOD_PLAY_EVT_PLAY_PROGRESS) {
            Log.e(TAG, "onLivePlayEvent:" + event + "," + bundle.getString(TXLiveConstants.EVT_DESCRIPTION));
        }
        mEventSink.success(TXCommonUtil.getParams(event, bundle));
    }

    @Override
    public void onNetStatus(Bundle bundle) {
        mNetStatusSink.success(TXCommonUtil.getParams(0, bundle));
    }

    // The default size of the surface is 1x1. When hardware decoding fails or software decoding is used,
    // software decoding relies on the window rendering of the surface.
    // Failure to update will result in only 1 pixel of content.
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

    @Deprecated
    void setPlayerAutoPlay(boolean isAutoPlay) {
    }

    @Deprecated
    void seekPlayer(float progress) {
    }

    @Deprecated
    void setPlayerRate(float rate) {
    }

    void setPlayerLiveMode(int type) {
        if (mLivePlayer != null) {
            TXLivePlayConfig config = new TXLivePlayConfig();
            if (type == 0) {
                // Auto mode
                config.setAutoAdjustCacheTime(true);
                config.setMinAutoAdjustCacheTime(1);
                config.setMaxAutoAdjustCacheTime(3);
            } else if (type == 1) {
                // Ultra-fast mode.
                config.setAutoAdjustCacheTime(true);
                config.setMinAutoAdjustCacheTime(1);
                config.setMaxAutoAdjustCacheTime(1);
            } else {
                // Smooth mode.
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

    @Deprecated
    private int preparePlayerLiveSeek(String domain, int bizId) {
        return Uninitialized;
    }

    @Deprecated
    private int resumePlayerLive() {
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
        return TXCommonUtil.intMsgWith(textureId);
    }

    @NonNull
    @Override
    public BoolMsg startLivePlay(@NonNull StringIntPlayerMsg playerMsg) {
        int r = startPlayerLivePlay(playerMsg.getStrValue(),
                null != playerMsg.getIntValue() ? playerMsg.getIntValue().intValue() : null);
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
        if (null != enable.getValue()) {
            return TXCommonUtil.boolMsgWith(enablePlayerHardwareDecode(enable.getValue()));
        }
        return TXCommonUtil.boolMsgWith(false);
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
        // After the startup is successful, pause the video on the current interface.
        if (pipResult == FTXEvent.NO_ERROR) {
            pausePlayer();
        }
        return TXCommonUtil.intMsgWith((long) pipResult);
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        mPipManager.exitPip();
    }
}
