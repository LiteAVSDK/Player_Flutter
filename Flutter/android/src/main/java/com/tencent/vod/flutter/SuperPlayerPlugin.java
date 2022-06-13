// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.util.SparseArray;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXPlayerGlobalSetting;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * SuperPlayerPlugin
 * <p>
 * The MethodChannel that will the communication between Flutter and native Android
 * This local reference serves to register the plugin with the Flutter Engine and unregister it
 * when the Flutter Engine is detached from the Activity
 */
public class SuperPlayerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    static final         String TAG                      = "SuperPlayerPlugin";
    private static final String VOLUME_CHANGED_ACTION    = "android.media.VOLUME_CHANGED_ACTION";
    private static final String EXTRA_VOLUME_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE";

    private EventChannel            mEventChannel;
    private FTXPlayerEventSink      mEventSink = new FTXPlayerEventSink();
    private VolumeBroadcastReceiver mVolumeBroadcastReceiver;

    private MethodChannel              channel;
    private FlutterPluginBinding       mFlutterPluginBinding;
    private ActivityPluginBinding      mActivityPluginBinding;
    private SparseArray<FTXBasePlayer> mPlayers;

    private AudioManager      mAudioManager;
    private AudioFocusRequest mFocusRequest;
    private AudioAttributes   mAudioAttributes;
    private int               volumeUIFlag = 0;

    AudioManager.OnAudioFocusChangeListener afChangeListener =
            new AudioManager.OnAudioFocusChangeListener() {
                public void onAudioFocusChange(int focusChange) {
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
                        //长时间丢失焦点,当其他应用申请的焦点为AUDIOFOCUS_GAIN时，会触发此回调事件
                        //例如播放QQ音乐，网易云音乐等
                        //此时应当暂停音频并释放音频相关的资源。
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        //短暂性丢失焦点，当其他应用申请AUDIOFOCUS_GAIN_TRANSIENT或AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE时，会触发此回调事件
                        //例如播放短视频，拨打电话等。
                        //通常需要暂停音乐播放
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
                        //短暂性丢失焦点并作降音处理，当其他应用申请AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK时，会触发此回调事件
                        //通常需要降低音量
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                        //当其他应用申请焦点之后又释放焦点会触发此回调
                        //可重新播放音乐
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPlay();
                            }
                        });
                    }
                }
            };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_super_player");
        channel.setMethodCallHandler(this);
        mPlayers = new SparseArray();

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent" +
                ".com/playerPlugin/event");
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
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("createVodPlayer")) {
            FTXVodPlayer player = new FTXVodPlayer(mFlutterPluginBinding);
            int playerId = player.getPlayerId();
            mPlayers.append(playerId, player);
            result.success(playerId);
        } else if (call.method.equals("createLivePlayer")) {
            FTXLivePlayer player = new FTXLivePlayer(mFlutterPluginBinding, mActivityPluginBinding.getActivity());
            int playerId = player.getPlayerId();
            mPlayers.append(playerId, player);
            result.success(playerId);
        } else if (call.method.equals("releasePlayer")) {
            Integer playerId = call.argument("playerId");
            FTXBasePlayer player = mPlayers.get(playerId);
            if (player != null) {
                player.destroy();
                mPlayers.remove(playerId);
            }
            result.success(null);
        } else if (call.method.equals("setConsoleEnabled")) {
            boolean enabled = call.argument("enabled");
            TXLiveBase.setConsoleEnabled(enabled);
            result.success(null);
        } else if (call.method.equals("setGlobalMaxCacheSize")) {
            Integer size = call.argument("size");
            if (null != size && size > 0) {
                TXPlayerGlobalSetting.setMaxCacheSize(size);
            }
            result.success(null);
        } else if (call.method.equals("setGlobalCacheFolderPath")) {
            String path = call.argument("path");
            if (!TextUtils.isEmpty(path)) {
                TXPlayerGlobalSetting.setCacheFolderPath(path);
            }
            result.success(null);
        } else if (call.method.equals("setGlobalLicense")) {
            String licenceUrl = call.argument("licenceUrl");
            String licenceKey = call.argument("licenceKey");
            TXLiveBase.getInstance().setLicence(mFlutterPluginBinding.getApplicationContext(), licenceUrl, licenceKey);
            result.success(null);
        } else if (call.method.equals("setBrightness")) {
            Double brightness = call.argument("brightness");
            if (null != brightness) {
                Window window = mActivityPluginBinding.getActivity().getWindow();
                WindowManager.LayoutParams params = window.getAttributes();
                params.screenBrightness = Float.parseFloat(String.valueOf(brightness));
                if (params.screenBrightness > 1.0f) {
                    params.screenBrightness = 1.0f;
                }
                if (params.screenBrightness != -1 && params.screenBrightness < 0) {
                    params.screenBrightness = 0.01f;
                }
                window.setAttributes(params);
            }
            result.success(null);
        } else if (call.method.equals("getBrightness")) {
            Window window = mActivityPluginBinding.getActivity().getWindow();
            WindowManager.LayoutParams params = window.getAttributes();
            result.success(params.screenBrightness);
        } else if (call.method.equals("getSystemVolume")) {
            result.success(getSystemCurrentVolume());
        } else if (call.method.equals("setSystemVolume")) {
            initAudioManagerIfNeed();
            Double volume = call.argument("volume");
            if (null != volume) {
                if (volume < 0) {
                    volume = 0d;
                }
                if (volume > 1) {
                    volume = 1d;
                }
                int maxVolume = mAudioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                int newVolume = (int) (volume * maxVolume);
                mAudioManager.setStreamVolume(AudioManager.STREAM_MUSIC, newVolume, volumeUIFlag);
            }
            result.success(null);
        } else if (call.method.equals("abandonAudioFocus")) {
            abandonAudioFocus();
            result.success(null);
        } else if (call.method.equals("requestAudioFocus")) {
            requestAudioFocus();
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    private void initAudioManagerIfNeed() {
        if (null == mAudioManager) {
            mAudioManager =
                    (AudioManager) mFlutterPluginBinding.getApplicationContext().getSystemService(Context.AUDIO_SERVICE);
        }
    }

    private void setVolumeUIVisible(boolean visible) {
        if (visible) {
            volumeUIFlag = AudioManager.FLAG_SHOW_UI;
        } else {
            volumeUIFlag = 0;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        mFlutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivityPluginBinding = binding;
        registerReceiver();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
        unregisterReceiver();
    }

    private float getSystemCurrentVolume() {
        initAudioManagerIfNeed();
        int curVolume = mAudioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        int maxVolume = mAudioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        return (float) curVolume / maxVolume;
    }

    void abandonAudioFocus() {
        initAudioManagerIfNeed();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (mFocusRequest != null) {
                mAudioManager.abandonAudioFocusRequest(mFocusRequest);
            }
        } else {
            if (afChangeListener != null) {
                mAudioManager.abandonAudioFocus(afChangeListener);
            }
        }
    }

    void requestAudioFocus() {
        initAudioManagerIfNeed();
        int result;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (mFocusRequest == null) {
                if (mAudioAttributes == null) {
                    mAudioAttributes = new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_GAME)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build();
                }
                mFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(mAudioAttributes)
                        .setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener(afChangeListener)
                        .build();
            }
            result = mAudioManager.requestAudioFocus(mFocusRequest);
        } else {
            result = mAudioManager.requestAudioFocus(afChangeListener, AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN);
        }
        Log.e(TAG, "requestAudioFocus result:" + result);
    }

    void onAudioFocusPause() {
        mEventSink.success(getParams(FTXEvent.EVENT_AUDIO_FOCUS_PAUSE, null));
    }

    void onAudioFocusPlay() {
        mEventSink.success(getParams(FTXEvent.EVENT_AUDIO_FOCUS_PLAY, null));
    }

    /**
     * 注册音量广播接收器
     *
     * @return
     */
    public void registerReceiver() {
        mVolumeBroadcastReceiver = new VolumeBroadcastReceiver();
        IntentFilter filter = new IntentFilter();
        filter.addAction(VOLUME_CHANGED_ACTION);
        mActivityPluginBinding.getActivity().registerReceiver(mVolumeBroadcastReceiver, filter);
    }

    /**
     * 反注册音量广播监听器，需要与 registerReceiver 成对使用
     */
    public void unregisterReceiver() {
        try {
            mActivityPluginBinding.getActivity().unregisterReceiver(mVolumeBroadcastReceiver);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap<>();
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

    private class VolumeBroadcastReceiver extends BroadcastReceiver {

        public void onReceive(Context context, Intent intent) {
            //媒体音量改变才通知
            if (VOLUME_CHANGED_ACTION.equals(intent.getAction())
                    && (intent.getIntExtra(EXTRA_VOLUME_STREAM_TYPE, -1) == AudioManager.STREAM_MUSIC)) {
                mEventSink.success(getParams(FTXEvent.EVENT_VOLUME_CHANGED, null));
            }
        }
    }
}
