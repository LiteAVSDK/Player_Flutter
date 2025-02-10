// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.player.render;

import com.tencent.vod.flutter.ui.render.FTXRenderCarrier;
import com.tencent.vod.flutter.ui.render.FTXRenderView;

public interface FTXPlayerRenderHost {

    void setUpPlayerView(FTXRenderView renderView);

    void setRenderView(FTXRenderCarrier textureView);

}
