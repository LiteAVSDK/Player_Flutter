// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import android.view.SurfaceView;
import android.view.TextureView;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.live2.V2TXLivePlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.CarrierViewObserver;
import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

public abstract class FTXLivePlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost,
        CarrierViewObserver {

    private static final String TAG = "FTXLivePlayerRenderHost";
    protected FTXRenderView mCurRenderView;
    private boolean isTargetDetached = false;

    @Override
    public void setUpPlayerView(FTXRenderView renderView) {
        if (null != renderView) {
            LiteavLog.i(TAG, "start setUpPlayerView:" + renderView.getViewId() + ", player:" + hashCode());
            mCurRenderView = renderView;
            renderView.setPlayer(this);
        } else {
            LiteavLog.w(TAG, "start setUpPlayerView met null view, reset player, player:" + hashCode());
            mCurRenderView = null;
            setRenderView(null);
        }
    }

    @Override
    public void setRenderView(FTXRenderCarrier textureView) {
        final V2TXLivePlayer livePlayer = getLivePlayer();
        isTargetDetached = false;
        if (null != textureView) {
            LiteavLog.i(TAG, "start bind Player:" + textureView + ", player:" + hashCode());
            if (textureView instanceof TextureView) {
                livePlayer.setRenderView((TextureView) textureView);
                textureView.addViewObserver(this);
            } else if (textureView instanceof SurfaceView) {
                livePlayer.setRenderView((SurfaceView) textureView);
            } else {
                LiteavLog.e(TAG, "setRenderView met a unImpl renderView, view obj:" + textureView);
            }
        } else {
            LiteavLog.i(TAG, "setRenderView met a null textureView, player:" + hashCode());
            livePlayer.setRenderView((TextureView) null);
            livePlayer.setRenderView((SurfaceView) null);
            if (null != mCurRenderView && mCurRenderView.getRenderView() != null) {
                mCurRenderView.getRenderView().removeViewObserver(this);
            }
        }
    }

    @Override
    public void onDetachWindow(FTXRenderCarrier carrier) {
        isTargetDetached = true;
    }

    @Override
    public void onAttachWindow(FTXRenderCarrier carrier) {
        if (isTargetDetached && null != mCurRenderView) {
            setUpPlayerView(mCurRenderView);
        }
    }

    protected abstract V2TXLivePlayer getLivePlayer();
}
