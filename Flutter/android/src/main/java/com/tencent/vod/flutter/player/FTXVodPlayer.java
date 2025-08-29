// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXBitrateItem;
import com.tencent.rtmp.TXImageSprite;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXPlayInfoParams;
import com.tencent.rtmp.TXPlayerDrmBuilder;
import com.tencent.rtmp.TXTrackInfo;
import com.tencent.rtmp.TXVodConstants;
import com.tencent.rtmp.TXVodDef;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.FTXPIPManager;
import com.tencent.vod.flutter.FTXTransformation;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.messages.FtxMessages;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoubleMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoublePlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXVodPlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.ListMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringListPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXPlayInfoParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.UInt8ListMsg;
import com.tencent.vod.flutter.model.TXPipResult;
import com.tencent.vod.flutter.model.TXPlayerHolder;
import com.tencent.vod.flutter.player.render.FTXVodPlayerRenderHost;
import com.tencent.vod.flutter.tools.FTXVersionAdapter;
import com.tencent.vod.flutter.tools.TXCommonUtil;
import com.tencent.vod.flutter.tools.TXFlutterEngineHolder;
import com.tencent.vod.flutter.ui.render.FTXRenderView;
import com.tencent.vod.flutter.ui.render.FTXRenderViewFactory;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * vodPlayer plugin processor
 */
