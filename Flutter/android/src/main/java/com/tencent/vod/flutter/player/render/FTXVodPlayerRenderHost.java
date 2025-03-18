// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import android.view.Surface;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

public abstract class FTXVodPlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost
        , FTXPlayerRenderSurfaceHost {

    private static final String TAG = "FTXVodPlayerRenderHost";

    protected FTXRenderCarrier mTextureView;
    protected FTXRenderView mCurRenderView;

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
        if (null != textureView) {
            LiteavLog.i(TAG, "start bind Player:" + textureView + ", player:" + hashCode());
            textureView.bindPlayer(this);
            mTextureView = textureView;
        } else {
            LiteavLog.i(TAG, "setRenderView met a null textureView, player:" + hashCode());
            removeRenderView();
        }
    }

    @Override
    public void setSurface(Surface surface) {
        final TXVodPlayer vodPlayer = getVodPlayer();
        if (null != vodPlayer) {
            LiteavLog.w(TAG, "start setSurface: " + surface + ", player:" + hashCode());
            vodPlayer.setSurface(surface);
        } else {
            LiteavLog.w(TAG, "setSurface met a null player, player:" + hashCode());
        }
    }

    private void removeRenderView() {
        LiteavLog.i(TAG, "start removeRenderView, player:" + hashCode());
        if (null != mTextureView) {
            mTextureView.bindPlayer(null);
        }
        final TXVodPlayer vodPlayer = getVodPlayer();
        if (null != vodPlayer) {
            vodPlayer.setSurface(null);
        }
        mTextureView = null;
    }

    @Override
    public FTXRenderCarrier getCurCarrier() {
        return mTextureView;
    }

    protected abstract TXVodPlayer getVodPlayer();
}
