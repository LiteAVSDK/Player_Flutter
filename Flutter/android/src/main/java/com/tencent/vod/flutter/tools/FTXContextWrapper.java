package com.tencent.vod.flutter.tools;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.os.Build;

public class FTXContextWrapper {

    @SuppressLint({"UnspecifiedRegisterReceiverFlag", "WrongConstant"})
    public static void registerReceiverForNotExport(Context applicationContext, BroadcastReceiver receiver,
                                                    IntentFilter filter) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.registerReceiver(receiver, filter, 0x4);
        } else {
            applicationContext.registerReceiver(receiver, filter);
        }
    }

}
