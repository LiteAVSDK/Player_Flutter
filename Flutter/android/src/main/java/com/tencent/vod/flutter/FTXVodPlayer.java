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
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXPlayInfoParams;
import com.tencent.rtmp.TXVodPlayConfig;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.model.PipResult;
import com.tencent.vod.flutter.model.VideoModel;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * vodPlayer plugin processor
 */
public class FTXVodPlayer extends FTXBasePlayer implements MethodChannel.MethodCallHandler, ITXVodPlayListener {

    private static final String TAG = "FTXVodPlayer";

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    private final MethodChannel mMethodChannel;
    private final EventChannel  mEventChannel;
    private final EventChannel  mNetChannel;

    private SurfaceTexture mSurfaceTexture;
    private Surface        mSurface;

    private final FTXPlayerEventSink mEventSink     = new FTXPlayerEventSink();
    private final FTXPlayerEventSink mNetStatusSink = new FTXPlayerEventSink();

    private TXVodPlayer mVodPlayer;
    private TXImageSprite mTxImageSprite;
    private VideoModel mVideoModel;

    private static final int                                 Uninitialized         = -101;
    private              TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    private              boolean                             mEnableHardwareDecode = true;
    private              boolean                             mHardwareDecodeFail   = false;

    private final FTXPIPManager             mPipManager;
    private       FTXPIPManager.PipParams   mPipParams;
    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPipResult(PipResult result) {
            float playTime = result.getPlayTime();
            float duration = mVodPlayer.getDuration();
            if (playTime > duration) {
                playTime = duration;
            }
            seek(playTime);
            // 启动pip的时候，当前player已经暂停，pip退出之后，如果退出的时候pip还处于播放状态，那么当前player也置为播放状态
            boolean isPipPlaying = result.isPlaying();
            if (isPipPlaying) {
                resume();
            }
        }
    };

    /**
     * 点播播放器
     */
    public FTXVodPlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, FTXPIPManager pipManager) {
        super();
        mPipManager = pipManager;
        mFlutterPluginBinding = flutterPluginBinding;
        mVideoModel = new VideoModel();
        mVideoModel.setPlayerType(FTXEvent.PLAYER_VOD);

        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent"
                + ".com/txvodplayer/" + super.getPlayerId());
        mMethodChannel.setMethodCallHandler(this);

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

        mMethodChannel.setMethodCallHandler(null);
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
                    int videoLeft = 0 - Integer.parseInt(array[2]);
                    int videoTop = 0 - Integer.parseInt(array[3]);
                    int videoRight = Integer.parseInt(array[4]) + 1 - Integer.parseInt(array[0]);
                    int videoBottom = Integer.parseInt(array[5]) + 1 - Integer.parseInt(array[1]);
                    bundle.putInt("videoWidth", videoWidth);
                    bundle.putInt("videoHeight", videoHeight);
                    bundle.putInt("videoLeft", videoLeft);
                    bundle.putInt("videoTop", videoTop);
                    bundle.putInt("videoRight", videoRight);
                    bundle.putInt("videoBottom", videoBottom);
                    mEventSink.success(CommonUtil.getParams(event, bundle));
                    return;
                }
            }

            int width = bundle.getInt(TXLiveConstants.EVT_PARAM1, 0);
            int height = bundle.getInt(TXLiveConstants.EVT_PARAM2, 0);
            // 设置surface大小，防止部分情况收不到硬解失败的事件，导致只有1px内容
            if (width != 0 && height != 0) {
                setDefaultBufferSizeForSoftDecode(width, height);
            }
        } else if (event == TXLiveConstants.PLAY_WARNING_HW_ACCELERATION_FAIL) {
            mHardwareDecodeFail = true;
        }
        mEventSink.success(CommonUtil.getParams(event, bundle));
    }

    // surface 的大小默认是宽高为1，当硬解失败时或使用软解时，软解会依赖surface的窗口渲染，不更新会导致只有1px的内容
    private void setDefaultBufferSizeForSoftDecode(int width, int height) {
        if (mSurfaceTextureEntry != null && mSurfaceTextureEntry.surfaceTexture() != null) {
            SurfaceTexture surfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            surfaceTexture.setDefaultBufferSize(width, height);
            mSurface = new Surface(surfaceTexture);
            mVodPlayer.setSurface(mSurface);
        }
    }


    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {
        mNetStatusSink.success(CommonUtil.getParams(0, bundle));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final MethodChannel.Result result) {
        if (call.method.equals("init")) {
            boolean onlyAudio = call.argument("onlyAudio");
            long id = init(onlyAudio);
            result.success(id);
        } else if (call.method.equals("setAutoPlay")) {
            boolean loop = call.argument("isAutoPlay");
            setIsAutoPlay(loop);
            result.success(null);
        } else if (call.method.equals("startVodPlay")) {
            String url = call.argument("url");
            int r = startVodPlay(url);
            result.success(r);
        } else if (call.method.equals("startVodPlayWithParams")) {
            startVodPlayWithParams(call);
            result.success(null);
        } else if (call.method.equals("stop")) {
            Boolean isNeedClear = call.argument("isNeedClear");
            int r = stopPlay(isNeedClear);
            result.success(r);
        } else if (call.method.equals("isPlaying")) {
            boolean r = isPlaying();
            result.success(r);
        } else if (call.method.equals("pause")) {
            pause();
            result.success(null);
        } else if (call.method.equals("resume")) {
            resume();
            result.success(null);
        } else if (call.method.equals("setMute")) {
            boolean mute = call.argument("mute");
            setMute(mute);
            result.success(null);
        } else if (call.method.equals("setLoop")) {
            boolean loop = call.argument("loop");
            setLoop(loop);
            result.success(null);
        } else if (call.method.equals("seek")) {
            double progress = call.argument("progress");
            seek((float) progress);
            result.success(null);
        } else if (call.method.equals("setRate")) {
            double rate = call.argument("rate");
            setRate((float) rate);
            result.success(null);
        } else if (call.method.equals("getSupportedBitrates")) {
            List bitrates = getSupportedBitrates();
            result.success(bitrates);
        } else if (call.method.equals("setBitrateIndex")) {
            int index = call.argument("index");
            setBitrateIndex(index);
            result.success(null);
        } else if (call.method.equals("setStartTime")) {
            double startTime = call.argument("startTime");
            setStartTime(startTime);
            result.success(null);
        } else if (call.method.equals("setAudioPlayoutVolume")) {
            Integer volume = call.argument("volume");
            setAudioPlayoutVolume(volume);
            result.success(null);
        } else if (call.method.equals("setRenderRotation")) {
            int rotation = call.argument("rotation");
            setRenderRotation(rotation);
            result.success(null);
        } else if (call.method.equals("setMirror")) {
            boolean isMirror = call.argument("isMirror");
            setMirror(isMirror);
            result.success(null);
        } else if (call.method.equals("setConfig")) {
            Map config = call.argument("config");
            setPlayConfig(config);
            result.success(null);
        } else if (call.method.equals("getCurrentPlaybackTime")) {
            float time = getCurrentPlaybackTime();
            result.success(time);
        } else if (call.method.equals("getBufferDuration")) {
            float time = getBufferDuration();
            result.success(time);
        } else if (call.method.equals("getWidth")) {
            int width = getWidth();
            result.success(width);
        } else if (call.method.equals("getHeight")) {
            int height = getHeight();
            result.success(height);
        } else if (call.method.equals("setToken")) {
            String token = call.argument("token");
            setToken(token);
            result.success(null);
        } else if (call.method.equals("isLoop")) {
            boolean isLoop = isVodPlayerLoop();
            result.success(isLoop);
        } else if (call.method.equals("enableHardwareDecode")) {
            boolean enable = call.argument("enable");
            boolean r = enableHardwareDecode(enable);
            result.success(r);
        } else if (call.method.equals("snapshot")) {
            snapshot(new TXLivePlayer.ITXSnapshotListener() {
                @Override
                public void onSnapshot(Bitmap bitmap) {
                    if (null != bitmap) {
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                        byte[] byteArray = stream.toByteArray();
                        result.success(byteArray);
                    } else {
                        result.success(null);
                    }
                }
            });
        } else if (call.method.equals("setRequestAudioFocus")) {
            boolean focus = call.argument("focus");
            boolean r = setRequestAudioFocus(focus);
            result.success(r);
        } else if (call.method.equals("getBitrateIndex")) {
            int index = getBitrateIndex();
            result.success(index);
        } else if (call.method.equals("getPlayableDuration")) {
            float time = getPlayableDuration();
            result.success(time);
        } else if (call.method.equals("getDuration")) {
            float duration = 0;
            if (null != mVodPlayer) {
                duration = mVodPlayer.getDuration();
            }
            result.success(duration);
        } else if (call.method.equals("enterPictureInPictureMode")) {
            String playBackAssetPath = call.argument("backIcon");
            String playResumeAssetPath = call.argument("playIcon");
            String playPauseAssetPath = call.argument("pauseIcon");
            String playForwardAssetPath = call.argument("forwardIcon");
            mPipManager.addCallback(getPlayerId(), pipCallback);
            mPipParams = new FTXPIPManager.PipParams(
                    mPipManager.toAndroidPath(playBackAssetPath),
                    mPipManager.toAndroidPath(playResumeAssetPath),
                    mPipManager.toAndroidPath(playPauseAssetPath),
                    mPipManager.toAndroidPath(playForwardAssetPath),
                    getPlayerId());
            mPipParams.setIsPlaying(isPlaying());
            mPipParams.setCurrentPlayTime(getCurrentPlaybackTime());
            int pipResult = mPipManager.enterPip(mPipParams, mVideoModel);
            // 启动成功之后，暂停当前界面视频
            if (pipResult == FTXEvent.NO_ERROR) {
                pause();
            }
            result.success(pipResult);
        } else if (call.method.equals("exitPictureInPictureMode")) {
            mPipManager.exitPip();
            result.success(null);
        } else if (call.method.equals("initImageSprite")) {
            String vvtUrl = call.argument("vvtUrl");
            List<String> imageUrls = call.argument("imageUrls");
            releaseTXImageSprite();
            mTxImageSprite = new TXImageSprite(mFlutterPluginBinding.getApplicationContext());
            mTxImageSprite.setVTTUrlAndImageUrls(vvtUrl, imageUrls);
            result.success(null);
        } else if (call.method.equals("getImageSprite")) {
            final Double time = call.argument("time");
            getImageSprite(time, result);
        } else {
            result.notImplemented();
        }
    }

    private void getImageSprite(final Double time, final MethodChannel.Result result) {
        if (mTxImageSprite != null && null != time) {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    Bitmap bitmap = mTxImageSprite.getThumbnail(time.floatValue());
                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    if (null != bitmap) {
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                        byte[] byteArray = stream.toByteArray();
                        result.success(byteArray);
                    } else {
                        result.success(null);
                    }
                }
            }).start();
        } else {
            Log.e(TAG, "getImageSprite failed, time is null or initImageSprite not invoke");
            result.success(null);
        }
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

    int startVodPlay(String url) {
        if (mVodPlayer != null) {
            mVideoModel.setVideoUrl(url);
            mVideoModel.setAppId(0);
            mVideoModel.setFileId("");
            mVideoModel.setPSign("");
            return mVodPlayer.startVodPlay(url);
        }
        return Uninitialized;
    }

    void startVodPlayWithParams(MethodCall call) {
        if (mVodPlayer != null) {
            int appId = call.argument("appId");
            String fileId = call.argument("fileId");
            String psign = call.argument("psign");
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

    boolean isPlaying() {
        if (mVodPlayer != null) {
            return mVodPlayer.isPlaying();
        }
        return false;
    }

    void pause() {
        if (mVodPlayer != null) {
            mVodPlayer.pause();
        }
    }

    void resume() {
        if (mVodPlayer != null) {
            mVodPlayer.resume();
        }
    }

    void setMute(boolean mute) {
        if (mVodPlayer != null) {
            mVodPlayer.setMute(mute);
        }
    }

    void setAudioPlayoutVolume(int volume) {
        if (mVodPlayer != null) {
            mVodPlayer.setAudioPlayoutVolume(volume);
        }
    }

    void setLoop(boolean loop) {
        if (mVodPlayer != null) {
            mVodPlayer.setLoop(loop);
        }
    }

    void setStartTime(double startTime) {
        if (mVodPlayer != null) {
            mVodPlayer.setStartTime((float) startTime);
        }
    }

    void setIsAutoPlay(boolean isAutoPlay) {
        if (mVodPlayer != null) {
            mVodPlayer.setAutoPlay(isAutoPlay);
        }
    }

    List<?> getSupportedBitrates() {
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

    void setBitrateIndex(int i) {
        if (mVodPlayer != null) {
            mVodPlayer.setBitrateIndex(i);
        }
    }

    void seek(float progress) {
        if (mVodPlayer != null) {
            mVodPlayer.seek(progress);
        }
    }

    void setRate(float rate) {
        if (mVodPlayer != null) {
            mVodPlayer.setRate(rate);
        }
    }

    void setRenderRotation(int rotation) {
        if (mVodPlayer != null) {
            mVodPlayer.setRenderRotation(rotation);
        }
    }

    void setMirror(boolean isMirror) {
        if (mVodPlayer != null) {
            mVodPlayer.setMirror(isMirror);
        }
    }

    void setPlayConfig(Map<Object, Object> config) {
        if (mVodPlayer != null) {
            TXVodPlayConfig playConfig = FTXTransformation.transformToVodConfig(config);
            mVodPlayer.setConfig(playConfig);
        }
    }

    float getCurrentPlaybackTime() {
        if (mVodPlayer != null) {
            return mVodPlayer.getCurrentPlaybackTime();
        }
        return 0;
    }

    float getPlayableDuration() {
        if (mVodPlayer != null) {
            return mVodPlayer.getPlayableDuration();
        }
        return 0;
    }

    float getBufferDuration() {
        if (mVodPlayer != null) {
            return mVodPlayer.getBufferDuration();
        }
        return 0;
    }

    int getWidth() {
        if (mVodPlayer != null) {
            return mVodPlayer.getWidth();
        }
        return 0;
    }

    int getHeight() {
        if (mVodPlayer != null) {
            return mVodPlayer.getHeight();
        }
        return 0;
    }

    void setToken(String token) {
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

    boolean enableHardwareDecode(boolean enable) {
        if (mVodPlayer != null) {
            mEnableHardwareDecode = enable;
            return mVodPlayer.enableHardwareDecode(enable);
        }
        return false;
    }

    void snapshot(TXLivePlayer.ITXSnapshotListener listener) {
        if (mVodPlayer != null) {
            mVodPlayer.snapshot(listener);
        }
    }

    // RENDER_MODE_FILL_SCREEN    = 0,    ///< 图像铺满屏幕，不留黑边，如果图像宽高比不同于屏幕宽高比，部分画面内容会被裁剪掉。
    // RENDER_MODE_FILL_EDGE      = 1,    ///< 图像适应屏幕，保持画面完整，但如果图像宽高比不同于屏幕宽高比，会有黑边的存在。
    void setRenderMode(int mode) {
        if (mVodPlayer != null) {
            mVodPlayer.setRenderMode(mode);
        }
    }

    boolean setRequestAudioFocus(boolean focus) {
        if (mVodPlayer != null) {
            return mVodPlayer.setRequestAudioFocus(focus);
        }
        return false;
    }

    int getBitrateIndex() {
        if (mVodPlayer != null) {
            return mVodPlayer.getBitrateIndex();
        }
        return -1;
    }
}
