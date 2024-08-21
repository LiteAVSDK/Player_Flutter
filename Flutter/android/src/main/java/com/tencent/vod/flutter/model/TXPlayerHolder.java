package com.tencent.vod.flutter.model;

import com.tencent.live2.V2TXLivePlayer;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.FTXEvent;

public class TXPlayerHolder {

    private TXVodPlayer mVodPlayer;
    private V2TXLivePlayer mLivePlayer;
    private final int mPlayerType;
    private boolean mPlayingStatus;
    private boolean mIsPlayingWhenCreated = false;

    public TXPlayerHolder(TXVodPlayer vodPlayer) {
        mVodPlayer = vodPlayer;
        mPlayingStatus = vodPlayer.isPlaying();
        mIsPlayingWhenCreated = mPlayingStatus;
        mPlayerType = FTXEvent.PLAYER_VOD;
    }

    public TXPlayerHolder(V2TXLivePlayer livePlayer, boolean initPauseStatus) {
        mLivePlayer = livePlayer;
        mPlayingStatus = !initPauseStatus;
        mIsPlayingWhenCreated = mPlayingStatus;
        mPlayerType = FTXEvent.PLAYER_LIVE;
    }

    public TXVodPlayer getVodPlayer() {
        return mVodPlayer;
    }

    public V2TXLivePlayer getLivePlayer() {
        return mLivePlayer;
    }

    public boolean isPlayingWhenCreate() {
        return mIsPlayingWhenCreated;
    }

    public boolean isPlaying() {
        return mPlayingStatus;
    }

    public void pause() {
        if (null != mVodPlayer) {
            mVodPlayer.pause();
            mPlayingStatus = false;
        } else if (null != mLivePlayer) {
            mLivePlayer.pauseAudio();
            mLivePlayer.pauseVideo();
            mPlayingStatus = false;
        }
    }

    public void resume() {
        if (null != mVodPlayer) {
            mVodPlayer.resume();
            mPlayingStatus = true;
        } else if (null != mLivePlayer) {
            mLivePlayer.resumeAudio();
            mLivePlayer.resumeVideo();
            mPlayingStatus = true;
        }
    }

    public int getPlayerType() {
        return mPlayerType;
    }
}
