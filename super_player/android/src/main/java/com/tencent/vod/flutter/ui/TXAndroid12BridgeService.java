package com.tencent.vod.flutter.ui;


import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import androidx.annotation.Nullable;

/**
 * To solve the problem that starting picture-in-picture multiple times is considered as background startup,
 * resulting in the inability to start.
 * This problem occurs on Android 12 and is currently only found on MIUI's Android 12.
 *
 * 为了解决多次打开画中画的时候，启动画中画被认为是后台启动，导致无法启动的问题。
 * 该问题出现于android 12版本上，目前只在MIUI的android 12版本上发现该问题。
 */
public class TXAndroid12BridgeService extends Service {

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return new Android12BridgeServiceBinder();
    }

    class Android12BridgeServiceBinder extends Binder {
        public TXAndroid12BridgeService getService() {
            return TXAndroid12BridgeService.this;
        }
    }
}
