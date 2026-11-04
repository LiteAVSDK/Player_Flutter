package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;

public class FTXTextureContainer extends FrameLayout {

    private static final String TAG = "FTXTextureContainer";

    private FTXRenderCarrier mTextureHolder;

    public FTXTextureContainer(@NonNull Context context) {
        super(context);
    }

    public synchronized void setCarrier(FTXRenderCarrier carrier) {
        LiteavLog.i(TAG, "called setUp new carrier:" + carrier + ",view:" + hashCode());
        if (mTextureHolder != carrier) {
            if (null == carrier) {
                LiteavLog.i(TAG, "start remove old carrier:" + mTextureHolder + ",view:" + hashCode());
                removeView((View) mTextureHolder);
                mTextureHolder.destroyRender();
                mTextureHolder.removeAllSurfaceListener();
            } else {
                LiteavLog.i(TAG, "start add new carrier:" + carrier + ",view:" + hashCode());
                // remove old
                removeView((View) mTextureHolder);
                addView((View) carrier);
            }
            mTextureHolder = carrier;
        }
    }

    @Override
    public void removeAllViews() {
        super.removeAllViews();
        LiteavLog.i(TAG, "target removeAllViews,view:" + hashCode());
    }

    @Override
    public void removeView(View view) {
        super.removeView(view);
        LiteavLog.i(TAG, "target removeView, child:" + view + ",view:" + hashCode());
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (null != mTextureHolder) {
            mTextureHolder.requestLayoutSizeByContainerSize(w, h);
        }
    }
}
