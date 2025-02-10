package com.tencent.vod.flutter.ui.render;

import android.view.View;

import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;

public interface FTXRenderCarrier {

    void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost);

    void clearLastImg();

    void setVisibility(int visibility);

}
