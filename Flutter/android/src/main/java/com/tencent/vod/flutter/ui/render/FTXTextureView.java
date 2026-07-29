package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.graphics.Matrix;
import android.graphics.SurfaceTexture;
import android.view.Gravity;
import android.view.Surface;
import android.view.TextureView;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.FTXVodPlayerRenderHost;
import com.tencent.vod.flutter.player.render.gl.FTXEGLRender;
import com.tencent.vod.flutter.player.render.gl.GLSurfaceTools;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/** TextureView 渲染载体：OES（默认）/ Pass-through 直连两条管线，构造时确定。 */
public class FTXTextureView extends TextureView implements FTXRenderCarrier {
    private static final String TAG = "FTXTextureView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private SurfaceTexture mSurfaceTexture;
    private final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;

    private int mVideoWidth = 0;
    private int mVideoHeight = 0;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private float mRotation = 0;
    private FTXEGLRender mRender;
    private final Object mLayoutLock = new Object();
    private final TextureViewInnerListener mSurfaceListenerDelegate = new TextureViewInnerListener(this);

    private final boolean mPassThrough;

    public FTXTextureView(@NonNull Context context) {
        this(context, false);
    }

    public FTXTextureView(@NonNull Context context, boolean forcePassThrough) {
        super(context);
        this.mPassThrough = forcePassThrough;
        initTextureView();
    }

