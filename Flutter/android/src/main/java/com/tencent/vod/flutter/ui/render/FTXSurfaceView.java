package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.gl.GLSurfaceTools;

public class FTXSurfaceView extends SurfaceView implements SurfaceHolder.Callback, FTXRenderCarrier {

    private static final String TAG = "FTXSurfaceView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private int mSurfaceWidth;
    private int mSurfaceHeight;
    private  final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();

    public FTXSurfaceView(Context context) {
        super(context);
        init();
    }

    private void init() {
        getHolder().addCallback(this);
    }

    @Override
    public void clearLastImg() {
        LiteavLog.i(TAG, "start clearLastImg, view:" + hashCode());
        if (null != mSurface) {
            mGlSurfaceTools.clearSurface(mSurface);
        }
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        mPlayer = surfaceHost;
        if (null != mSurface && null != surfaceHost) {
            LiteavLog.i(TAG, "bindPlayer suc,player: " + surfaceHost + ", view:" + hashCode());
            surfaceHost.setSurface(mSurface);
        }
    }

    private void updateHostSurface(Surface surface) {
        if (null != mPlayer) {
            mPlayer.setSurface(surface);
        }
    }

    private void applySurfaceConfig(Surface surface, int width, int height) {
        mSurfaceWidth = width;
        mSurfaceHeight = height;
        updateSurfaceTexture(surface);
    }

    private void updateSurfaceTexture(Surface surface) {
        if (mSurface != surface) {
            LiteavLog.v(TAG, "surfaceTexture is updated:" + surface);
            mSurface = surface;
            // surfaceView must clear img when created, or it will show flutter ui img
            mGlSurfaceTools.clearSurface(surface);
            updateHostSurface(surface);
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
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
        LiteavLog.v(TAG, "surfaceCreated");
        applySurfaceConfig(holder.getSurface(), 0, 0);
        layoutTextureRenderMode();
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
        LiteavLog.v(TAG, "surfaceChanged");
        applySurfaceConfig(holder.getSurface(), width, height);
        layoutTextureRenderMode();
    }

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
        LiteavLog.v(TAG, "onSurfaceTextureDestroyed");
        if (null != mSurface) {
            mSurface.release();
        }
        mSurface = null;
    }
}
