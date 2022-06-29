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
import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXLivePlayer;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

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

    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    private Activity mActivity;

    public FTXLivePlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, Activity activity) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;
        mActivity = activity;

        mSurfaceTextureEntry =  mFlutterPluginBinding.getTextureRegistry().createSurfaceTexture();
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
    public void onPlayEvent(int i, Bundle bundle) {
        mEventSink.success(CommonUtil.getParams(i, bundle));
    }

    @Override
    public void onNetStatus(Bundle bundle) {
        mNetStatusSink.success(CommonUtil.getParams(0, bundle));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if(call.method.equals("init")){
            boolean onlyAudio = call.argument("onlyAudio");
            long id = init(onlyAudio);
            result.success(id);
        }else if(call.method.equals("setIsAutoPlay")) {
            boolean loop = call.argument("isAutoPlay");
            setIsAutoPlay(loop);
            result.success(null);
        }else if(call.method.equals("play")){
            String url = call.argument("url");
            int type = call.argument("playType");
            int r = startPlay(url,type);
            result.success(r);
        }else if(call.method.equals("stop")){
            Boolean isNeedClear = call.argument("isNeedClear");
            int r = stopPlay(isNeedClear);
            result.success(r);
        }else if(call.method.equals("isPlaying")){
            boolean r = isPlaying();
            result.success(r);
        }else if(call.method.equals("pause")){
            pause();
            result.success(null);
        }else if(call.method.equals("resume")){
            resume();
            result.success(null);
        }else if(call.method.equals("setMute")){
            boolean mute = call.argument("mute");
            setMute(mute);
            result.success(null);
        }else if (call.method.equals("seek")) {
            result.notImplemented();
        }else if (call.method.equals("setRate")) {
            result.notImplemented();
        }else if(call.method.equals("setVolume")) {
            Integer volume = call.argument("volume");
            setVolume(volume);
            result.success(null);
        }else if(call.method.equals("setRenderRotation")) {
            int rotation = call.argument("rotation");
            setRenderRotation(rotation);
            result.success(null);
        }else if(call.method.equals("setLiveMode")){
            int type = call.argument("type");
            setLiveMode(type);
            result.success(null);
        }else if(call.method.equals("switchStream")) {
            String url = call.argument("url");
            switchStream(url);
            result.success(null);
        }else if(call.method.equals("setAppID")) {
            String appId = call.argument("appId");
            setAppID(appId);
            result.success(null);
        }else if(call.method.equals("prepareLiveSeek")) {
            result.notImplemented();
        }else if(call.method.equals("resumeLive")) {
            int r = resumeLive();
            result.success(r);
        }else {
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

    private int mSurfaceWidth,mSurfaceHeight = 0;
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
                    if(width != mSurfaceWidth || height != mSurfaceHeight){
                        Log.d(TAG, "onRenderVideoFrame: width="+texture.width+",height="+texture.height);
                        mLivePlayer.setSurfaceSize(width,height);
                        mSurfaceTexture.setDefaultBufferSize(width,height);
                        mSurfaceWidth = width;
                        mSurfaceHeight = height;
                    }
                }
            },null);
            return mLivePlayer.startPlay(url, type);
        }
        return Uninitialized;
    }

    int stopPlay(boolean isNeedClearLastImg) {
        if (mLivePlayer != null) {
            return mLivePlayer.stopPlay(isNeedClearLastImg);
        }
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
            }else if(type == 1){
                //极速模式
                config.setAutoAdjustCacheTime(true);
                config.setMinAutoAdjustCacheTime(1);
                config.setMaxAutoAdjustCacheTime(1);
            }else{
                //流畅模式
                config.setAutoAdjustCacheTime(false);
                config.setCacheTime(5);
            }

            mLivePlayer.setConfig(config);
        }
    }

    void switchStream(String url) {
        if (mLivePlayer != null) {
            mLivePlayer.switchStream(url);
        }
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

    private void setRenderMode(int renderMode) {
        if (mLivePlayer != null) {
            mLivePlayer.setRenderMode(renderMode);
        }
    }
}