    private void initTextureView() {
        setSurfaceTextureListener(mSurfaceListenerDelegate);
        if (!mPassThrough) {
            mRender = new FTXEGLRender(1080, 720);
        }
        // HDR not supported on TextureView.
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
                if (mPassThrough) {
                    applyLayoutParams();
                } else {
                    updateVideoRenderMode();
                }
                LiteavLog.i(TAG, "notifyVideoResolutionChanged updateSize, mVideoWidth:"
                        + mVideoWidth + ",mVideoHeight:" + mVideoHeight);
            }
        }
    }

    @Override
    public void notifyTextureRotation(float rotation) {
        if (mRotation == rotation) {
            return;
        }
        mRotation = rotation;
        if (mPassThrough) {
            applyTextureRotation(rotation);
        } else if (null != mRender) {
            mRender.updateRotation(rotation);
        }
    }

    private void applyTextureRotation(float rotation) {
        Matrix matrix = new Matrix();
        matrix.setRotate(rotation, getWidth() / 2f, getHeight() / 2f);
        setTransform(matrix);
    }

    @Override
    public void updateRenderMode(long renderMode) {
        if (mRenderMode != renderMode) {
            mRenderMode = renderMode;
            if (mPassThrough) {
                applyLayoutParams();
            } else {
                updateVideoRenderMode();
            }
        }
    }

    @Override
    public void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight) {
        if (mPassThrough) {
            updateContainerSizeIfNeed(viewWidth, viewHeight);
        } else {
            updateRenderSizeIfNeed(viewWidth, viewHeight);
            // redraw when layout size changed
            post(new Runnable() {
                @Override
                public void run() {
                    reDrawVod(false);
                }
            });
        }
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
            if (mPassThrough) {
                if (null != mPlayer && null != mSurface && mSurface.isValid()) {
                    surfaceHost.setSurface(mSurface);
                }
            } else {
                if (null != mPlayer) {
                    surfaceHost.setSurface(mRender.getInputSurface());
                    updateRenderSizeIfCan();
                    LiteavLog.w(TAG, "bindPlayer interrupt ,player: " + surfaceHost + " is equal before, view:"
                            + FTXTextureView.this.hashCode());
                } else {
                    mRender.stopRender();
                }
            }
        } else {
            mPlayer = surfaceHost;
            connectPlayer(surfaceHost);
        }
        if (null != surfaceHost) {
            if (surfaceHost instanceof FTXVodPlayerRenderHost) {
                ((FTXVodPlayerRenderHost) surfaceHost).handleTRTCObj(this);
            }
            mRenderMode = surfaceHost.getPlayerRenderMode();
            mVideoWidth = surfaceHost.getVideoWidth();
            mVideoHeight = surfaceHost.getVideoHeight();
            mRotation = surfaceHost.getRotation();
            if (mPassThrough) {
                applyLayoutParams();
            } else {
                updateVideoRenderMode();
                notifyTextureRotation(mRotation);
            }
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
                if (mPassThrough) {
                    updateContainerSizeIfCan();
                } else {
                    updateRenderSizeIfCan();
                }
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
            if (null != mRender) {
                mRender.setViewPortSize(width, height);
            }
        }
    }

    /** Pass-through 容器尺寸同步 */
    private void updateContainerSizeIfCan() {
        if (null != getParent()) {
            ViewGroup viewGroup = (ViewGroup) getParent();
            updateContainerSizeIfNeed(viewGroup.getWidth(), viewGroup.getHeight());
        }
    }

    private void updateContainerSizeIfNeed(int width, int height) {
        if (mViewWidth != width || mViewHeight != height) {
            mViewWidth = width;
            mViewHeight = height;
            applyLayoutParams();
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        LiteavLog.i(TAG, "target onDetachedFromWindow,view:" + hashCode());
        if (!mPassThrough && null != mRender) {
            mRender.stopRender();
        }
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
            if (mPassThrough) {
                mPlayer.setSurface(surface);
            } else {
                mRender.initOpengl(surface);
                mPlayer.setSurface(mRender.getInputSurface());
                mRender.startRender();
            }
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
        if (!mPassThrough && null != mRender) {
            mRender.stopRender();
        }
        setSurfaceTextureListener(null);
    }

    @Override
    public void reDrawVod(boolean isForcePullFrame) {
        if (!mPassThrough && null != mRender) {
            mRender.refreshRender(isForcePullFrame);
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

    @Override
    public void enableTRTCCloud(boolean enable, FTXEGLRender.OnFrameCopyListener listener) {
        if (mPassThrough) {
            return;
        }
        if (null != mRender) {
            mRender.setEnableFrameCopy(enable, listener);
        }
    }

    // ===================== Pass-through layout =====================

    private void applyLayoutParams() {
        if (!mPassThrough) {
            return;
        }
        post(new Runnable() {
            @Override
            public void run() {
                applyLayoutParamsInternal();
            }
        });
    }

    private void applyLayoutParamsInternal() {
        if (mVideoWidth <= 0 || mVideoHeight <= 0 || mViewWidth <= 0 || mViewHeight <= 0) {
            return;
        }
        float videoRatio = (float) mVideoWidth / mVideoHeight;
        float containerRatio = (float) mViewWidth / mViewHeight;

        int targetW = mViewWidth;
        int targetH = mViewHeight;

        if (mRenderMode == FTXPlayerConstants.FTXRenderMode.ADJUST_RESOLUTION) {
            if (videoRatio > containerRatio) {
                targetH = (int) (mViewWidth / videoRatio);
            } else {
                targetW = (int) (mViewHeight * videoRatio);
            }
        } else if (mRenderMode == FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER) {
            if (videoRatio > containerRatio) {
                targetW = (int) (mViewHeight * videoRatio);
            } else {
                targetH = (int) (mViewWidth / videoRatio);
            }
        }

        ViewGroup.LayoutParams lp = getLayoutParams();
        if (lp instanceof FrameLayout.LayoutParams) {
            FrameLayout.LayoutParams flp = (FrameLayout.LayoutParams) lp;
            if (flp.width != targetW || flp.height != targetH) {
                flp.width = targetW;
                flp.height = targetH;
                flp.gravity = Gravity.CENTER;
                setLayoutParams(flp);
            }
        } else if (lp != null) {
            if (lp.width != targetW || lp.height != targetH) {
                lp.width = targetW;
                lp.height = targetH;
                setLayoutParams(lp);
            }
        }
    }

    // ===================== SurfaceTextureListener =====================

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
            if (mContainer.mPassThrough) {
                mContainer.updateContainerSizeIfCan();
            } else {
                mContainer.updateRenderSizeIfCan();
            }
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureAvailable(mContainer.mSurface);
            }
        }

        @Override
        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
            LiteavLog.v(TAG, "onSurfaceTextureSizeChanged " + width + "x" + height);
            mContainer.applySurfaceConfig(surface, width, height);
            if (mContainer.mPassThrough) {
                mContainer.applyLayoutParams();
            } else {
                // resize is truly completed at this moment, sync viewport with real size and force redraw
                if (null != mContainer.mRender) {
                    mContainer.mRender.setViewPortSize(width, height);
                }
                mContainer.reDrawVod(true);
            }
        }

        @Override
        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
            LiteavLog.v(TAG, "onSurfaceTextureDestroyed:" + mContainer.mSurface);
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureDestroyed(mContainer.mSurface);
            }
            if (mContainer.mPassThrough && null != mContainer.mPlayer) {
                mContainer.mPlayer.setSurface(null);
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
