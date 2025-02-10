package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderHost;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class FTXRenderView implements PlatformView {
    private static final String TAG = "FTXRenderView";

    private final FTXRenderCarrier mTextureView;
    private FTXPlayerRenderHost mBasePlayer;
    private final int mViewId;

    public FTXRenderView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams
            , BinaryMessenger messenger) {
        int renderType = FTXEvent.ViewType.TEXTURE_TYPE;
        if (null != creationParams) {
            Object renderTypeObj = creationParams.get(FTXEvent.RENDER_TYPE_KEY);
            if (renderTypeObj instanceof Integer) {
                renderType = (int) renderTypeObj;
            }
        }
        if (renderType == FTXEvent.ViewType.TEXTURE_TYPE) {
            mTextureView = new FTXTextureView(context);
        } else if (renderType == FTXEvent.ViewType.SURFACE_TYPE) {
            mTextureView = new FTXSurfaceView(context);
        } else {
            LiteavLog.e(TAG, "unknown view type :" + renderType + ", use default type TEXTURE_TYPE");
            mTextureView = new FTXTextureView(context);
        }
        mViewId = id;
    }

    public FTXRenderCarrier getRenderView() {
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
        return (View) mTextureView;
    }

    public int getViewId() {
        return mViewId;
    }

    @Override
    public void dispose() {
        LiteavLog.i(TAG, "render view is dispose, id:" + mViewId + ", view:" + hashCode());
    }
}
