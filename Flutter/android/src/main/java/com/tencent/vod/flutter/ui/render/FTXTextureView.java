package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.view.Surface;
import android.view.TextureView;
import android.view.ViewGroup;
import android.view.ViewParent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;

public class FTXTextureView extends TextureView implements TextureView.SurfaceTextureListener, FTXRenderCarrier {
    private static final String TAG = "FTXTextureView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private SurfaceTexture mSurfaceTexture;
    private int mSurfaceWidth;
    private int mSurfaceHeight;

    public FTXTextureView(@NonNull Context context) {
        super(context);
        initTextureView();
    }

    private void initTextureView() {
        setSurfaceTextureListener(this);
    }

    @Override
    public void clearLastImg() {
        LiteavLog.i(TAG, "start clearLastImg, view:" + hashCode());
        ViewParent viewParent = getParent();
        if (null != viewParent) {
            // remove view for targeting surface recycle
            ViewGroup viewGroup = (ViewGroup) viewParent;
            int viewIndex = viewGroup.indexOfChild(this);
            viewGroup.removeView(this);
            viewGroup.addView(this, viewIndex);
        } else {
            LiteavLog.i(TAG, "clearLastImg failed, parent is null, view:" + hashCode());
        }
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        if (surfaceHost != mPlayer) {
            mPlayer = surfaceHost;
            if (null != mSurface && null != surfaceHost) {
                LiteavLog.i(TAG, "bindPlayer suc,player: " + surfaceHost + ", view:" + hashCode());
                surfaceHost.setSurface(mSurface);
            }
        } else {
            LiteavLog.w(TAG, "bindPlayer interrupt ,player: " + surfaceHost + " is equal before, view:"
                    + hashCode());
        }
    }

    @Override
    public void setSurfaceTextureListener(@Nullable SurfaceTextureListener listener) {
        // bypass the video player's processing logic
        if (listener instanceof FTXTextureView) {
            super.setSurfaceTextureListener(listener);
        }
    }

    @Override
    public void setSurfaceTexture(@NonNull SurfaceTexture surfaceTexture) {
        super.setSurfaceTexture(surfaceTexture);
        updateSurfaceTexture(surfaceTexture);
    }

    private void updateHostSurface(Surface surface) {
        if (null != mPlayer) {
            mPlayer.setSurface(surface);
        }
    }

    private void applySurfaceConfig(SurfaceTexture surfaceTexture, int width, int height) {
        mSurfaceWidth = width;
        mSurfaceHeight = height;
        updateSurfaceTexture(surfaceTexture);
    }

    private void updateSurfaceTexture(SurfaceTexture surfaceTexture) {
        if (mSurfaceTexture != surfaceTexture && null != surfaceTexture) {
            LiteavLog.v(TAG, "surfaceTexture is updated:" + surfaceTexture);
            mSurfaceTexture = surfaceTexture;
            mSurface = new Surface(surfaceTexture);
            updateHostSurface(mSurface);
        }
    }

    private void layoutTextureRenderMode() {
        if (getParent() != null) {
            final int viewWidth = ((ViewGroup) getParent()).getWidth();
            final int viewHeight = ((ViewGroup) getParent()).getHeight();
            ViewGroup.LayoutParams layoutParams = getLayoutParams();
            layoutParams.width = viewWidth;
            layoutParams.height = viewHeight;
            setLayoutParams(layoutParams);
        }
    }

    @Override
    public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
        LiteavLog.v(TAG, "onSurfaceTextureAvailable");
        applySurfaceConfig(surface, width, height);
        layoutTextureRenderMode();
    }

    @Override
    public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
        LiteavLog.v(TAG, "onSurfaceTextureSizeChanged");
        applySurfaceConfig(surface, width, height);
        layoutTextureRenderMode();
    }

    @Override
    public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
        LiteavLog.v(TAG, "onSurfaceTextureDestroyed");
        if (null != mSurfaceTexture) {
            mSurfaceTexture.release();
        }
        mSurfaceTexture = null;
        mSurface = null;
        return true;
    }

    @Override
    public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {
    }
}
