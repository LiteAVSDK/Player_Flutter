package com.tencent.vod.flutter.ui.render;

import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;

public interface FTXRenderCarrier {

    void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost);

    void clearLastImg();

    void setVisibility(int visibility);

    void notifyVideoResolutionChanged(int videoWidth, int videoHeight);

    void notifyTextureRotation(float rotation);

    void updateRenderMode(long renderMode);

    void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight);

    void destroyRender();

    void reDrawVod();

    void addSurfaceTextureListener(FTXCarrierSurfaceListener listener);

    void removeSurfaceTextureListener(FTXCarrierSurfaceListener listener);

    void removeAllSurfaceListener();
}
