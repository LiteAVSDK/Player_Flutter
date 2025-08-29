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

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

public class FTXSurfaceView extends SurfaceView implements FTXRenderCarrier {

    private static final String TAG = "FTXSurfaceView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private  final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;

    private int mVideoWidth = 0;
    private int mVideoHeight = 0;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private float mRotation = 0;
    private final Object mLayoutLock = new Object();
    private FTXEGLRender mRender;
    private final SurfaceViewInnerListener mSurfaceListenerDelegate = new SurfaceViewInnerListener(this);

    public FTXSurfaceView(Context context) {
        super(context);
        init();
    }

    private void init() {
        getHolder().addCallback(mSurfaceListenerDelegate);
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
            updateVideoRenderMode();
        }
    }

    @Override
    public void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight) {
        updateRenderSizeIfNeed(viewWidth, viewHeight);
    }

    public void updateVideoRenderMode() {
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
            LiteavLog.i(TAG, "updateHostSurface:" + surface);
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
    public void reDrawVod() {
        // surfaceView will detach view, so reDraw will invalid
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

    private static class SurfaceViewInnerListener implements SurfaceHolder.Callback {

        private final List<FTXCarrierSurfaceListener> mExternalSurfaceListeners = new CopyOnWriteArrayList<>();
        private final FTXSurfaceView mContainer;

        private SurfaceViewInnerListener(FTXSurfaceView container) {
            this.mContainer = container;
        }

        @Override
        public void surfaceCreated(@NonNull SurfaceHolder holder) {
            LiteavLog.v(TAG, "onSurfaceTextureAvailable");
            mContainer.applySurfaceConfig(holder.getSurface(), 0, 0);
            mContainer.updateRenderSizeIfCan();
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureAvailable(mContainer.mSurface);
            }
        }

        @Override
        public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
            LiteavLog.v(TAG, "surfaceChanged");
            mContainer.applySurfaceConfig(holder.getSurface(), width, height);
        }

        @Override
        public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
            LiteavLog.v(TAG, "onSurfaceTextureDestroyed:" + mContainer.mSurface);
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureDestroyed(mContainer.mSurface);
            }
            mContainer.mSurface = null;
        }
    }
}
