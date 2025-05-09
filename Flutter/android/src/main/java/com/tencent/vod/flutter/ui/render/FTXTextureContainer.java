package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

public class FTXTextureContainer extends FrameLayout {

    private FTXRenderCarrier mTextureHolder;

    public FTXTextureContainer(@NonNull Context context) {
        super(context);
    }

    public synchronized void setCarrier(FTXRenderCarrier carrier) {
        if (mTextureHolder != carrier) {
            if (null == carrier) {
                removeView((View) mTextureHolder);
                mTextureHolder.destroyRender();
            } else {
                if (null != mTextureHolder) {
                    removeView((View) mTextureHolder);
                    mTextureHolder.destroyRender();
                }
                addView((View) carrier);
            }
            mTextureHolder = carrier;
        }
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (null != mTextureHolder) {
            mTextureHolder.requestLayoutSizeByContainerSize(w, h);
        }
    }
}
