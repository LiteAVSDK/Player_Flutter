package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.view.Surface;
import android.view.TextureView;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.gl.FTXEGLRender;
import com.tencent.vod.flutter.player.render.gl.GLSurfaceTools;

public class FTXTextureView extends TextureView implements TextureView.SurfaceTextureListener, FTXRenderCarrier {
    private static final String TAG = "FTXTextureView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private SurfaceTexture mSurfaceTexture;
    private  final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;

    private int mVideoWidth = 0;
    private int mVideoHeight = 0;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private final Object mLayoutLock = new Object();
    private FTXEGLRender mRender;

    public FTXTextureView(@NonNull Context context) {
        super(context);
        initTextureView();
    }

    private void initTextureView() {
        setSurfaceTextureListener(this);
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
        mRender.updateSizeAndRenderMode(mVideoWidth, mVideoHeight, mRenderMode);
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        LiteavLog.i(TAG, "called bindPlayer " + surfaceHost + ", view:" + FTXTextureView.this.hashCode());
        if (mPlayer == surfaceHost) {
            if (null != mPlayer) {
                surfaceHost.setSurface(mRender.getInputSurface());
                updateRenderSizeIfCan();
                LiteavLog.w(TAG, "bindPlayer interrupt ,player: " + surfaceHost + " is equal before, view:"
                        + FTXTextureView.this.hashCode());
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
        if (null != mSurfaceTexture && null != surfaceHost) {
            LiteavLog.i(TAG, "bindPlayer suc,player: " + surfaceHost + ", view:"
                    + FTXTextureView.this.hashCode());
            if (mSurface.isValid()) {
                updateHostSurface(mSurface);
                updateRenderSizeIfCan();
            } else {
                LiteavLog.w(TAG, "bindPlayer interrupt ,mSurface: " + mSurface + " is inValid, view:"
                        + FTXTextureView.this.hashCode());
            }
        }
    }

    @Override
    public void setSurfaceTextureListener(@Nullable SurfaceTextureListener listener) {
        // bypass the video player's processing logic
        if (listener instanceof FTXTextureView) {
            super.setSurfaceTextureListener(listener);
        }
    }

    private void updateRenderSizeIfCan() {
        if (null != getParent()) {
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

    @Override
    public void setSurfaceTexture(@NonNull SurfaceTexture surfaceTexture) {
        super.setSurfaceTexture(surfaceTexture);
        updateSurfaceTexture(surfaceTexture);
    }

    private void updateHostSurface(Surface surface) {
        if (null != mPlayer) {
            mRender.stopRender();
            mRender.initOpengl(surface);
            mRender.startRender();
            mPlayer.setSurface(mRender.getInputSurface());
        }
    }

    private void applySurfaceConfig(SurfaceTexture surfaceTexture, int width, int height) {
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
    public void destroyRender() {
        mRender.stopRender();
    }

    @Override
    public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
        LiteavLog.v(TAG, "onSurfaceTextureAvailable");
        applySurfaceConfig(surface, width, height);
        updateRenderSizeIfCan();
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
