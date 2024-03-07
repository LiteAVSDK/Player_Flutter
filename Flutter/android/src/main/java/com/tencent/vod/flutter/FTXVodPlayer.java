// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.Surface;
import androidx.annotation.NonNull;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXBitrateItem;
import com.tencent.rtmp.TXImageSprite;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXPlayInfoParams;
import com.tencent.rtmp.TXVodConstants;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
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
import com.tencent.vod.flutter.model.TXVideoModel;
import com.tencent.vod.flutter.tools.TXCommonUtil;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.view.TextureRegistry;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * vodPlayer plugin processor
 */
public class FTXVodPlayer extends FTXBasePlayer implements ITXVodPlayListener, FtxMessages.TXFlutterVodPlayerApi {

    private static final String TAG = "FTXVodPlayer";

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    private final EventChannel mEventChannel;
    private final EventChannel mNetChannel;

    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    private final FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    private final FTXPlayerEventSink mNetStatusSink = new FTXPlayerEventSink();

    private TXVodPlayer mVodPlayer;
    private TXImageSprite mTxImageSprite;
    private TXVideoModel mVideoModel;

    private static final int Uninitialized = -101;
    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    private boolean mEnableHardwareDecode = true;
    private boolean mHardwareDecodeFail = false;

    private final FTXPIPManager mPipManager;
    private FTXPIPManager.PipParams mPipParams;
    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(TXPipResult result) {
            float playTime = result.getPlayTime();
            float duration = mVodPlayer.getDuration();
            if (playTime > duration) {
                playTime = duration;
            }
            seekPlayer(playTime);
            // When starting PIP, the current player has been paused. After PIP exits,
            // if PIP is still in playing state, the current player will also be set to playing state.
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                playerResume();
            }
        }
    };

    /**
     * VOD player.
     *
     * 点播播放器
     */
    public FTXVodPlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager) {
        super();
        mPipManager = pipManager;
        mFlutterPluginBinding = flutterPluginBinding;
        mVideoModel = new TXVideoModel();
        mVideoModel.setPlayerType(FTXEvent.PLAYER_VOD);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent"
                + ".com/txvodplayer/event/" + super.getPlayerId());
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

        mNetChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent"
                + ".com/txvodplayer/net/" + super.getPlayerId());
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
        if (mVodPlayer != null) {
            mVodPlayer.stopPlay(true);
            mVodPlayer = null;
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
        releaseTXImageSprite();
        if (null != mPipManager) {
            mPipManager.releaseCallback(getPlayerId());
        }
    }

    @Override
    public void onPlayEvent(TXVodPlayer txVodPlayer, int event, Bundle bundle) {
        if (event == TXLiveConstants.PLAY_EVT_CHANGE_RESOLUTION) {
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
                    mEventSink.success(TXCommonUtil.getParams(event, bundle));
                    return;
                }
            }

            int width = bundle.getInt(TXLiveConstants.EVT_PARAM1, 0);
            int height = bundle.getInt(TXLiveConstants.EVT_PARAM2, 0);
            // Set the size of the surface to prevent some situations where the hardware decoding failure
            // event is not received, resulting in only 1 pixel of content.
            if (width != 0 && height != 0) {
                setDefaultBufferSizeForSoftDecode(width, height);
            }
        } else if (event == TXLiveConstants.PLAY_WARNING_HW_ACCELERATION_FAIL) {
            mHardwareDecodeFail = true;
        }
        if (event != TXVodConstants.VOD_PLAY_EVT_PLAY_PROGRESS) {
            Log.e(TAG, "onPlayEvent:" + event + "," + bundle.getString(TXLiveConstants.EVT_DESCRIPTION));
        }
        mEventSink.success(TXCommonUtil.getParams(event, bundle));
    }

    // The default size of the surface is 1x1. When hardware decoding fails or software decoding is used,
    // software decoding will depend on the window rendering of the surface. Failure to update will result
    // in only 1 pixel of content.
    private void setDefaultBufferSizeForSoftDecode(int width, int height) {
        if (null != mVodPlayer && mSurfaceTextureEntry != null) {
            SurfaceTexture surfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            surfaceTexture.setDefaultBufferSize(width, height);
            mSurface = new Surface(surfaceTexture);
            mVodPlayer.setSurface(mSurface);
        }
    }

    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {
        mNetStatusSink.success(TXCommonUtil.getParams(0, bundle));
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
            Log.e(TAG, "getImageSprite failed, time is null or initImageSprite not invoke");
        }
        return null;
    }

    private void releaseTXImageSprite() {
        if (mTxImageSprite != null) {
            mTxImageSprite.release();
            mTxImageSprite = null;
        }
    }

    protected long init(boolean onlyAudio) {
        if (mVodPlayer == null) {
            mVodPlayer = new TXVodPlayer(mFlutterPluginBinding.getApplicationContext());
            mVodPlayer.setVodListener(this);
            // prevent config null exception
            mVodPlayer.setConfig(new TXVodPlayConfig());
            setPlayer(onlyAudio);
        }
        return mSurfaceTextureEntry == null ? -1 : mSurfaceTextureEntry.id();
    }

    void setPlayer(boolean onlyAudio) {
        if (!onlyAudio) {
            mSurfaceTextureEntry = mFlutterPluginBinding.getTextureRegistry().createSurfaceTexture();
            mSurfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            mSurface = new Surface(mSurfaceTexture);

            if (mVodPlayer != null) {
                mVodPlayer.setSurface(mSurface);
            }
        }
    }

    int startPlayerVodPlay(String url) {
        if (mVodPlayer != null) {
            mVideoModel.setVideoUrl(url);
            mVideoModel.setAppId(0);
            mVideoModel.setFileId("");
            mVideoModel.setPSign("");
            return mVodPlayer.startVodPlay(url);
        }
        return Uninitialized;
    }

    void startPlayerVodPlayWithParams(int appId, String fileId, String psign) {
        if (mVodPlayer != null) {
            mVideoModel.setVideoUrl("");
            mVideoModel.setAppId(appId);
            mVideoModel.setFileId(fileId);
            mVideoModel.setPSign(psign);
            TXPlayInfoParams playInfoParams = new TXPlayInfoParams(appId, fileId, psign);
            mVodPlayer.startVodPlay(playInfoParams);
        }
    }

    int stopPlay(boolean isNeedClearLastImg) {
        if (mVodPlayer != null) {
            return mVodPlayer.stopPlay(isNeedClearLastImg);
        }
        releaseTXImageSprite();
        mHardwareDecodeFail = false;
        return Uninitialized;
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
                mVideoModel.setToken(null);
            } else {
                mVodPlayer.setToken(token);
                mVideoModel.setToken(token);
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
        mPipManager.addCallback(getPlayerId(), pipCallback);
        mPipParams = new FTXPIPManager.PipParams(
                mPipManager.toAndroidPath(pipParamsMsg.getBackIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPlayIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getPauseIconForAndroid()),
                mPipManager.toAndroidPath(pipParamsMsg.getForwardIconForAndroid()),
                getPlayerId());
        mPipParams.setIsPlaying(isPlayerPlaying());
        mPipParams.setCurrentPlayTime(getPlayerCurrentPlaybackTime());
        if (null != mVodPlayer) {
            mPipParams.setRadio(mVodPlayer.getWidth(), mVodPlayer.getHeight());
        }
        int pipResult = mPipManager.enterPip(mPipParams, mVideoModel);
        // After successful startup, pause the current interface video.
        if (pipResult == FTXEvent.NO_ERROR) {
            playerPause();
        }
        return TXCommonUtil.intMsgWith((long) pipResult);
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        mPipManager.exitPip();
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
}
