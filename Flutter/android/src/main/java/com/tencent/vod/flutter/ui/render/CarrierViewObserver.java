package com.tencent.vod.flutter.ui.render;

public interface CarrierViewObserver {

    void onAttachWindow(FTXRenderCarrier carrier);

    void onDetachWindow(FTXRenderCarrier carrier);
}
