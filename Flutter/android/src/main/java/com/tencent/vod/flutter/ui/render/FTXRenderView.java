package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.vod.flutter.player.render.FTXPlayerRenderHost;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class FTXRenderView implements PlatformView {

    private final FTXTextureView mTextureView;
    private FTXPlayerRenderHost mBasePlayer;

    public FTXRenderView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams
            , BinaryMessenger messenger) {
        mTextureView = new FTXTextureView(context);
    }

    public FTXTextureView getRenderView() {
        return mTextureView;
    }

    public void setPlayer(FTXPlayerRenderHost player) {
        if (mBasePlayer != player) {
            if (null != mBasePlayer) {
                mBasePlayer.setRenderView(null);
                mTextureView.clearLastImg();
            }
            mBasePlayer = player;
            mTextureView.setVisibility(View.VISIBLE);
            player.setRenderView(mTextureView);
        } else {
            mTextureView.setVisibility(View.VISIBLE);
            player.setRenderView(mTextureView);
        }
    }

    @Nullable
    @Override
    public View getView() {
        return mTextureView;
    }

    @Override
    public void dispose() {

    }
}
