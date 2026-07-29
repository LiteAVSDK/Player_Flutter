package com.tencent.vod.flutter.model;

import com.tencent.live2.V2TXLivePlayer;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.player.FTXVodPlayer;
import com.tencent.vod.flutter.player.FTXLivePlayer;

public class TXPlayerHolder {

    private final FTXVodPlayer mFTXVodPlayer;
    private final FTXLivePlayer mFTXLivePlayer;
    private final int mPlayerType;
    private final boolean mIsPlayingWhenCreated;

    public TXPlayerHolder(FTXVodPlayer ftxVodPlayer) {
        mFTXVodPlayer = ftxVodPlayer;
        mFTXLivePlayer = null;
        mIsPlayingWhenCreated = ftxVodPlayer.isPlayerPlaying();
        mPlayerType = FTXEvent.PLAYER_VOD;
    }

    public TXPlayerHolder(FTXLivePlayer ftxLivePlayer, boolean initPauseStatus) {
        mFTXVodPlayer = null;
        mFTXLivePlayer = ftxLivePlayer;
        mIsPlayingWhenCreated = !initPauseStatus;
        mPlayerType = FTXEvent.PLAYER_LIVE;
    }

    // for PIP view bind/unbind
    public TXVodPlayer getVodPlayer() {
        if (mFTXVodPlayer != null) {
            return mFTXVodPlayer.getVodPlayer();
        }
        return null;
    }

    // for PIP view bind/unbind
    public V2TXLivePlayer getLivePlayer() {
        if (mFTXLivePlayer != null) {
            return mFTXLivePlayer.getLivePlayer();
        }
        return null;
    }

    public boolean isPlayingWhenCreate() {
        return mIsPlayingWhenCreated;
    }

    // real SDK state
    public boolean isPlaying() {
        if (mFTXVodPlayer != null) {
            return mFTXVodPlayer.isPlayerPlaying();
        } else if (mFTXLivePlayer != null) {
            return mFTXLivePlayer.isPlayerPlaying();
        }
        return false;
    }

    public void pause() {
        if (mFTXVodPlayer != null) {
            mFTXVodPlayer.playerPause(true);
        } else if (mFTXLivePlayer != null) {
            mFTXLivePlayer.pausePlayer(true);
        }
    }

    public void resume() {
        if (mFTXVodPlayer != null) {
            mFTXVodPlayer.playerResume();
        } else if (mFTXLivePlayer != null) {
            mFTXLivePlayer.resumePlayer();
        }
    }

    public void seek(float pos) {
        if (mFTXVodPlayer != null) {
            mFTXVodPlayer.seekPlayer(pos);
        }
    }

    public float getCurrentPlaybackTime() {
        if (mFTXVodPlayer != null) {
            return mFTXVodPlayer.getPlayerCurrentPlaybackTime();
        }
        return 0;
    }

    public void restart() {
        if (mFTXVodPlayer != null) {
            mFTXVodPlayer.restart();
        }
    }

    public int getPlayerType() {
        return mPlayerType;
    }
}
