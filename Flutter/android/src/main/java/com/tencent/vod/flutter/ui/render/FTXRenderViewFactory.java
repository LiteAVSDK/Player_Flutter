package com.tencent.vod.flutter.ui.render;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class FTXRenderViewFactory extends PlatformViewFactory {

    private static final String TAG = "FTXRenderViewFactory";

    private final Map<Integer, WeakReference<FTXRenderView>> mRenderViewCache = new HashMap<>();
    private final BinaryMessenger mBinaryMessenger;

    public FTXRenderViewFactory(@Nullable BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        mBinaryMessenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        final Map<String, Object> creationParams = (Map<String, Object>) args;
        FTXRenderView renderView = new FTXRenderView(context, viewId, creationParams, this);
        mRenderViewCache.put(viewId, new WeakReference<>(renderView));
        LiteavLog.i(TAG, "create renderView: " + viewId);
        return renderView;
    }

    public void removeByViewId(int viewId) {
        mRenderViewCache.remove(viewId);
    }

    public FTXRenderView findViewById(int viewId) {
        WeakReference<FTXRenderView> renderViewWeakReference = mRenderViewCache.get(viewId);
        if (null == renderViewWeakReference) {
            return null;
        }
        return renderViewWeakReference.get();
    }
}
