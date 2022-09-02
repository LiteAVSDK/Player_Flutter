// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.app.Activity;
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

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

/**
 * live player processor
 */
public class FTXLivePlayer extends FTXBasePlayer implements MethodChannel.MethodCallHandler, ITXLivePlayListener {

    private static final String TAG = "FTXLivePlayer";
    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    final private MethodChannel mMethodChannel;
    private final EventChannel mEventChannel;
    private final EventChannel mNetChannel;

    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    final private FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    final private FTXPlayerEventSink mNetStatusSink = new FTXPlayerEventSink();

    private TXLivePlayer mLivePlayer;
    private static final int Uninitialized = -101;
    private boolean mEnableHardwareDecode = true;
    private boolean mHardwareDecodeFail = false;
    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    private Activity mActivity;

    private final FTXPIPManager mPipManager;
    private FTXPIPManager.PipParams mPipParams;
    private final FTXPIPManager.PipCallback pipCallback = new FTXPIPManager.PipCallback() {
        @Override
        public void onPlayBack() {
            // pip not support playback
        }

        @Override
        public void onResumeOrPlay() {
            boolean isPlaying = isPlaying();
            if (isPlaying) {
                pause();
            } else {
                resume();
            }
            // isPlaying取反，点击暂停/播放之后，播放状态会变化
            mPipManager.updatePipActions(!isPlaying, mPipParams);
        }

        @Override
        public void onPlayForward() {
            // pip not support forward
        }
    };

