// Copyright (c) 2026 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.content.Context;
import android.view.OrientationEventListener;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXLiveBaseListener;
import com.tencent.vod.flutter.tools.TXFlutterEngineHolder;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Process-wide shared resources for the SuperPlayer module.
 *
 * The SuperPlayerPlugin itself stays per-engine (Flutter creates a new instance of the plugin
 * class for every engine), but process-level hooks must only be attached once:
 *   - TXLiveBase.setListener (License callback only accepts one listener)
 *   - OrientationEventListener (one listener per app is enough)
 *   - TXFlutterEngineHolder (ActivityLifecycle callbacks, one per Application)
 *
 * This class keeps an ordered set of attached plugins and reference-counts the global hooks
 * based on the number of attached plugins. When the first plugin attaches, the hooks are wired
 * up; when the last plugin detaches, they are torn down.
 *
 * SDK events that are conceptually global (License loaded / orientation changed) are fanned out
 * to every attached plugin so that every Flutter engine gets the same notification.
 */
public final class VodGlobalResource {

    private static final String TAG = "VodGlobalResource";

    private static final class Holder {
        private static final VodGlobalResource INSTANCE = new VodGlobalResource();
    }

    public static VodGlobalResource getInstance() {
        return Holder.INSTANCE;
    }

    private final Object mLock = new Object();
    private final Set<SuperPlayerPlugin> mAttachedPlugins = new LinkedHashSet<>();

    private OrientationEventListener mOrientationManager;
    private int mCurrentOrientation = FTXEvent.ORIENTATION_PORTRAIT_UP;

    private final TXLiveBaseListener mSDKEvent = new TXLiveBaseListener() {
        @Override
        public void onLicenceLoaded(int result, String reason) {
            super.onLicenceLoaded(result, reason);
            LiteavLog.v(TAG, "onLicenceLoaded,result:" + result + ",reason:" + reason);
            broadcastLicenceLoaded(result, reason);
        }
    };

    private VodGlobalResource() {
    }

    /**
     * Called from {@link SuperPlayerPlugin#onAttachedToEngine}.
     * The first attach wires up the global hooks; subsequent attaches only register the plugin
     * for broadcasting.
     */
    public void acquire(@NonNull SuperPlayerPlugin plugin,
                        @NonNull FlutterPlugin.FlutterPluginBinding binding) {
        synchronized (mLock) {
            boolean wasEmpty = mAttachedPlugins.isEmpty();
            mAttachedPlugins.add(plugin);
            LiteavLog.i(TAG, "acquire plugin=" + plugin
                    + ", size=" + mAttachedPlugins.size() + ", firstAttach=" + wasEmpty);
            if (wasEmpty) {
                TXLiveBase.setListener(mSDKEvent);
                TXFlutterEngineHolder.getInstance().attachBindLife(binding);
            }
        }
    }

    /**
     * Called from {@link SuperPlayerPlugin#onDetachedFromEngine}.
     * The last detach tears down the global hooks; earlier detaches only unregister the plugin.
     */
    public void release(@NonNull SuperPlayerPlugin plugin,
                        @NonNull FlutterPlugin.FlutterPluginBinding binding) {
        synchronized (mLock) {
            mAttachedPlugins.remove(plugin);
            boolean nowEmpty = mAttachedPlugins.isEmpty();
            LiteavLog.i(TAG, "release plugin=" + plugin
                    + ", size=" + mAttachedPlugins.size() + ", lastDetach=" + nowEmpty);
            if (nowEmpty) {
                TXLiveBase.setListener(null);
                if (mOrientationManager != null) {
                    mOrientationManager.disable();
                    mOrientationManager = null;
                }
                TXFlutterEngineHolder.getInstance().destroy(binding);
            }
        }
    }

    /**
     * Start the shared orientation service if it is not running yet. Safe to call repeatedly
     * across engines; only the first call enables the underlying {@link OrientationEventListener}.
     */
    public boolean startOrientationService(@NonNull Context appCtx) {
        synchronized (mLock) {
            if (mOrientationManager != null) {
                return true;
            }
            try {
                mOrientationManager = new OrientationEventListener(appCtx) {
                    @Override
                    public void onOrientationChanged(int orientation) {
                        if (!isDeviceAutoRotateOn(appCtx)) {
                            return;
                        }
                        int ev = mapOrientation(orientation, mCurrentOrientation);
                        if (ev != mCurrentOrientation) {
                            mCurrentOrientation = ev;
                            broadcastOrientationChanged(ev);
                        }
                    }
                };
                mOrientationManager.enable();
                return true;
            } catch (Exception e) {
                LiteavLog.e(TAG, "startOrientationService error", e);
                return false;
            }
        }
    }

    private void broadcastLicenceLoaded(int result, String reason) {
        List<SuperPlayerPlugin> snapshot;
        synchronized (mLock) {
            snapshot = new ArrayList<>(mAttachedPlugins);
        }
        for (SuperPlayerPlugin p : snapshot) {
            p.dispatchLicenceLoaded(result, reason);
        }
    }

    private void broadcastOrientationChanged(int orientation) {
        List<SuperPlayerPlugin> snapshot;
        synchronized (mLock) {
            snapshot = new ArrayList<>(mAttachedPlugins);
        }
        for (SuperPlayerPlugin p : snapshot) {
            p.dispatchOrientationChanged(orientation);
        }
    }

    private static int mapOrientation(int orientation, int current) {
        int ev = current;
        if (((orientation >= 0) && (orientation < 30)) || (orientation > 330)) {
            ev = FTXEvent.ORIENTATION_PORTRAIT_UP;
        } else if (orientation > 240 && orientation < 300) {
            ev = FTXEvent.ORIENTATION_LANDSCAPE_RIGHT;
        } else if (orientation > 150 && orientation < 210) {
            ev = FTXEvent.ORIENTATION_PORTRAIT_DOWN;
        } else if (orientation > 60 && orientation < 110) {
            ev = FTXEvent.ORIENTATION_LANDSCAPE_LEFT;
        }
        return ev;
    }

    private static boolean isDeviceAutoRotateOn(@Nullable Context ctx) {
        if (ctx == null) {
            return false;
        }
        try {
            return android.provider.Settings.System.getInt(
                    ctx.getContentResolver(),
                    android.provider.Settings.System.ACCELEROMETER_ROTATION, 0) == 1;
        } catch (Exception e) {
            LiteavLog.e(TAG, "isDeviceAutoRotateOn error", e);
            return false;
        }
    }
}
