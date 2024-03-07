// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.model;

import android.os.Parcel;
import android.os.Parcelable;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.vod.flutter.FTXEvent;

/**
 * Video model.
 *
 * 视频model
 */
public class TXVideoModel implements Parcelable {

    private String videoUrl;
    private int appId;
    private String fileId;
    private String pSign;
    private int mPlayerType = FTXEvent.PLAYER_VOD;
    private int mLiveType = TXLivePlayer.PLAY_TYPE_LIVE_FLV;
    private String mToken;

    public TXVideoModel() {}

    protected TXVideoModel(Parcel in) {
        videoUrl = in.readString();
        appId = in.readInt();
        fileId = in.readString();
        pSign = in.readString();
        mPlayerType = in.readInt();
        mLiveType = in.readInt();
        mToken = in.readString();
    }

    public static final Creator<TXVideoModel> CREATOR = new Creator<TXVideoModel>() {
        @Override
        public TXVideoModel createFromParcel(Parcel in) {
            return new TXVideoModel(in);
        }

        @Override
        public TXVideoModel[] newArray(int size) {
            return new TXVideoModel[size];
        }
    };

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public String getToken() {
        return mToken;
    }

    public void setToken(String token) {
        this.mToken = token;
    }

    public int getAppId() {
        return appId;
    }

    public void setAppId(int appId) {
        this.appId = appId;
    }

    public String getFileId() {
        return fileId;
    }

    public void setFileId(String fileId) {
        this.fileId = fileId;
    }

    public String getPSign() {
        return pSign;
    }

    public void setPSign(String pSign) {
        this.pSign = pSign;
    }

    public int getPlayerType() {
        return mPlayerType;
    }

    public void setPlayerType(int mPlayerType) {
        this.mPlayerType = mPlayerType;
    }

    public int getLiveType() {
        return mLiveType;
    }

    public void setLiveType(int mLiveType) {
        this.mLiveType = mLiveType;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(videoUrl);
        dest.writeInt(appId);
        dest.writeString(fileId);
        dest.writeString(pSign);
        dest.writeInt(mPlayerType);
        dest.writeInt(mLiveType);
        dest.writeString(mToken);
    }
}
