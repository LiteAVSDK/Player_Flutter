// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter.player.render;

import com.tencent.vod.flutter.ui.render.FTXRenderView;
import com.tencent.vod.flutter.ui.render.FTXTextureView;

public interface FTXPlayerRenderHost {

    void setUpPlayerView(FTXRenderView renderView);

    void setRenderView(FTXTextureView textureView);

}
