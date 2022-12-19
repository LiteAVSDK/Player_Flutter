// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * player base
 */
public class FTXBasePlayer {
    private static final AtomicInteger mAtomicId = new AtomicInteger(0);
    private final int mPlayerId;

    public int getPlayerId() {
        return mPlayerId;
    }

    public FTXBasePlayer() {
        mPlayerId = mAtomicId.incrementAndGet();
    }

    public void destroy() {

    }

}
