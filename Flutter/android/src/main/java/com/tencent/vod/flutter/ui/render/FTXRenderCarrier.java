package com.tencent.vod.flutter.ui.render;

import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;

import java.lang.ref.WeakReference;
import java.util.List;

public interface FTXRenderCarrier {

    void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost);

    void clearLastImg();

    void setVisibility(int visibility);

    void notifyVideoResolutionChanged(int videoWidth, int videoHeight);

    void updateRenderMode(long renderMode);

    void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight);

    void destroyRender();

    void addViewObserver(CarrierViewObserver observer);

    void removeViewObserver(CarrierViewObserver observer);

    void removeAllViewObserver();

    List<WeakReference<CarrierViewObserver>> getViewObservers();
}
