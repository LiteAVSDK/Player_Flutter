package com.tencent.vod.flutter.ui.render;

import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.gl.FTXEGLRender;

public interface FTXRenderCarrier {

    void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost);

    void clearLastImg();

    void notifyVideoResolutionChanged(int videoWidth, int videoHeight);

    void notifyTextureRotation(float rotation);

    void updateRenderMode(long renderMode);

    void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight);

    void destroyRender();

    void reDrawVod(boolean isForcePullFrame);

    void addSurfaceTextureListener(FTXCarrierSurfaceListener listener);

    void removeSurfaceTextureListener(FTXCarrierSurfaceListener listener);

    void removeAllSurfaceListener();

    void enableTRTCCloud(boolean enable, FTXEGLRender.OnFrameCopyListener listener);
}
