// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import android.view.Surface;
import android.view.SurfaceView;
import android.view.TextureView;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.live2.V2TXLivePlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.FTXCarrierSurfaceListener;
import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

public abstract class FTXLivePlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost,
        FTXCarrierSurfaceListener {

    private static final String TAG = "FTXLivePlayerRenderHost";
    protected FTXRenderView mCurRenderView;
    protected FTXRenderCarrier mRenderCarrier;

    @Override
    public void setUpPlayerView(FTXRenderView renderView) {
        if (null != renderView) {
            LiteavLog.i(TAG, "start setUpPlayerView:" + renderView.getViewId() + ", player:" + hashCode());
            mCurRenderView = renderView;
            renderView.setPlayer(this);
        } else {
            LiteavLog.w(TAG, "start setUpPlayerView met null view, reset player, player:" + hashCode());
            setRenderView(null);
            if (null != mCurRenderView && null != mCurRenderView.getRenderView()) {
                mCurRenderView.getRenderView().removeSurfaceTextureListener(this);
            }
            mCurRenderView = null;
        }
    }

    @Override
    public void setRenderView(FTXRenderCarrier textureView) {
        final V2TXLivePlayer livePlayer = getLivePlayer();
        if (null != textureView) {
            LiteavLog.i(TAG, "start bind Player:" + textureView + ", player:" + hashCode());
            if (textureView instanceof TextureView) {
                livePlayer.setRenderView((TextureView) textureView);
                textureView.addSurfaceTextureListener(this);
                mRenderCarrier = textureView;
            } else if (textureView instanceof SurfaceView) {
                livePlayer.setRenderView((SurfaceView) textureView);
                textureView.addSurfaceTextureListener(this);
                mRenderCarrier = textureView;
            } else {
                LiteavLog.e(TAG, "setRenderView met a unImpl renderView, view obj:" + textureView);
            }
        } else {
            LiteavLog.i(TAG, "setRenderView met a null textureView, player:" + hashCode());
            mRenderCarrier = null;
            if (null != livePlayer) {
                livePlayer.setRenderView((TextureView) null);
                livePlayer.setRenderView((SurfaceView) null);
            }
        }
    }

    @Override
    public void onSurfaceTextureAvailable(Surface surface) {
        if (null != mCurRenderView) {
            setRenderView(mCurRenderView.getRenderView());
        }
    }

    @Override
    public boolean onSurfaceTextureDestroyed(Surface surface) {
        return false;
    }

    @Override
    public boolean isUsingRenderCarrier(FTXRenderCarrier carrier) {
        return mRenderCarrier == carrier;
    }

    protected abstract V2TXLivePlayer getLivePlayer();
}
