// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter.player.render;

import android.view.TextureView;

import com.tencent.live2.V2TXLivePlayer;
import com.tencent.vod.flutter.player.FTXBasePlayer;
import com.tencent.vod.flutter.ui.render.FTXRenderView;
import com.tencent.vod.flutter.ui.render.FTXTextureView;

public abstract class FTXLivePlayerRenderHost extends FTXBasePlayer implements FTXPlayerRenderHost {

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
        final V2TXLivePlayer livePlayer = getLivePlayer();
        if (null != textureView) {
            livePlayer.setRenderView(textureView);
        } else {
            livePlayer.setRenderView((TextureView) null);
        }
    }

    protected abstract V2TXLivePlayer getLivePlayer();
}
