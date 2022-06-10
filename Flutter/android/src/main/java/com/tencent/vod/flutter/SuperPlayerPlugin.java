package com.tencent.vod.flutter;

import android.text.TextUtils;
import android.util.Log;
import android.util.SparseArray;

import androidx.annotation.NonNull;

import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXPlayerGlobalSetting;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
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

    static final         String TAG                   = "SuperPlayerPlugin";
    private static final int    SUPPORT_MAJOR_VERSION = 8;
    private static final int    SUPPORT_MINOR_VERSION = 5;

    private MethodChannel              channel;
    private FlutterPluginBinding       mFlutterPluginBinding;
    private ActivityPluginBinding      mActivityPluginBinding;
    private SparseArray<FTXBasePlayer> mPlayers;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_super_player");
        channel.setMethodCallHandler(this);
        mPlayers = new SparseArray();
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
            boolean bnabled = call.argument("enabled");
            TXLiveBase.setConsoleEnabled(bnabled);
            result.success(null);
        } else if (call.method.equals("setGlobalMaxCacheSize")) {
            Integer size = call.argument("size");
            if (null != size && size > 0) {
                TXPlayerGlobalSetting.setMaxCacheSize(size);
            }
        } else if (call.method.equals("setGlobalCacheFolderPath")) {
            String path = call.argument("path");
            if (!TextUtils.isEmpty(path)) {
                TXPlayerGlobalSetting.setCacheFolderPath(path);
            }
        } else if (call.method.equals("setGlobalLicense")) {
            String licenceUrl = call.argument("licenceUrl");
            String licenceKey = call.argument("licenceKey");
            TXLiveBase.getInstance().setLicence(mFlutterPluginBinding.getApplicationContext(), licenceUrl, licenceKey);
        } else {
            result.notImplemented();
        }
    }

    private boolean isVersionSupportAppendUrl() {
        String strVersion = TXLiveBase.getSDKVersionStr();
        String[] strVers = strVersion.split("\\.");
        if (strVers.length <= 1) {
            return false;
        }
        int majorVer = 0;
        int minorVer = 0;
        try {
            majorVer = Integer.parseInt(strVers[0]);
            minorVer = Integer.parseInt(strVers[1]);
        } catch (NumberFormatException e) {
            Log.e(TAG, "parse version failed.", e);
            majorVer = 0;
            minorVer = 0;
        }
        Log.i(TAG, strVersion + " , " + majorVer + " , " + minorVer);
        return majorVer > SUPPORT_MAJOR_VERSION || (majorVer == SUPPORT_MAJOR_VERSION && minorVer >= SUPPORT_MINOR_VERSION);
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        mFlutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivityPluginBinding = binding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
