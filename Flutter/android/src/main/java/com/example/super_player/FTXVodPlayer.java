package com.example.super_player;

import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.view.Surface;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

import com.tencent.rtmp.ITXLivePlayListener;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXBitrateItem;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXPlayerAuthBuilder;
import com.tencent.rtmp.TXVodPlayer;

public class FTXVodPlayer extends FTXBasePlayer implements MethodChannel.MethodCallHandler, ITXVodPlayListener  {

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;

    final private MethodChannel mMethodChannel;
    private final EventChannel mEventChannel;
    private final EventChannel mNetChannel;

    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    final private FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    final private FTXPlayerEventSink mNetStatusSink = new FTXPlayerEventSink();

    private TXVodPlayer mVodPlayer;

    private static final int Uninitialized = -101;
    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;

    public FTXVodPlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super();
        mFlutterPluginBinding = flutterPluginBinding;

        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txvodplayer/" + super.getPlayerId());
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txvodplayer/event/" + super.getPlayerId());
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

        mNetChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txvodplayer/net/" + super.getPlayerId());
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
    public void destory() {
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
    }

    @Override
    public void onPlayEvent(TXVodPlayer txVodPlayer, int i, Bundle bundle) {
        mEventSink.success(getParams(i, bundle));
    }

    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {
        mNetStatusSink.success(getParams(0, bundle));
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
            int r = startPlay(url);
            result.success(r);
        }else if(call.method.equals("startPlayWithParams")){
            int r = startPlayWithParams(call);
            result.success(r);
        } else if(call.method.equals("stop")){
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
        }else if(call.method.equals("setLoop")){
            boolean loop = call.argument("loop");
            setLoop(loop);
            result.success(null);
        }else if (call.method.equals("seek")) {
            double progress = call.argument("progress");
            seek((float) progress);
            result.success(null);
        }else if (call.method.equals("setRate")) {
            double rate = call.argument("rate");
            setRate((float) rate);
            result.success(null);
        }else if(call.method.equals("getSupportedBitrates")) {
            List bitrates = getSupportedBitrates();
            result.success(bitrates);
        }else if(call.method.equals("setBitrateIndex")) {
            int index = call.argument("index");
            setBitrateIndex(index);
            result.success(null);
        }else if(call.method.equals("setStartTime")) {
            double startTime = call.argument("startTime");
            setStartTime(startTime);
            result.success(null);
        }else if(call.method.equals("setAudioPlayoutVolume")) {
            Integer volume = call.argument("volume");
            setAudioPlayoutVolume(volume);
            result.success(null);
        }else if(call.method.equals("setRenderRotation")) {
            int rotation = call.argument("rotation");
            setRenderRotation(rotation);
            result.success(null);
        }else if(call.method.equals("setMirror")){
            boolean isMirror = call.argument("isMirror");
            setMirror(isMirror);
            result.success(null);
        }else {
            result.notImplemented();
        }
    }

    protected long init(boolean onlyAudio) {
        if (mVodPlayer == null) {
            mVodPlayer = new TXVodPlayer(mFlutterPluginBinding.getApplicationContext());
            mVodPlayer.setVodListener(this);
            setPlayer(onlyAudio);
        }
//        Log.d("AndroidLog", "textureId :" + mSurfaceTextureEntry.id());
        return mSurfaceTextureEntry == null ? -1 : mSurfaceTextureEntry.id();
    }

    void setPlayer(boolean onlyAudio) {
        if (!onlyAudio) {
            mSurfaceTextureEntry =  mFlutterPluginBinding.getTextureRegistry().createSurfaceTexture();
            mSurfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            mSurface = new Surface(mSurfaceTexture);

            if (mVodPlayer != null) {
                mVodPlayer.setSurface(mSurface);
                mVodPlayer.enableHardwareDecode(true);
            }
        }
    }

    int startPlay(String url) {
        if (mVodPlayer != null) {
            return mVodPlayer.startPlay(url);
        }
        return Uninitialized;
    }

    int startPlayWithParams(MethodCall call) {
        if (mVodPlayer != null) {
            TXPlayerAuthBuilder builder = new TXPlayerAuthBuilder();
            int appId = call.argument("appId");
            builder.setAppId(appId);
            String fileId = call.argument("fileId");
            builder.setFileId(fileId);
            String timeout = call.argument("timeout");
            if (!timeout.isEmpty()) {
                builder.setTimeout(timeout);
            }
            int exper = call.argument("exper");
            builder.setExper(exper);

            String us = call.argument("us");
            if (!us.isEmpty()) {
                builder.setUs(us);
            }

            String sign = call.argument("sign");
            if (!sign.isEmpty()) {
                builder.setSign(sign);
            }

            boolean https = call.argument("https");
            builder.setHttps(https);

            return mVodPlayer.startPlay(builder);

        }
        return Uninitialized;
    }

    int stopPlay(boolean isNeedClearLastImg) {
        if (mVodPlayer != null) {
            return mVodPlayer.stopPlay(isNeedClearLastImg);
        }
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
        if (mVodPlayer != null){
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

    List getSupportedBitrates() {
        if (mVodPlayer != null) {
            ArrayList<TXBitrateItem> bitrates = mVodPlayer.getSupportedBitrates();
            ArrayList<Map> jsons = new ArrayList<Map>();
            for (TXBitrateItem item:
                    bitrates) {
                Map map = new HashMap();
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

    private Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap();
        if (event != 0) {
            param.put("event", event);
        }

        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }

        return param;
    }
}
