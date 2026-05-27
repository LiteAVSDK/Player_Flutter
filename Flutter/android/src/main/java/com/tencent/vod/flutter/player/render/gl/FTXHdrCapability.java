package com.tencent.vod.flutter.player.render.gl;

import android.content.Context;
import android.os.Build;
import android.view.Display;
import android.view.WindowManager;

import com.tencent.liteav.base.util.LiteavLog;

/** Probes whether the display supports HDR10. Result is process-cached. */
public final class FTXHdrCapability {

    private static final String TAG = "FTXHdrCapability";

    private static volatile Boolean sCachedDisplayHdr10 = null;

    private FTXHdrCapability() {}

    public static boolean isDisplayHdr10(Context context) {
        Boolean cached = sCachedDisplayHdr10;
        if (cached != null) {
            return cached;
        }
        boolean result = probeDisplayHdr10(context);
        sCachedDisplayHdr10 = result;
        LiteavLog.i(TAG, "isDisplayHdr10 probed: " + result);
        return result;
    }

    private static boolean probeDisplayHdr10(Context context) {
        if (context == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false;
        }
        try {
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            if (wm == null) {
                return false;
            }
            Display display = wm.getDefaultDisplay();
            if (display == null) {
                return false;
            }
            Display.HdrCapabilities caps = display.getHdrCapabilities();
            if (caps == null) {
                return false;
            }
            int[] types = caps.getSupportedHdrTypes();
            if (types == null) {
                return false;
            }
            for (int t : types) {
                if (t == Display.HdrCapabilities.HDR_TYPE_HDR10) {
                    return true;
                }
            }
        } catch (Throwable t) {
            LiteavLog.w(TAG, "probeDisplayHdr10 failed: " + t.getMessage());
        }
        return false;
    }
}
