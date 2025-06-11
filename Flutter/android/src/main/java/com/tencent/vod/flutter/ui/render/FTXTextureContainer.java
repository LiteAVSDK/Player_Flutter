package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

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
            } else {
                List<WeakReference<CarrierViewObserver>> mOldObservers = new ArrayList<>();
                if (null != mTextureHolder) {
                    removeView((View) mTextureHolder);
                    mOldObservers.addAll(mTextureHolder.getViewObservers());
                    mTextureHolder.destroyRender();
                }
                for (WeakReference<CarrierViewObserver> ref : mOldObservers) {
                    carrier.addViewObserver(ref.get());
                }
                LiteavLog.i(TAG, "start add new carrier:" + carrier + ",view:" + hashCode());
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
