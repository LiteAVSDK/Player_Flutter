// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter.player.render;

import android.view.Surface;

import com.tencent.rtmp.TXVodPlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.FTXRenderView;
import com.tencent.vod.flutter.ui.render.FTXTextureView;

public abstract class FTXVodPlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost
        , FTXPlayerRenderSurfaceHost {

    private static final String TAG = "FTXVodPlayerRenderHost";

    protected FTXTextureView mTextureView;
    protected FTXRenderView mCurRenderView;

    @Override
    public void setUpPlayerView(FTXRenderView renderView) {
        if (null != renderView) {
            mCurRenderView = renderView;
            renderView.setPlayer(this);
        } else {
            mCurRenderView = null;
            setRenderView(null);
        }
    }

    @Override
    public void setRenderView(FTXTextureView textureView) {
        if (null != textureView) {
//            if (mTextureView != textureView) {
//                removeRenderView();
//                mTextureView = textureView;
//                textureView.bindPlayer(this);
//            } else {
//                textureView.bindPlayer(this);
//            }
            mTextureView = textureView;
            textureView.bindPlayer(this);
        } else {
            removeRenderView();
        }
    }

    @Override
    public void setSurface(Surface surface) {
        final TXVodPlayer vodPlayer = getVodPlayer();
        vodPlayer.setSurface(surface);
    }

    private void removeRenderView() {
        if (null != mTextureView) {
            mTextureView.bindPlayer(null);
        }
        final TXVodPlayer vodPlayer = getVodPlayer();
        if (null != vodPlayer) {
            vodPlayer.setSurface(null);
        }
        mTextureView = null;
    }

    protected abstract TXVodPlayer getVodPlayer();
}
