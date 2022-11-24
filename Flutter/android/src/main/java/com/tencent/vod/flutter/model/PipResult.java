package com.tencent.vod.flutter.model;

import android.os.Parcel;
import android.os.Parcelable;

public class PipResult implements Parcelable {
    private Float mPlayTime;
    private boolean mIsPlaying;
    private int mPlayerId;

    public PipResult(){}

    protected PipResult(Parcel in) {
        if (in.readByte() == 0) {
            mPlayTime = null;
        } else {
            mPlayTime = in.readFloat();
        }
        mIsPlaying = in.readByte() != 0;
        mPlayerId = in.readInt();
    }

    public static final Creator<PipResult> CREATOR = new Creator<PipResult>() {
        @Override
        public PipResult createFromParcel(Parcel in) {
            return new PipResult(in);
        }

        @Override
        public PipResult[] newArray(int size) {
            return new PipResult[size];
        }
    };

    public Float getPlayTime() {
        return mPlayTime;
    }

    public void setPlayTime(Float mPlayTime) {
        this.mPlayTime = mPlayTime;
    }

    public boolean isPlaying() {
        return mIsPlaying;
    }

    public void setPlaying(boolean playing) {
        mIsPlaying = playing;
    }

    public int getPlayerId() {
        return mPlayerId;
    }

    public void setPlayerId(int mPlayerId) {
        this.mPlayerId = mPlayerId;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        if (mPlayTime == null) {
            dest.writeByte((byte) 0);
        } else {
            dest.writeByte((byte) 1);
            dest.writeFloat(mPlayTime);
        }
        dest.writeByte((byte) (mIsPlaying ? 1 : 0));
        dest.writeInt(mPlayerId);
    }
}
