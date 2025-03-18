package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.graphics.SurfaceTexture;
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
        setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
    }

    @Override
    public void clearLastImg() {
        LiteavLog.i(TAG, "start clearLastImg, view:" + FTXTextureView.this.hashCode());
        ViewParent viewParent = getParent();
        if (null != viewParent) {
            // remove view for targeting surface recycle
            ViewGroup viewGroup = (ViewGroup) viewParent;
            final int viewIndex = viewGroup.indexOfChild(FTXTextureView.this);
            if (null != mSurfaceTexture) {
                mSurfaceTexture.release();
            }
            mSurfaceTexture = null;
            mSurface = null;
            viewGroup.removeView(FTXTextureView.this);
            viewGroup.addView(FTXTextureView.this, viewIndex);
        } else {
            LiteavLog.i(TAG, "clearLastImg failed, parent is null, view:" + FTXTextureView.this.hashCode());
        }
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        LiteavLog.i(TAG, "called bindPlayer " + surfaceHost + ", view:" + FTXTextureView.this.hashCode());
        if (surfaceHost != mPlayer || (null != mPlayer && mPlayer.getCurCarrier() != FTXTextureView.this)) {
            mPlayer = surfaceHost;
            if (null != mSurfaceTexture && null != surfaceHost) {
                LiteavLog.i(TAG, "bindPlayer suc,player: " + surfaceHost + ", view:"
                        + FTXTextureView.this.hashCode());
                if (mSurface.isValid()) {
                    surfaceHost.setSurface(mSurface);
                } else {
                    LiteavLog.w(TAG, "bindPlayer interrupt ,mSurface: " + mSurface + " is inVaild, view:"
                            + FTXTextureView.this.hashCode());
                }
            }
        } else {
            LiteavLog.w(TAG, "bindPlayer interrupt ,player: " + surfaceHost + " is equal before, view:"
                    + FTXTextureView.this.hashCode());
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

    @Override
    public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
        LiteavLog.v(TAG, "onSurfaceTextureAvailable");
        applySurfaceConfig(surface, width, height);
    }

    @Override
    public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
        LiteavLog.v(TAG, "onSurfaceTextureSizeChanged");
        applySurfaceConfig(surface, width, height);
    }

    @Override
    public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
        LiteavLog.v(TAG, "onSurfaceTextureDestroyed");
        if (null != mSurfaceTexture) {
            mSurfaceTexture.release();
        }
        mSurfaceTexture = null;
        mSurface = null;
        return false;
    }

    @Override
    public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {

    }
}
