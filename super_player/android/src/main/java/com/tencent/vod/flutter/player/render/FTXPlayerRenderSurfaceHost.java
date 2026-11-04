// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import android.view.Surface;

import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;

public interface FTXPlayerRenderSurfaceHost {

    void setSurface(Surface surface);

    FTXRenderCarrier getCurCarrier();

    long getPlayerRenderMode();

    float getRotation();

    int getVideoWidth();

    int getVideoHeight();

}
