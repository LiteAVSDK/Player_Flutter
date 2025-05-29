package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.gl.FTXEGLRender;
import com.tencent.vod.flutter.player.render.gl.GLSurfaceTools;

public class FTXSurfaceView extends SurfaceView implements SurfaceHolder.Callback, FTXRenderCarrier {

    private static final String TAG = "FTXSurfaceView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private  final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;

    private int mVideoWidth = 0;
    private int mVideoHeight = 0;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private final Object mLayoutLock = new Object();
    private FTXEGLRender mRender;

    public FTXSurfaceView(Context context) {
        super(context);
        init();
    }

    private void init() {
        getHolder().addCallback(this);
        setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        mRender = new FTXEGLRender(1, 1);
    }

    @Override
    public void clearLastImg() {
        LiteavLog.i(TAG, "start clearLastImg, view:" + hashCode());
        if (null != mSurface) {
            mGlSurfaceTools.clearSurface(mSurface);
        }
    }

    @Override
    public void notifyVideoResolutionChanged(int videoWidth, int videoHeight) {
        synchronized (mLayoutLock) {
            if (mVideoWidth != videoWidth || mVideoHeight != videoHeight) {
                if (videoWidth >= 0) {
                    mVideoWidth = videoWidth;
                }
                if (videoHeight >= 0) {
                    mVideoHeight = videoHeight;
                }
                mRender.updateSizeAndRenderMode(videoWidth, videoHeight, mRenderMode);
                LiteavLog.i(TAG, "notifyVideoResolutionChanged updateSize, mVideoWidth:"
                        + mVideoWidth + ",mVideoHeight:" + mVideoHeight);
            }
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        LiteavLog.i(TAG, "target onDetachedFromWindow,view:" + hashCode());
        mRender.stopRender();
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        LiteavLog.i(TAG, "target onAttachedToWindow,view:" + hashCode());
    }

    @Override
    public void updateRenderMode(long renderMode) {
        if (mRenderMode != renderMode) {
            mRenderMode = renderMode;
            layoutTextureRenderMode();
        }
    }

    @Override
    public void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight) {
        updateRenderSizeIfNeed(viewWidth, viewHeight);
    }

    public void layoutTextureRenderMode() {
        if (mRender != null) {
            mRender.updateSizeAndRenderMode(mVideoWidth, mVideoHeight, mRenderMode);
        }
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        LiteavLog.i(TAG, "called bindPlayer " + surfaceHost + ", view:" + FTXSurfaceView.this.hashCode());
        if (mPlayer == surfaceHost) {
            if (null != mPlayer) {
                surfaceHost.setSurface(mRender.getInputSurface());
                updateRenderSizeIfCan();
                LiteavLog.w(TAG, "bindPlayer interrupt ,player: " + surfaceHost + " is equal before, view:"
                        + hashCode());
            } else {
                mRender.stopRender();
            }
        } else {
            mPlayer = surfaceHost;
            connectPlayer(surfaceHost);
        }
        if (null != surfaceHost) {
            final int videoWidth = surfaceHost.getVideoWidth();
            final int videoHeight = surfaceHost.getVideoHeight();
            mRenderMode = surfaceHost.getPlayerRenderMode();
            mVideoWidth = surfaceHost.getVideoWidth();
            mVideoHeight = surfaceHost.getVideoHeight();
            mRender.updateSizeAndRenderMode(videoWidth, videoHeight, mRenderMode);
            LiteavLog.i(TAG, "updateSize, mVideoWidth:" + mVideoWidth + ",mVideoHeight:"
                    + mVideoHeight + ",renderMode:" + mRenderMode);
        }
    }

    private void connectPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        if (null != mSurface && null != surfaceHost) {
            LiteavLog.i(TAG, "bindPlayer suc,player: " + surfaceHost + ", view:"
                    + hashCode());
            if (mSurface.isValid()) {
                updateHostSurface(mSurface);
                updateRenderSizeIfCan();
            } else {
                LiteavLog.w(TAG, "bindPlayer interrupt ,mSurface: " + mSurface + " is inValid, view:"
                        + this.hashCode());
            }
        }
    }

    private void updateRenderSizeIfCan() {
        if (null != mRender && null != getParent()) {
            ViewGroup viewGroup = (ViewGroup) getParent();
            int width = viewGroup.getWidth();
            int height = viewGroup.getHeight();
            updateRenderSizeIfNeed(width, height);
        }
    }

    private void updateRenderSizeIfNeed(int width, int height) {
        if (mViewWidth != width || mViewHeight != height) {
            mViewWidth = width;
            mViewHeight = height;
            LiteavLog.i(TAG, "updateRenderSizeIfNeed, width:" + width + ",height:" + height);
            mRender.setViewPortSize(width, height);
        }
    }

    private void updateHostSurface(Surface surface) {
        if (null != mPlayer) {
            mRender.initOpengl(surface);
            mPlayer.setSurface(mRender.getInputSurface());
            mRender.startRender();
            mPlayer.setSurface(mRender.getInputSurface());
        }
    }

    private void applySurfaceConfig(Surface surface, int width, int height) {
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

    @Override
    public void destroyRender() {
        mRender.stopRender();
    }

    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
        LiteavLog.v(TAG, "surfaceCreated");
        applySurfaceConfig(holder.getSurface(), 0, 0);
        updateRenderSizeIfCan();
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
        LiteavLog.v(TAG, "surfaceChanged");
        applySurfaceConfig(holder.getSurface(), width, height);
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
