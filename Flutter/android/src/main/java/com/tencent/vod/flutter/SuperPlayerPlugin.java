// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.os.Bundle;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.SparseArray;
import android.view.OrientationEventListener;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXPlayerGlobalSetting;

import java.io.File;
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

    private FTXDownloadManager mFTXDownloadManager;

    private FTXAudioManager mTxAudioManager;
    private FTXPIPManager   mTxPipManager;

    private OrientationEventListener mOrientationManager;
    private int                      mCurrentOrientation = FTXEvent.ORIENTATION_PORTRAIT_UP;

    private final FTXAudioManager.AudioFocusChangeListener audioFocusChangeListener =
            new FTXAudioManager.AudioFocusChangeListener() {
                @Override
                public void onAudioFocusPause() {
                    onHandleAudioFocusPause();
                }

                @Override
                public void onAudioFocusPlay() {
                    onHandleAudioFocusPlay();
                }
            };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_super_player");
        channel.setMethodCallHandler(this);
        mPlayers = new SparseArray();
        initAudioManagerIfNeed();
        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/playerPlugin/event");
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
        mFTXDownloadManager = new FTXDownloadManager(mFlutterPluginBinding);
        mOrientationManager = new OrientationEventListener(flutterPluginBinding.getApplicationContext()) {
            @Override
            public void onOrientationChanged(int orientation) {
                if (isAutoRotateOn()) {
                    int orientationEvent = mCurrentOrientation;
                    // 每个方向判断当前方向正负30度，共计60度的区间
                    if (((orientation >= 0) && (orientation < 30)) || (orientation > 330)) {
                        orientationEvent = FTXEvent.ORIENTATION_PORTRAIT_UP;
                    } else if (orientation > 240 && orientation < 300) {
                        orientationEvent = FTXEvent.ORIENTATION_LANDSCAPE_RIGHT;
                    } else if (orientation > 150 && orientation < 210) {
                        orientationEvent = FTXEvent.ORIENTATION_PORTRAIT_DOWN;
                    } else if (orientation > 60 && orientation < 110) {
                        orientationEvent = FTXEvent.ORIENTATION_LANDSCAPE_LEFT;
                    }
                    if (orientationEvent != mCurrentOrientation) {
                        mCurrentOrientation = orientationEvent;
                        Bundle bundle = new Bundle();
                        bundle.putInt(FTXEvent.EXTRA_NAME_ORIENTATION, orientationEvent);
                        mEventSink.success(getParams(FTXEvent.EVENT_ORIENTATION_CHANGED, bundle));
                    }
                }
            }
        };
        mOrientationManager.enable();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("createVodPlayer")) {
            FTXVodPlayer player = new FTXVodPlayer(mFlutterPluginBinding, mTxPipManager);
            int playerId = player.getPlayerId();
            mPlayers.append(playerId, player);
            result.success(playerId);
        } else if (call.method.equals("createLivePlayer")) {
            FTXLivePlayer player = new FTXLivePlayer(mFlutterPluginBinding, mActivityPluginBinding.getActivity(), mTxPipManager);
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
            String postfixPath = call.argument("postfixPath");
            boolean configResult = false;
            if (!TextUtils.isEmpty(postfixPath)) {
                File sdcardDir = mFlutterPluginBinding.getApplicationContext().getExternalFilesDir(null);
                if (null != sdcardDir) {
                    TXPlayerGlobalSetting.setCacheFolderPath(sdcardDir.getPath() + File.separator + postfixPath);
                    configResult = true;
                }
            }
            result.success(configResult);
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
            result.success(mTxAudioManager.getSystemCurrentVolume());
        } else if (call.method.equals("setSystemVolume")) {
            Double volume = call.argument("volume");
            mTxAudioManager.setSystemVolume(volume);
            result.success(null);
        } else if (call.method.equals("abandonAudioFocus")) {
            mTxAudioManager.abandonAudioFocus();
            result.success(null);
        } else if (call.method.equals("requestAudioFocus")) {
            mTxAudioManager.requestAudioFocus();
            result.success(null);
        } else if (call.method.equals("setLogLevel")) {
            Integer logLevel = call.argument("logLevel");
            TXLiveBase.setLogLevel(logLevel);
            result.success(null);
        } else if (call.method.equals("isDeviceSupportPip")) {
            result.success(mTxPipManager.isSupportDevice());
        } else if (call.method.equals("getLiteAVSDKVersion")) {
            result.success(TXLiveBase.getSDKVersionStr());
        } else if(call.method.equals("setGlobalEnv")) {
            String envConfig = call.argument("envConfig");
            int setResult = TXLiveBase.setGlobalEnv(envConfig);
            result.success(setResult);
        } else {
            result.notImplemented();
        }
    }

    private void initAudioManagerIfNeed() {
        if (null == mTxAudioManager) {
            mTxAudioManager = new FTXAudioManager(mFlutterPluginBinding.getApplicationContext());
            mTxAudioManager.addAudioFocusChangedListener(audioFocusChangeListener);
        }
    }

    private void initPipManagerIfNeed() {
        if (null == mTxPipManager) {
            mTxPipManager = new FTXPIPManager(mTxAudioManager, mActivityPluginBinding.getActivity(),
                    mFlutterPluginBinding.getFlutterAssets());
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        mFTXDownloadManager.destroy();
        mFlutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivityPluginBinding = binding;
        initAudioManagerIfNeed();
        initPipManagerIfNeed();
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
        if (null != mTxPipManager) {
            mTxPipManager.releaseReceiver();
        }
        if (null != mOrientationManager) {
            mOrientationManager.disable();
        }
        unregisterReceiver();
    }

    void onHandleAudioFocusPause() {
        mEventSink.success(getParams(FTXEvent.EVENT_AUDIO_FOCUS_PAUSE, null));
    }

    void onHandleAudioFocusPlay() {
        mEventSink.success(getParams(FTXEvent.EVENT_AUDIO_FOCUS_PLAY, null));
    }

    /**
     * 系统是否允许自动旋转屏幕
     *
     * @return
     */
    protected boolean isAutoRotateOn() {
        //获取系统是否允许自动旋转屏幕
        return (android.provider.Settings.System.getInt(
                mFlutterPluginBinding.getApplicationContext().getContentResolver(),
                Settings.System.ACCELEROMETER_ROTATION, 0) == 1);
    }

    /**
     * 注册音量广播接收器
     */
    public void registerReceiver() {
        // volume receiver
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
            mTxAudioManager.removeAudioFocusChangedListener(audioFocusChangeListener);
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
