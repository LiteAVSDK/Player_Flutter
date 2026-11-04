package com.tencent.vod.flutter.ui.render;

import android.view.Surface;

public interface FTXCarrierSurfaceListener {

    void onSurfaceTextureAvailable(Surface surface);

    boolean onSurfaceTextureDestroyed(Surface surface);
}
