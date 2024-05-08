package com.tencent.vod.flutter.model;

import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.FTXEvent;

public class TXPlayerHolder {

    private TXVodPlayer mVodPlayer;
    private TXLivePlayer mLivePlayer;
    private int mPlayerType;
    private boolean mInitPlayingStatus;

    public TXPlayerHolder(TXVodPlayer vodPlayer) {
        mVodPlayer = vodPlayer;
        mInitPlayingStatus = vodPlayer.isPlaying();
        mPlayerType = FTXEvent.PLAYER_VOD;
    }

    public TXPlayerHolder(TXLivePlayer livePlayer) {
        mLivePlayer = livePlayer;
        mInitPlayingStatus = livePlayer.isPlaying();
        mPlayerType = FTXEvent.PLAYER_LIVE;
    }

    public TXVodPlayer getVodPlayer() {
        return mVodPlayer;
    }

    public TXLivePlayer getLivePlayer() {
        return mLivePlayer;
    }

    public boolean isPlayingWhenCreate() {
        return mInitPlayingStatus;
    }

    public void tmpPause() {
        if (null != mVodPlayer) {
            mVodPlayer.pause();
        } else if (null != mLivePlayer) {
            mLivePlayer.pause();
        }
    }

    public int getPlayerType() {
        return mPlayerType;
    }
}