    public FTXLivePlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, Activity activity,
                         FTXPIPManager pipManager) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;
        mActivity = activity;
        mPipManager = pipManager;

        mSurfaceTextureEntry = mFlutterPluginBinding.getTextureRegistry().createSurfaceTexture();
        mSurfaceTexture = mSurfaceTextureEntry.surfaceTexture();
        mSurface = new Surface(mSurfaceTexture);

        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txliveplayer/" + super.getPlayerId());
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txliveplayer/event/" + super.getPlayerId());
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

        mNetChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txliveplayer/net/" + super.getPlayerId());
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

        mMethodChannel.setMethodCallHandler(null);
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
        if (mSurfaceTextureEntry != null && mSurfaceTextureEntry.surfaceTexture() != null) {
            SurfaceTexture surfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            surfaceTexture.setDefaultBufferSize(width, height);
            if (mSurface != null) {
                mSurface.release();
            }
            mSurface = new Surface(surfaceTexture);
            mLivePlayer.setSurface(mSurface);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("init")) {
            boolean onlyAudio = call.argument("onlyAudio");
            long id = init(onlyAudio);
            result.success(id);
        } else if (call.method.equals("setIsAutoPlay")) {
            boolean loop = call.argument("isAutoPlay");
            setIsAutoPlay(loop);
            result.success(null);
        } else if (call.method.equals("play")) {
            String url = call.argument("url");
            int type = call.argument("playType");
            int r = startPlay(url, type);
            result.success(r);
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
        } else if (call.method.equals("seek")) {
            result.notImplemented();
        } else if (call.method.equals("setRate")) {
            result.notImplemented();
        } else if (call.method.equals("setVolume")) {
            Integer volume = call.argument("volume");
            setVolume(volume);
            result.success(null);
        } else if (call.method.equals("setRenderRotation")) {
            int rotation = call.argument("rotation");
            setRenderRotation(rotation);
            result.success(null);
        } else if (call.method.equals("setLiveMode")) {
            int type = call.argument("type");
            setLiveMode(type);
            result.success(null);
        } else if (call.method.equals("switchStream")) {
            String url = call.argument("url");
            int switchResult = switchStream(url);
            result.success(switchResult);
        } else if (call.method.equals("setAppID")) {
            String appId = call.argument("appId");
            setAppID(appId);
            result.success(null);
        } else if (call.method.equals("prepareLiveSeek")) {
            result.notImplemented();
        } else if (call.method.equals("resumeLive")) {
            int r = resumeLive();
            result.success(r);
        } else if (call.method.equals("enableHardwareDecode")) {
            Boolean enable = call.argument("enable");
            boolean r = enableHardwareDecode(enable);
            result.success(r);
        } else if (call.method.equals("enterPictureInPictureMode")) {
            String playBackAssetPath = call.argument("backIcon");
            String playResumeAssetPath = call.argument("playIcon");
            String playPauseAssetPath = call.argument("pauseIcon");
            String playForwardAssetPath = call.argument("forwardIcon");
            mPipManager.addCallback(getPlayerId(), pipCallback);
            mPipParams = new FTXPIPManager.PipParams(playBackAssetPath, playResumeAssetPath,
                    playPauseAssetPath,
                    playForwardAssetPath, getPlayerId(), false, false, true);
            int pipResult = mPipManager.enterPip(isPlaying(), mPipParams);
            result.success(pipResult);
        } else if (call.method.equals("setConfig")) {
            Map<Object, Object> config = call.argument("config");
            setPlayConfig(config);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    protected long init(boolean onlyAudio) {
        if (mLivePlayer == null) {
            mLivePlayer = new TXLivePlayer(mActivity);
            mLivePlayer.setPlayListener(this);
        }
        Log.d("AndroidLog", "textureId :" + mSurfaceTextureEntry.id());
        return mSurfaceTextureEntry == null ? -1 : mSurfaceTextureEntry.id();
    }

    private int mSurfaceWidth, mSurfaceHeight = 0;

    int startPlay(String url, int type) {
        Log.d(TAG, "startPlay:");
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
            return mLivePlayer.startPlay(url, type);
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

    boolean isPlaying() {
        if (mLivePlayer != null) {
            return mLivePlayer.isPlaying();
        }
        return false;
    }

    void pause() {
        if (mLivePlayer != null) {
            mLivePlayer.pause();
        }
    }

    void resume() {
        if (mLivePlayer != null) {
            mLivePlayer.resume();
        }
    }

    void setMute(boolean mute) {
        if (mLivePlayer != null) {
            mLivePlayer.setMute(mute);
        }
    }

    void setVolume(int volume) {
        if (mLivePlayer != null) {
            mLivePlayer.setVolume(volume);
        }
    }

    void setIsAutoPlay(boolean isAutoPlay) {
        if (mLivePlayer != null) {
            mLivePlayer.setAutoPlay(isAutoPlay);
        }
    }

    void seek(float progress) {
        if (mLivePlayer != null) {
            mLivePlayer.seek((int) progress);
        }
    }

    void setRate(float rate) {
        if (mLivePlayer != null) {
            mLivePlayer.setRate(rate);
        }
    }

    void setRenderRotation(int rotation) {
        if (mLivePlayer != null) {
            mLivePlayer.setRenderRotation(rotation);
        }
    }

    void setLiveMode(int type) {
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

    int switchStream(String url) {
        if (mLivePlayer != null) {
            return mLivePlayer.switchStream(url);
        }
        return -1;
    }

    private void setAppID(String appId) {
        TXLiveBase.setAppID(appId);
    }

    private int prepareLiveSeek(String domain, int bizId) {
        if (mLivePlayer != null) {
            return mLivePlayer.prepareLiveSeek(domain, bizId);
        }
        return Uninitialized;
    }

    private int resumeLive() {
        if (mLivePlayer != null) {
            return mLivePlayer.resumeLive();
        }
        return Uninitialized;
    }

    private boolean enableHardwareDecode(Boolean enable) {
        if (mLivePlayer != null) {
            mEnableHardwareDecode = enable;
            return mLivePlayer.enableHardwareDecode(enable);
        }
        return false;
    }

    private void setRenderMode(int renderMode) {
        if (mLivePlayer != null) {
            mLivePlayer.setRenderMode(renderMode);
        }
    }

    void setPlayConfig(Map<Object, Object> config) {
        if (mLivePlayer != null) {
            TXLivePlayConfig playConfig = FTXTransformation.transformToLiveConfig(config);
            mLivePlayer.setConfig(playConfig);
        }
    }
}
