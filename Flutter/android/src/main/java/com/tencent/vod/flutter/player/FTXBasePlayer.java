// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * player base
 */
public abstract class FTXBasePlayer {
    private static final AtomicInteger mAtomicId = new AtomicInteger(0);
    private final int mPlayerId;
    private final AtomicBoolean mDestroyed = new AtomicBoolean(false);

    public int getPlayerId() {
        return mPlayerId;
    }

    public FTXBasePlayer() {
        mPlayerId = mAtomicId.incrementAndGet();
    }

    public boolean isDestroyed() {
        return mDestroyed.get();
    }

    protected boolean markDestroyedIfNeeded() {
        return mDestroyed.compareAndSet(false, true);
    }

    public void destroy() {

    }

}
