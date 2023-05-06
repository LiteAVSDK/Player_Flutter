// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.database.ContentObserver;
import android.media.AudioManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.provider.Settings.SettingNotFoundException;
import android.text.TextUtils;
import android.util.Log;
import android.util.SparseArray;
import android.view.OrientationEventListener;
import android.view.Window;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXPlayerGlobalSetting;
import com.tencent.vod.flutter.messages.FTXLivePlayerDispatcher;
import com.tencent.vod.flutter.messages.FTXVodPlayerDispatcher;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoubleMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.LicenseMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterLivePlayerApi;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterNativeAPI;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterSuperPlayerPluginAPI;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterVodPlayerApi;
import com.tencent.vod.flutter.ui.Android12BridgeService;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import java.io.File;
import java.math.BigDecimal;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * SuperPlayerPlugin
 * <p>
 * The MethodChannel that will the communication between Flutter and native Android
 * This local reference serves to register the plugin with the Flutter Engine and unregister it
 * when the Flutter Engine is detached from the Activity
 * </p>
 */
public class SuperPlayerPlugin implements FlutterPlugin, ActivityAware,
        TXFlutterSuperPlayerPluginAPI, TXFlutterNativeAPI {

    static final String TAG = "SuperPlayerPlugin";
    private static final String VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION";
    private static final String EXTRA_VOLUME_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE";

    private EventChannel mEventChannel;
    private FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    private VolumeBroadcastReceiver mVolumeBroadcastReceiver;

    private FlutterPluginBinding mFlutterPluginBinding;
    private ActivityPluginBinding mActivityPluginBinding;
    private SparseArray<FTXBasePlayer> mPlayers;

    private FTXDownloadManager mFTXDownloadManager;
    private FTXAudioManager mTxAudioManager;
    private FTXPIPManager mTxPipManager;

    private OrientationEventListener mOrientationManager;
    private int mCurrentOrientation = FTXEvent.ORIENTATION_PORTRAIT_UP;

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

    private final ContentObserver brightnessObserver = new ContentObserver(new Handler(Looper.getMainLooper())) {
        @Override
        public void onChange(boolean selfChange, @NonNull Collection<Uri> uris, int flags) {
            super.onChange(selfChange, uris, flags);
            double systemBrightness = getSystemScreenBrightness();
            setWindowBrightness(systemBrightness);
        }
    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine");
        TXFlutterSuperPlayerPluginAPI.setup(flutterPluginBinding.getBinaryMessenger(), this);
        TXFlutterNativeAPI.setup(flutterPluginBinding.getBinaryMessenger(), this);
        TXFlutterVodPlayerApi.setup(flutterPluginBinding.getBinaryMessenger(), new FTXVodPlayerDispatcher(
                () -> mPlayers));
        TXFlutterLivePlayerApi.setup(flutterPluginBinding.getBinaryMessenger(), new FTXLivePlayerDispatcher(
                () -> mPlayers));
        mFlutterPluginBinding = flutterPluginBinding;
        mPlayers = new SparseArray<>();
        initAudioManagerIfNeed();
        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
                "cloud.tencent.com/playerPlugin/event");
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
        mFTXDownloadManager = new FTXDownloadManager(flutterPluginBinding);
    }

    /******* native method call start *******/

    @NonNull
    @Override
    public StringMsg getPlatformVersion() {
        StringMsg stringMsg = new StringMsg();
        stringMsg.setValue("Android " + android.os.Build.VERSION.RELEASE);
        return stringMsg;
    }

    @NonNull
    @Override
    public PlayerMsg createVodPlayer() {
        FTXVodPlayer player = new FTXVodPlayer(mFlutterPluginBinding, mTxPipManager);
        int playerId = player.getPlayerId();
        mPlayers.append(playerId, player);
        PlayerMsg playerMsg = new PlayerMsg();
        playerMsg.setPlayerId((long) playerId);
        return playerMsg;
    }

    @NonNull
    @Override
    public PlayerMsg createLivePlayer() {
        FTXLivePlayer player = new FTXLivePlayer(mFlutterPluginBinding, mTxPipManager);
        int playerId = player.getPlayerId();
        mPlayers.append(playerId, player);
        PlayerMsg playerMsg = new PlayerMsg();
        playerMsg.setPlayerId((long) playerId);
        return playerMsg;
    }

    @Override
    public void setConsoleEnabled(@NonNull BoolMsg enabled) {
        if (enabled.getValue() != null) {
            TXLiveBase.setConsoleEnabled(enabled.getValue());
        }
    }

    @Override
    public void releasePlayer(@NonNull PlayerMsg playerId) {
        if (null != playerId.getPlayerId()) {
            int intPlayerId = playerId.getPlayerId().intValue();
            FTXBasePlayer player = mPlayers.get(intPlayerId);
            if (player != null) {
                player.destroy();
                mPlayers.remove(intPlayerId);
            }
        }
    }

    @Override
    public void setGlobalMaxCacheSize(@NonNull IntMsg size) {
        if (null != size.getValue() && size.getValue() > 0) {
            TXPlayerGlobalSetting.setMaxCacheSize(size.getValue().intValue());
        }
    }

    @NonNull
    @Override
    public BoolMsg setGlobalCacheFolderPath(@NonNull StringMsg postfixPath) {
        boolean configResult = false;
        if (!TextUtils.isEmpty(postfixPath.getValue())) {
            File sdcardDir = mFlutterPluginBinding.getApplicationContext().getExternalFilesDir(null);
            if (null != sdcardDir) {
                TXPlayerGlobalSetting.setCacheFolderPath(sdcardDir.getPath() + File.separator + postfixPath.getValue());
                configResult = true;
            }
        }
        BoolMsg boolMsg = new BoolMsg();
        boolMsg.setValue(configResult);
        return boolMsg;
    }

    @Override
    public void setGlobalLicense(@NonNull LicenseMsg licenseMsg) {
        TXLiveBase.getInstance().setLicence(mFlutterPluginBinding.getApplicationContext(), licenseMsg.getLicenseUrl(),
                licenseMsg.getLicenseKey());
    }

    @Override
    public void setLogLevel(@NonNull IntMsg logLevel) {
        if (null != logLevel.getValue()) {
            TXLiveBase.setLogLevel(logLevel.getValue().intValue());
        }
    }

    @NonNull
    @Override
    public StringMsg getLiteAVSDKVersion() {
        StringMsg stringMsg = new StringMsg();
        stringMsg.setValue(TXLiveBase.getSDKVersionStr());
        return stringMsg;
    }

    @NonNull
    @Override
    public IntMsg setGlobalEnv(@NonNull StringMsg envConfig) {
        int setResult = TXLiveBase.setGlobalEnv(envConfig.getValue());
        IntMsg intMsg = new IntMsg();
        intMsg.setValue((long) setResult);
        return intMsg;
    }

    @NonNull
    @Override
    public BoolMsg startVideoOrientationService() {
        boolean setResult = innerStartVideoOrientationService();
        BoolMsg boolMsg = new BoolMsg();
        boolMsg.setValue(setResult);
        return boolMsg;
    }

    /******* native method call end *******/


    private boolean innerStartVideoOrientationService() {
        if (null == mFlutterPluginBinding) {
            return false;
        }
        if (null == mOrientationManager) {
            try {
                mOrientationManager = new OrientationEventListener(mFlutterPluginBinding.getApplicationContext()) {
                    @Override
                    public void onOrientationChanged(int orientation) {
                        if (isDeviceAutoRotateOn()) {
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
            } catch (Exception e) {
                Log.getStackTraceString(e);
                return false;
            }
        }
        return true;
    }

    /**
     * 设置当前window亮度
     */
    private void setWindowBrightness(Double brightness) {
        if (null != brightness) {
            // 保留两位小数
            BigDecimal bigDecimal = new BigDecimal(brightness);
            brightness = bigDecimal.setScale(2, BigDecimal.ROUND_HALF_UP).doubleValue();
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
            // 发送亮度变化通知
            mEventSink.success(getParams(FTXEvent.EVENT_BRIGHTNESS_CHANGED, null));
        }
    }

    /**
     * 获得当前window亮度，如果当前window亮度未赋值，则返回当前系统亮度
     */
    private float getWindowBrightness() {
        Window window = mActivityPluginBinding.getActivity().getWindow();
        WindowManager.LayoutParams params = window.getAttributes();
        float screenBrightness = params.screenBrightness;
        if (screenBrightness < 0) {
            screenBrightness = getSystemScreenBrightness();
        }
        // 保留两位小数
        BigDecimal bigDecimal = new BigDecimal(screenBrightness);
        bigDecimal = bigDecimal.setScale(2, BigDecimal.ROUND_HALF_UP);
        return bigDecimal.floatValue();
    }

    private float getSystemScreenBrightness() {
        float screenBrightness = -1;
        try {
            ContentResolver resolver = mActivityPluginBinding.getActivity().getContentResolver();
            int brightnessInt = Settings.System.getInt(resolver, Settings.System.SCREEN_BRIGHTNESS);
            screenBrightness = brightnessInt / 255F;
        } catch (SettingNotFoundException e) {
            e.printStackTrace();
        }
        return screenBrightness;
    }

    private void initAudioManagerIfNeed() {
        if (null == mTxAudioManager) {
            mTxAudioManager = new FTXAudioManager(mFlutterPluginBinding.getApplicationContext());
            mTxAudioManager.addAudioFocusChangedListener(audioFocusChangeListener);
        }
    }

    private void initPipManagerIfNeed() {
        if (null == mTxPipManager) {
            mTxPipManager = new FTXPIPManager(mTxAudioManager, mFlutterPluginBinding, mActivityPluginBinding,
                    mFlutterPluginBinding.getFlutterAssets());
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.i(TAG, "onAttachedToEngine");
        mFTXDownloadManager.destroy();
        mFlutterPluginBinding = null;
        if (null != mOrientationManager) {
            mOrientationManager.disable();
        }
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
            mTxPipManager.releaseActivityListener();
        }
        // 关闭用于解决Android12部分版本上画中画点击还原失灵的问题
        Intent serviceIntent = new Intent(mActivityPluginBinding.getActivity(), Android12BridgeService.class);
        mActivityPluginBinding.getActivity().stopService(serviceIntent);
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
    protected boolean isDeviceAutoRotateOn() {
        //获取系统是否允许自动旋转屏幕
        try {
            return (android.provider.Settings.System.getInt(
                    mFlutterPluginBinding.getApplicationContext().getContentResolver(),
                    Settings.System.ACCELEROMETER_ROTATION, 0) == 1);
        } catch (Exception e) {
            Log.getStackTraceString(e);
            return false;
        }
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
        // brightness observer
        ContentResolver resolver = mActivityPluginBinding.getActivity().getContentResolver();
        resolver.registerContentObserver(Settings.System.getUriFor(Settings.System.SCREEN_BRIGHTNESS),
                true, brightnessObserver);
    }

    /**
     * 反注册音量广播监听器，需要与 registerReceiver 成对使用
     */
    public void unregisterReceiver() {
        try {
            mTxAudioManager.removeAudioFocusChangedListener(audioFocusChangeListener);
            mActivityPluginBinding.getActivity().unregisterReceiver(mVolumeBroadcastReceiver);
            mActivityPluginBinding.getActivity().getContentResolver().unregisterContentObserver(brightnessObserver);
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

    @Override
    public void setBrightness(@NonNull DoubleMsg brightness) {
        setWindowBrightness(brightness.getValue());
    }

    @Override
    public void restorePageBrightness() {
        setWindowBrightness(-1D);
    }

    @NonNull
    @Override
    public DoubleMsg getBrightness() {
        float brightness = getWindowBrightness();
        BigDecimal bigDecimal = BigDecimal.valueOf(brightness);
        DoubleMsg doubleMsg = new DoubleMsg();
        doubleMsg.setValue(bigDecimal.doubleValue());
        return doubleMsg;
    }

    @NonNull
    @Override
    public DoubleMsg getSysBrightness() {
        float brightness = getSystemScreenBrightness();
        BigDecimal bigDecimal = BigDecimal.valueOf(brightness);
        DoubleMsg doubleMsg = new DoubleMsg();
        doubleMsg.setValue(bigDecimal.doubleValue());
        return doubleMsg;
    }

    @Override
    public void setSystemVolume(@NonNull DoubleMsg volume) {
        mTxAudioManager.setSystemVolume(volume.getValue());
    }

    @NonNull
    @Override
    public DoubleMsg getSystemVolume() {
        BigDecimal bigDecimal = BigDecimal.valueOf(mTxAudioManager.getSystemCurrentVolume());
        DoubleMsg doubleMsg = new DoubleMsg();
        doubleMsg.setValue(bigDecimal.doubleValue());
        return doubleMsg;
    }

    @Override
    public void abandonAudioFocus() {
        mTxAudioManager.abandonAudioFocus();
    }

    @Override
    public void requestAudioFocus() {
        mTxAudioManager.requestAudioFocus();
    }

    @NonNull
    @Override
    public IntMsg isDeviceSupportPip() {
        IntMsg intMsg = new IntMsg();
        intMsg.setValue((long) mTxPipManager.isSupportDevice());
        return intMsg;
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
