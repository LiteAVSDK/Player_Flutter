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

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

public class FTXTextureView extends TextureView implements FTXRenderCarrier {
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
    private float mRotation = 0;
    private FTXEGLRender mRender;
    private final Object mLayoutLock = new Object();
    private final TextureViewInnerListener mSurfaceListenerDelegate = new TextureViewInnerListener(this);

    public FTXTextureView(@NonNull Context context) {
        super(context);
        initTextureView();
    }

    private void initTextureView() {
        setSurfaceTextureListener(mSurfaceListenerDelegate);
        mRender = new FTXEGLRender(1080, 720);
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
                updateVideoRenderMode();
                LiteavLog.i(TAG, "notifyVideoResolutionChanged updateSize, mVideoWidth:"
                        + mVideoWidth + ",mVideoHeight:" + mVideoHeight);
            }
        }
    }

    @Override
    public void notifyTextureRotation(float rotation) {
        if (mRotation != rotation) {
            mRotation = rotation;
            if (null != mRender) {
                mRender.updateRotation(rotation);
            }
        }
    }

    @Override
    public void updateRenderMode(long renderMode) {
        if (mRenderMode != renderMode) {
            mRenderMode = renderMode;
            updateVideoRenderMode();
        }
    }

    @Override
    public void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight) {
        updateRenderSizeIfNeed(viewWidth, viewHeight);
    }

    public void updateVideoRenderMode() {
        LiteavLog.i(TAG, "updateVideoSize, mVideoWidth:" + mVideoWidth + ",mVideoHeight:"
                + mVideoHeight + ",renderMode:" + mRenderMode);
        if (null != mRender) {
            mRender.updateSizeAndRenderMode(mVideoWidth, mVideoHeight, mRenderMode);
        }
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
            mRenderMode = surfaceHost.getPlayerRenderMode();
            mVideoWidth = surfaceHost.getVideoWidth();
            mVideoHeight = surfaceHost.getVideoHeight();
            mRotation = surfaceHost.getRotation();
            updateVideoRenderMode();
            notifyTextureRotation(mRotation);
            LiteavLog.i(TAG, "updateSize, mVideoWidth:" + mVideoWidth + ",mVideoHeight:"
                    + mVideoHeight + ",renderMode:" + mRenderMode + ",mRotation:" + mRotation);
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

    @Deprecated
    @Override
    public void setSurfaceTextureListener(@Nullable SurfaceTextureListener listener) {
//        super.setSurfaceTextureListener(listener);
        if (listener instanceof TextureViewInnerListener) {
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
    public void setSurfaceTexture(@NonNull SurfaceTexture surfaceTexture) {
        super.setSurfaceTexture(surfaceTexture);
        updateSurfaceTexture(surfaceTexture);
    }

    private void updateHostSurface(Surface surface) {
        if (null != mPlayer) {
            mRender.initOpengl(surface);
            mPlayer.setSurface(mRender.getInputSurface());
            mRender.startRender();
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
        setSurfaceTextureListener(null);
    }

    @Override
    public void reDrawVod() {
        if (null != mRender) {
            mRender.refreshRender();
        }
    }

    @Override
    public void addSurfaceTextureListener(FTXCarrierSurfaceListener listener) {
        if (null != listener && !mSurfaceListenerDelegate.mExternalSurfaceListeners.contains(listener)) {
            mSurfaceListenerDelegate.mExternalSurfaceListeners.add(listener);
        }
    }

    @Override
    public void removeSurfaceTextureListener(FTXCarrierSurfaceListener listener) {
        if (null != listener) {
            mSurfaceListenerDelegate.mExternalSurfaceListeners.remove(listener);
        }
    }

    @Override
    public void removeAllSurfaceListener() {
        mSurfaceListenerDelegate.mExternalSurfaceListeners.clear();
    }

    private static class TextureViewInnerListener implements SurfaceTextureListener {

        private final List<FTXCarrierSurfaceListener> mExternalSurfaceListeners = new CopyOnWriteArrayList<>();
        private final FTXTextureView mContainer;

        public TextureViewInnerListener(FTXTextureView container) {
            mContainer = container;
        }

        @Override
        public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surfaceTexture, int width, int height) {
            LiteavLog.v(TAG, "onSurfaceTextureAvailable");
            mContainer.applySurfaceConfig(surfaceTexture, width, height);
            mContainer.updateRenderSizeIfCan();
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureAvailable(mContainer.mSurface);
            }
        }

        @Override
        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
            LiteavLog.v(TAG, "onSurfaceTextureSizeChanged");
            mContainer.applySurfaceConfig(surface, width, height);
        }

        @Override
        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
            LiteavLog.v(TAG, "onSurfaceTextureDestroyed:" + mContainer.mSurface);
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureDestroyed(mContainer.mSurface);
            }
            mContainer.mSurface = null;
            mContainer.mSurfaceTexture = null;
            return false;
        }

        @Override
        public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {

        }
    }
}
