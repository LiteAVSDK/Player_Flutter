package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderHost;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class FTXRenderView implements PlatformView {
    private static final String TAG = "FTXRenderView";

    private final FTXTextureView mTextureView;
    private FTXPlayerRenderHost mBasePlayer;
    private final int mViewId;

    public FTXRenderView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams
            , BinaryMessenger messenger) {
        mTextureView = new FTXTextureView(context);
        mViewId = id;
    }

    public FTXTextureView getRenderView() {
        return mTextureView;
    }

    public void setPlayer(FTXPlayerRenderHost player) {
        if (mBasePlayer != player) {
            LiteavLog.i(TAG, "setPlayer, player is not equal, old:" + mBasePlayer
                    + ",new:" + player + ", view:" + hashCode());
            if (null != mBasePlayer) {
                mBasePlayer.setRenderView(null);
                mTextureView.clearLastImg();
            }
            mBasePlayer = player;
            mTextureView.setVisibility(View.VISIBLE);
            player.setRenderView(mTextureView);
        } else {
            LiteavLog.i(TAG, "setPlayer, player is same, player:" + player
                    + " refresh it, view:" + hashCode());
            mTextureView.setVisibility(View.VISIBLE);
            player.setRenderView(mTextureView);
        }
    }

    @Nullable
    @Override
    public View getView() {
        return mTextureView;
    }

    public int getViewId() {
        return mViewId;
    }

    @Override
    public void dispose() {

    }
}
