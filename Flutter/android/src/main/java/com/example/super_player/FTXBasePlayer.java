package com.example.super_player;
import java.util.concurrent.atomic.AtomicInteger;

public class FTXBasePlayer {
    private static final AtomicInteger mAtomicId = new AtomicInteger(0);
    private final int mPlayerId;

    public int getPlayerId() {
        return mPlayerId;
    }

    public FTXBasePlayer() {
        mPlayerId = mAtomicId.incrementAndGet();
    }

    public void destory() {

    }

}
