// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import android.view.SurfaceView;
import android.view.TextureView;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.live2.V2TXLivePlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

public abstract class FTXLivePlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost {

    private static final String TAG = "FTXLivePlayerRenderHost";
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
    public void setRenderView(FTXRenderCarrier textureView) {
        final V2TXLivePlayer livePlayer = getLivePlayer();
        if (null != textureView) {
            if (textureView instanceof TextureView) {
                livePlayer.setRenderView((TextureView) textureView);
            } else if (textureView instanceof SurfaceView) {
                livePlayer.setRenderView((SurfaceView) textureView);
            } else {
                LiteavLog.e(TAG, "setRenderView met a unImpl renderView, view obj:" + textureView);
            }
        } else {
            livePlayer.setRenderView((TextureView) null);
        }
    }

    protected abstract V2TXLivePlayer getLivePlayer();
}