public class FTXVodPlayer extends FTXVodPlayerRenderHost implements ITXVodPlayListener,
        FtxMessages.TXFlutterVodPlayerApi, FtxMessages.VoidResult {

    private static final String TAG = "FTXVodPlayer";

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    private TXVodPlayer mVodPlayer;
    private TXImageSprite mTxImageSprite;

    private static final int Uninitialized = -101;
    private boolean mEnableHardwareDecode = true;
    private boolean mHardwareDecodeFail = false;
    private final FTXPIPManager mPipManager;
    private boolean mNeedPipResume = false;
    private final FtxMessages.TXVodPlayerFlutterAPI mVodFlutterApi;
    private final FTXRenderViewFactory mRenderViewFactory;
    private final Handler mUIHandler = new Handler(Looper.getMainLooper());
    private long mCurrentRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;
    private float mCurrentRotation = 0;
    private TXVodPlayConfig mCurConfig = new TXVodPlayConfig();
    private final FTXPIPManager.PipCallback mPipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(TXPipResult result) {
            if (mVodPlayer != null) {
                if (null != mCurRenderView) {
                    mCurRenderView.setPlayer(FTXVodPlayer.this);
                }
                mVodPlayer.setVodListener(FTXVodPlayer.this);
            }
            // When starting PIP, the current player has been paused. After PIP exits,
            // if PIP is still in playing state, the current player will also be set to playing state.
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                if (TXFlutterEngineHolder.getInstance().isInForeground()) {
                    playerResume();
                } else {
                    mNeedPipResume = true;
                }
            }
        }

        @Override
        public void onPipPlayerEvent(int event, Bundle bundle) {
            onPlayEvent(mVodPlayer, event, bundle);
        }
    };

    private final TXFlutterEngineHolder.TXAppStatusListener mAppLifeListener
            = new TXFlutterEngineHolder.TXAppStatusListener() {
        @Override
        public void onResume() {
            if (mNeedPipResume) {
                mNeedPipResume = false;
                playerResume();
            }
        }

        @Override
        public void onEnterBack() {
        }
    };

    /**
     * VOD player.
     * <p>
     * 点播播放器
     */
    public FTXVodPlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager,
                        FTXRenderViewFactory renderViewFactory, boolean onlyAudio) {
        super();
        mPipManager = pipManager;
        mFlutterPluginBinding = flutterPluginBinding;
        mRenderViewFactory = renderViewFactory;
        FtxMessages.TXFlutterVodPlayerApi.setUp(flutterPluginBinding.getBinaryMessenger(),
                String.valueOf(getPlayerId()), this);
        mVodFlutterApi = new FtxMessages.TXVodPlayerFlutterAPI(flutterPluginBinding.getBinaryMessenger(),
                String.valueOf(getPlayerId()));
        TXFlutterEngineHolder.getInstance().addAppLifeListener(mAppLifeListener);
        init(onlyAudio);
    }

    @Override
    public void destroy() {
        if (mVodPlayer != null) {
            stopPlay(true);
            mVodPlayer.setPlayerView((TXCloudVideoView) null);
            mVodPlayer = null;
        }
        mCurrentRotation = 0;
        mCurRenderView = null;
        TXFlutterEngineHolder.getInstance().removeAppLifeListener(mAppLifeListener);
        releaseTXImageSprite();
        if (null != mPipManager) {
            mPipManager.releaseCallback(getPlayerId());
        }
    }

    @Override
    public void onPlayEvent(TXVodPlayer txVodPlayer, int event, Bundle bundle) {
        switch (event) {
            case TXLiveConstants.PLAY_EVT_CHANGE_RESOLUTION:
                String evtParam3 = bundle.getString("EVT_PARAM3");
                if (!TextUtils.isEmpty(evtParam3)) {
                    String[] array = evtParam3.split(",");
                    if (array.length == 6) {
                        int videoWidth = Integer.parseInt(array[4]) - Integer.parseInt(array[2]) + 1;
                        int videoHeight = Integer.parseInt(array[5]) - Integer.parseInt(array[3]) + 1;
                        int videoLeft = -Integer.parseInt(array[2]);
                        int videoTop = -Integer.parseInt(array[3]);
                        int videoRight = Integer.parseInt(array[4]) + 1 - Integer.parseInt(array[0]);
                        int videoBottom = Integer.parseInt(array[5]) + 1 - Integer.parseInt(array[1]);
                        bundle.putInt("videoWidth", videoWidth);
                        bundle.putInt("videoHeight", videoHeight);
                        bundle.putInt("videoLeft", videoLeft);
                        bundle.putInt("videoTop", videoTop);
                        bundle.putInt("videoRight", videoRight);
                        bundle.putInt("videoBottom", videoBottom);
                        mUIHandler.post(new Runnable() {
                            @Override
                            public void run() {
                                mVodFlutterApi.onPlayerEvent(TXCommonUtil.getParams(event, bundle),
                                        FTXVodPlayer.this);
                            }
                        });
                        return;
                    }
                }
                long rotation = bundle.getLong(TXVodConstants.EVT_KEY_VIDEO_ROTATION);
                if (mCurConfig.isAutoRotate()) {
                    notifyTextureRotation(rotation);
                }
                mCurrentRotation = rotation;
                break;
            case TXLiveConstants.PLAY_WARNING_HW_ACCELERATION_FAIL:
                mHardwareDecodeFail = true;
                break;
            case TXLiveConstants.PLAY_EVT_VOD_PLAY_PREPARED:
                int resolutionWidth = txVodPlayer.getWidth();
                int resolutionHeight = txVodPlayer.getHeight();
                notifyTextureResolution(resolutionWidth, resolutionHeight);
                break;
            case TXVodConstants.VOD_PLAY_EVT_SEEK_COMPLETE:
                reDraw();
                break;
            default:
                break;
        }
        if (event != TXVodConstants.VOD_PLAY_EVT_PLAY_PROGRESS) {
            LiteavLog.i(TAG, "onPlayEvent:" + event + "," + bundle.getString(TXLiveConstants.EVT_DESCRIPTION));
        }
        if (event == TXLiveConstants.PLAY_EVT_RCV_FIRST_I_FRAME) {
            // delay fir
            mUIHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    mVodFlutterApi.onPlayerEvent(TXCommonUtil.getParams(event, bundle), FTXVodPlayer.this);
                }
            }, 200);
        } else {
            mUIHandler.post(new Runnable() {
                @Override
                public void run() {
                    mVodFlutterApi.onPlayerEvent(TXCommonUtil.getParams(event, bundle), FTXVodPlayer.this);
                }
            });
        }
    }

    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {
        mUIHandler.post(new Runnable() {
            @Override
            public void run() {
                mVodFlutterApi.onNetEvent(TXCommonUtil.getParams(0, bundle), FTXVodPlayer.this);
            }
        });
    }

    private byte[] getPlayerImageSprite(final Double time) {
        if (mTxImageSprite != null && null != time) {
            Bitmap bitmap = mTxImageSprite.getThumbnail(time.floatValue());
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            if (null != bitmap) {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                return stream.toByteArray();
            }
        } else {
            LiteavLog.e(TAG, "getImageSprite failed, time is null or initImageSprite not invoke");
        }
        return null;
    }

    private void releaseTXImageSprite() {
        if (mTxImageSprite != null) {
            mTxImageSprite.release();
            mTxImageSprite = null;
        }
    }

    @Override
    public void reDraw() {
        if (mCurRenderView != null) {
            mCurRenderView.getRenderView().reDrawVod();
        }
    }

    protected long init(boolean onlyAudio) {
        if (mVodPlayer == null) {
            mVodPlayer = new TXVodPlayer(mFlutterPluginBinding.getApplicationContext());
            mVodPlayer.setVodListener(this);
            mVodPlayer.setRenderMode(TXLiveConstants.RENDER_MODE_ADJUST_RESOLUTION);
            // prevent config null exception
            TXVodPlayConfig playConfig = new TXVodPlayConfig();
            FTXVersionAdapter.enableCustomSubtitle(playConfig, 0);
            FTXVersionAdapter.enableDrmLevel3(playConfig, true);
            mCurConfig = playConfig;
            mVodPlayer.setConfig(playConfig);
            mVodPlayer.setVodSubtitleDataListener(new ITXVodPlayListener.ITXVodSubtitleDataListener() {
                @Override
                public void onSubtitleData(TXVodDef.TXVodSubtitleData sub) {
                    LiteavLog.i(TAG, "callback subtitle"
                            + " ,index:" + sub.trackIndex
                            + " ,startMs:" + sub.startPositionMs
                            + " ,durationMs:" + sub.durationMs
                            + " ,content:" + sub.subtitleData
                    );
                    Bundle bundle = new Bundle();
                    bundle.putString(FTXEvent.EXTRA_SUBTITLE_DATA, sub.subtitleData);
                    bundle.putLong(FTXEvent.EXTRA_SUBTITLE_START_POSITION_MS, sub.startPositionMs);
                    bundle.putLong(FTXEvent.EXTRA_SUBTITLE_DURATION_MS, sub.durationMs);
                    bundle.putLong(FTXEvent.EXTRA_SUBTITLE_TRACK_INDEX, sub.trackIndex);
                    mVodFlutterApi.onPlayerEvent(TXCommonUtil.getParams(FTXEvent.EVENT_SUBTITLE_DATA, bundle),
                            FTXVodPlayer.this);
                }
            });
            setPlayer(onlyAudio);
        }
        return FTXEvent.NO_ERROR;
    }

    void setPlayer(boolean onlyAudio) {
        if (!onlyAudio) {
            if (mVodPlayer != null && null != mCurRenderView) {
                mCurRenderView.setPlayer(this);
            }
        }
    }

    int startPlayerVodPlay(String url) {
        if (mVodPlayer != null) {
            if (null != mCurRenderView) {
                mCurRenderView.setPlayer(this);
            }
            mCurrentRotation = 0;
            return mVodPlayer.startVodPlay(url);
        }
        return Uninitialized;
    }

    void startPlayerVodPlayWithParams(int appId, String fileId, String psign) {
        if (mVodPlayer != null) {
            if (null != mCurRenderView) {
                mCurRenderView.setPlayer(this);
            }
            TXPlayInfoParams playInfoParams = new TXPlayInfoParams(appId, fileId, psign);
            mVodPlayer.startVodPlay(playInfoParams);
        }
    }

    int stopPlay(boolean isNeedClearLastImg) {
        int result = Uninitialized;
        if (mVodPlayer != null) {
            result = mVodPlayer.stopPlay(isNeedClearLastImg);
        }
        mUIHandler.removeCallbacksAndMessages(null);
        mPipManager.exitPipByPlayerId(getPlayerId());
        releaseTXImageSprite();
        mHardwareDecodeFail = false;
        if (isNeedClearLastImg && null != mCurRenderView) {
            LiteavLog.i(TAG, "stopPlay target clear last img, player:" + hashCode());
            mCurRenderView.clearTexture();
        }
        return result;
    }

    boolean isPlayerPlaying() {
        if (mVodPlayer != null) {
            return mVodPlayer.isPlaying();
        }
        return false;
    }

    void playerPause() {
        if (mVodPlayer != null) {
            mVodPlayer.pause();
            if (mPipManager.isInPipMode()) {
                mPipManager.notifyCurrentPipPlayerPlayState(getPlayerId(), isPlayerPlaying());
            }
        }
    }

    void playerResume() {
        if (mVodPlayer != null) {
            mVodPlayer.resume();
        }
    }

    void setPlayerMute(boolean mute) {
        if (mVodPlayer != null) {
            mVodPlayer.setMute(mute);
        }
    }

    void setPlayerAudioPlayoutVolume(int volume) {
        if (mVodPlayer != null) {
            mVodPlayer.setAudioPlayoutVolume(volume);
        }
    }

    void setPlayerLoop(boolean loop) {
        if (mVodPlayer != null) {
            mVodPlayer.setLoop(loop);
        }
    }

    void setPlayerStartTime(double startTime) {
        if (mVodPlayer != null) {
            mVodPlayer.setStartTime((float) startTime);
        }
    }

    void setIsAutoPlay(boolean isAutoPlay) {
        if (mVodPlayer != null) {
            mVodPlayer.setAutoPlay(isAutoPlay);
        }
    }

    List<?> getPlayerSupportedBitrates() {
        if (mVodPlayer != null) {
            ArrayList<TXBitrateItem> bitrates = mVodPlayer.getSupportedBitrates();
            ArrayList<Map<Object, Object>> jsons = new ArrayList<>();
            for (TXBitrateItem item :
                    bitrates) {
                Map<Object, Object> map = new HashMap<>();
                map.put("bitrate", item.bitrate);
                map.put("width", item.width);
                map.put("height", item.height);
                map.put("index", item.index);
                jsons.add(map);
            }
            return jsons;
        }
        return null;
    }

    void setPlayerBitrateIndex(int i) {
        if (mVodPlayer != null) {
            mVodPlayer.setBitrateIndex(i);
        }
    }

    void seekPlayer(float progress) {
        if (mVodPlayer != null) {
            mVodPlayer.seek(progress);
        }
    }

    void setPlayerRate(float rate) {
        if (mVodPlayer != null) {
            mVodPlayer.setRate(rate);
        }
    }

    void setPlayConfig(FTXVodPlayConfigPlayerMsg config) {
        if (mVodPlayer != null) {
            TXVodPlayConfig playConfig = FTXTransformation.transformToVodConfig(config);
            FTXVersionAdapter.enableCustomSubtitle(playConfig, 0);
            FTXVersionAdapter.enableDrmLevel3(playConfig, true);
            mCurConfig = playConfig;
            mVodPlayer.setConfig(playConfig);
        }
    }

    float getPlayerCurrentPlaybackTime() {
        if (mVodPlayer != null) {
            return mVodPlayer.getCurrentPlaybackTime();
        }
        return 0;
    }

    float getPlayerPlayableDuration() {
        if (mVodPlayer != null) {
            return mVodPlayer.getPlayableDuration();
        }
        return 0;
    }

    float getPlayerBufferDuration() {
        if (mVodPlayer != null) {
            return mVodPlayer.getBufferDuration();
        }
        return 0;
    }

    int getPlayerWidth() {
        if (mVodPlayer != null) {
            return mVodPlayer.getWidth();
        }
        return 0;
    }

    int getPlayerHeight() {
        if (mVodPlayer != null) {
            return mVodPlayer.getHeight();
        }
        return 0;
    }

    void setPlayerToken(String token) {
        if (mVodPlayer != null) {
            if (TextUtils.isEmpty(token)) {
                mVodPlayer.setToken(null);
            } else {
                mVodPlayer.setToken(token);
            }
        }
    }

    boolean isVodPlayerLoop() {
        if (mVodPlayer != null) {
            return mVodPlayer.isLoop();
        }
        return false;
    }

    boolean enablePlayerHardwareDecode(boolean enable) {
        if (mVodPlayer != null) {
            mEnableHardwareDecode = enable;
            return mVodPlayer.enableHardwareDecode(enable);
        }
        return false;
    }

    boolean requestPlayerAudioFocus(boolean focus) {
        if (mVodPlayer != null) {
            return mVodPlayer.setRequestAudioFocus(focus);
        }
        return false;
    }

    int getPlayerBitrateIndex() {
        if (mVodPlayer != null) {
            return mVodPlayer.getBitrateIndex();
        }
        return -1;
    }

    @NonNull
    @Override
    public IntMsg initialize(@NonNull BoolPlayerMsg onlyAudio) {
        long textureId = init(onlyAudio.getValue() != null ? onlyAudio.getValue() : false);
        return TXCommonUtil.intMsgWith(textureId);
    }

    @NonNull
    @Override
    public BoolMsg startVodPlay(@NonNull StringPlayerMsg url) {
        String urlStr = url.getValue();
        return TXCommonUtil.boolMsgWith(startPlayerVodPlay(urlStr) == 1);
    }

    @Override
    public void startVodPlayWithParams(@NonNull TXPlayInfoParamsPlayerMsg params) {
        int appId = Objects.requireNonNull(params.getAppId()).intValue();
        String fileId = params.getFileId();
        String psign = params.getPsign();
        startPlayerVodPlayWithParams(appId, fileId, psign);
    }

    @NonNull
    @Override
    public IntMsg startPlayDrm(@NonNull FtxMessages.TXPlayerDrmMsg params) {
        if (null != mVodPlayer) {
            TXPlayerDrmBuilder builder = new TXPlayerDrmBuilder(params.getLicenseUrl(), params.getPlayUrl());
            if (!TextUtils.isEmpty(params.getDeviceCertificateUrl())) {
                builder.setDeviceCertificateUrl(params.getDeviceCertificateUrl());
            }
            int result = mVodPlayer.startPlayDrm(builder);
            return TXCommonUtil.intMsgWith((long) result);
        }
        return TXCommonUtil.intMsgWith((long) Uninitialized);
    }

    @Override
    public void setAutoPlay(@NonNull BoolPlayerMsg isAutoPlay) {
        if (null != isAutoPlay.getValue()) {
            setIsAutoPlay(isAutoPlay.getValue());
        }
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
        playerPause();
    }

    @Override
    public void resume(@NonNull PlayerMsg playerMsg) {
        playerResume();
    }

    @Override
    public void setMute(@NonNull BoolPlayerMsg mute) {
        if (null != mute.getValue()) {
            setPlayerMute(mute.getValue());
        }
    }

    @Override
    public void setLoop(@NonNull BoolPlayerMsg loop) {
        if (null != loop.getValue()) {
            setPlayerLoop(loop.getValue());
        }
    }

    @Override
    public void seek(@NonNull DoublePlayerMsg progress) {
        if (null != progress.getValue()) {
            seekPlayer(progress.getValue().floatValue());
        }
    }

    @Override
    public void seekToPdtTime(@NonNull IntPlayerMsg pdtTimeMs) {
        if (null != pdtTimeMs.getValue()) {
            seekToPdtTime(pdtTimeMs.getValue().longValue());
        }
    }

    public void seekToPdtTime(long pdtTimeMs) {
        if (mVodPlayer != null) {
            mVodPlayer.seekToPdtTime(pdtTimeMs);
        }
    }

    @Override
    public void setRate(@NonNull DoublePlayerMsg rate) {
        if (null != rate.getValue()) {
            setPlayerRate(rate.getValue().floatValue());
        }
    }

    @NonNull
    @Override
    public ListMsg getSupportedBitrate(@NonNull PlayerMsg playerMsg) {
        //noinspection unchecked
        return TXCommonUtil.listMsgWith((List<Object>) getPlayerSupportedBitrates());
    }

    @NonNull
    @Override
    public IntMsg getBitrateIndex(@NonNull PlayerMsg playerMsg) {
        return TXCommonUtil.intMsgWith((long) getPlayerBitrateIndex());
    }

    @Override
    public void setBitrateIndex(@NonNull IntPlayerMsg index) {
        if (null != index.getValue()) {
            setPlayerBitrateIndex(index.getValue().intValue());
        }
    }

    @Override
    public void setStartTime(@NonNull DoublePlayerMsg startTime) {
        if (null != startTime.getValue()) {
            setPlayerStartTime(startTime.getValue());
        }
    }

    @Override
    public void setAudioPlayOutVolume(@NonNull IntPlayerMsg volume) {
        if (null != volume.getValue()) {
            setPlayerAudioPlayoutVolume(volume.getValue().intValue());
        }
    }

    @NonNull
    @Override
    public BoolMsg setRequestAudioFocus(@NonNull BoolPlayerMsg focus) {
        if (null != focus.getValue()) {
            return TXCommonUtil.boolMsgWith(requestPlayerAudioFocus(focus.getValue()));
        }
        return TXCommonUtil.boolMsgWith(false);
    }

    @Override
    public void setConfig(@NonNull FTXVodPlayConfigPlayerMsg config) {
        setPlayConfig(config);
    }

    @NonNull
    @Override
    public DoubleMsg getCurrentPlaybackTime(@NonNull PlayerMsg playerMsg) {
        // Use BigDecimal for conversion to prevent precision issues with decimal
        // digits when converting from float to double.
        BigDecimal bigDecimal = BigDecimal.valueOf(getPlayerCurrentPlaybackTime());
        return TXCommonUtil.doubleMsgWith(bigDecimal.doubleValue());
    }

    @NonNull
    @Override
    public DoubleMsg getBufferDuration(@NonNull PlayerMsg playerMsg) {
        // Use BigDecimal for conversion to prevent precision issues with decimal
        // digits when converting from float to double.
        BigDecimal bigDecimal = BigDecimal.valueOf(getPlayerBufferDuration());
        return TXCommonUtil.doubleMsgWith(bigDecimal.doubleValue());
    }

    @NonNull
    @Override
    public DoubleMsg getPlayableDuration(@NonNull PlayerMsg playerMsg) {
        // Use BigDecimal for conversion to prevent precision issues with decimal
        // digits when converting from float to double.
        BigDecimal bigDecimal = BigDecimal.valueOf(getPlayerPlayableDuration());
        return TXCommonUtil.doubleMsgWith(bigDecimal.doubleValue());
    }

    @NonNull
    @Override
    public IntMsg getWidth(@NonNull PlayerMsg playerMsg) {
        return TXCommonUtil.intMsgWith((long) getPlayerWidth());
    }

    @NonNull
    @Override
    public IntMsg getHeight(@NonNull PlayerMsg playerMsg) {
        return TXCommonUtil.intMsgWith((long) getPlayerHeight());
    }

    @Override
    public void setToken(@NonNull StringPlayerMsg token) {
        setPlayerToken(token.getValue());
    }

    @NonNull
    @Override
    public BoolMsg isLoop(@NonNull PlayerMsg playerMsg) {
        return TXCommonUtil.boolMsgWith(isVodPlayerLoop());
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
        mPipManager.addCallback(getPlayerId(), mPipCallback);
        FTXPIPManager.PipParams pipParams = new FTXPIPManager.PipParams(
                mPipManager.toAndroidPath(pipParamsMsg.getBackIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPlayIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPauseIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getForwardIconForAndroid()),
                getPlayerId());
        pipParams.setIsPlaying(isPlayerPlaying());
        pipParams.setCurrentPlayTime(getPlayerCurrentPlaybackTime());
        int pipResult = FTXEvent.ERROR_PIP_MISS_PLAYER;
        if (null != mVodPlayer) {
            pipParams.setRadio(mVodPlayer.getWidth(), mVodPlayer.getHeight());
            pipResult = mPipManager.enterPip(pipParams, new TXPlayerHolder(mVodPlayer));
            // After successful startup, pause the current interface video.
            if (pipResult == FTXEvent.NO_ERROR) {
                playerPause();
            }
        }
        return TXCommonUtil.intMsgWith((long) pipResult);
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        mPipManager.exitPipByPlayerId(getPlayerId());
    }

    @Override
    public void initImageSprite(@NonNull StringListPlayerMsg spriteInfo) {
        releaseTXImageSprite();
        mTxImageSprite = new TXImageSprite(mFlutterPluginBinding.getApplicationContext());
        mTxImageSprite.setVTTUrlAndImageUrls(spriteInfo.getVvtUrl(), spriteInfo.getImageUrls());
    }

    @NonNull
    @Override
    public UInt8ListMsg getImageSprite(@NonNull DoublePlayerMsg time) {
        if (null != time.getValue()) {
            return TXCommonUtil.uInt8ListMsg(getPlayerImageSprite(time.getValue()));
        }
        return TXCommonUtil.uInt8ListMsg(new byte[0]);
    }

    @NonNull
    @Override
    public DoubleMsg getDuration(@NonNull PlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            // Use BigDecimal for conversion to prevent precision issues with decimal
            // digits when converting from float to double.
            BigDecimal bigDecimal = BigDecimal.valueOf(mVodPlayer.getDuration());
            return TXCommonUtil.doubleMsgWith(bigDecimal.doubleValue());
        }
        return TXCommonUtil.doubleMsgWith(0D);
    }

    @Override
    public void addSubtitleSource(@NonNull FtxMessages.SubTitlePlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            mVodPlayer.addSubtitleSource(playerMsg.getUrl(), playerMsg.getName(), playerMsg.getMimeType());
        }
    }

    @NonNull
    @Override
    public ListMsg getSubtitleTrackInfo(@NonNull PlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            List<TXTrackInfo> trackInfoList = mVodPlayer.getSubtitleTrackInfo();
            List<Object> json = new ArrayList<>();
            for (TXTrackInfo trackInfo : trackInfoList) {
                Map<Object, Object> map = new HashMap<>();
                map.put("trackType", trackInfo.trackType);
                map.put("trackIndex", trackInfo.trackIndex);
                map.put("name", trackInfo.name);
                map.put("isSelected", trackInfo.isSelected);
                map.put("isExclusive", trackInfo.isExclusive);
                map.put("isInternal", trackInfo.isInternal);
                json.add(map);
            }
            return TXCommonUtil.listMsgWith(json);
        }
        return TXCommonUtil.listMsgWith(Collections.emptyList());
    }

    @NonNull
    @Override
    public ListMsg getAudioTrackInfo(@NonNull PlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            List<TXTrackInfo> trackInfoList = mVodPlayer.getAudioTrackInfo();
            List<Object> json = new ArrayList<>();
            for (TXTrackInfo trackInfo : trackInfoList) {
                Map<Object, Object> map = new HashMap<>();
                map.put("trackType", trackInfo.trackType);
                map.put("trackIndex", trackInfo.trackIndex);
                map.put("name", trackInfo.name);
                map.put("isSelected", trackInfo.isSelected);
                map.put("isExclusive", trackInfo.isExclusive);
                map.put("isInternal", trackInfo.isInternal);
                json.add(map);
            }
            return TXCommonUtil.listMsgWith(json);
        }
        return TXCommonUtil.listMsgWith(Collections.emptyList());
    }

    @Override
    public void selectTrack(@NonNull IntPlayerMsg playerMsg) {
        if (null != mVodPlayer && null != playerMsg.getValue()) {
            mVodPlayer.selectTrack(playerMsg.getValue().intValue());
        }
    }

    @Override
    public void deselectTrack(@NonNull IntPlayerMsg playerMsg) {
        if (null != mVodPlayer && null != playerMsg.getValue()) {
            mVodPlayer.deselectTrack(playerMsg.getValue().intValue());
        }
    }

    @Override
    public void setSubtitleStyle(@NonNull FtxMessages.SubTitleRenderModelPlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            mVodPlayer.setSubtitleStyle(FTXTransformation.transToTitleRenderModel(playerMsg));
        }
    }

    @Override
    public void setStringOption(@NonNull FtxMessages.StringOptionPlayerMsg playerMsg) {
        if (null != mVodPlayer) {
            List<Object> values = playerMsg.getValue();
            if (null != values && !values.isEmpty()) {
                Object value = values.get(0);
                mVodPlayer.setStringOption(playerMsg.getKey(), value);
            }
        }
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
            updateTextureRenderMode(renderMode);
        }
    }

    @Override
    public long getPlayerRenderMode() {
        return mCurrentRenderMode;
    }

    @Override
    public float getRotation() {
        return mCurrentRotation;
    }

    @Override
    public int getVideoWidth() {
        if (null != mVodPlayer) {
            return mVodPlayer.getWidth();
        }
        return 0;
    }

    @Override
    public int getVideoHeight() {
        if (null != mVodPlayer) {
            return mVodPlayer.getHeight();
        }
        return 0;
    }

    @Override
    public void success() {

    }

    @Override
    public void error(@NonNull Throwable error) {
        LiteavLog.e(TAG, "callback message error:" + error);
    }

    @Override
    protected TXVodPlayer getVodPlayer() {
        return mVodPlayer;
    }
}
