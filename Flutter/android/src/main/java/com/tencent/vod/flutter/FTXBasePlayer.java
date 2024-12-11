// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import com.tencent.rtmp.ui.TXCloudVideoView;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * player base
 */
public abstract class FTXBasePlayer {
    private static final AtomicInteger mAtomicId = new AtomicInteger(0);
    private final int mPlayerId;

    public int getPlayerId() {
        return mPlayerId;
    }

    public FTXBasePlayer() {
        mPlayerId = mAtomicId.incrementAndGet();
    }

    public abstract void setRenderView(TXCloudVideoView cloudVideoView);

    public void destroy() {

    }

}
