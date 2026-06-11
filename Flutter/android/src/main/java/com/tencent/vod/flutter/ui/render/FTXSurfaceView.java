package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.Gravity;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderSurfaceHost;
import com.tencent.vod.flutter.player.render.FTXVodPlayerRenderHost;
import com.tencent.vod.flutter.player.render.gl.FTXEGLRender;
import com.tencent.vod.flutter.player.render.gl.GLSurfaceTools;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/** SurfaceView 渲染载体：OES（默认）/ Pass-through 直连两条管线，构造时确定。 */
public class FTXSurfaceView extends SurfaceView implements FTXRenderCarrier {

    private static final String TAG = "FTXSurfaceView";

    private FTXPlayerRenderSurfaceHost mPlayer;
    private Surface mSurface;
    private final GLSurfaceTools mGlSurfaceTools = new GLSurfaceTools();
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;

    private int mVideoWidth = 0;
    private int mVideoHeight = 0;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private float mRotation = 0;
    private final Object mLayoutLock = new Object();

    private final boolean mPassThrough;
    private FTXEGLRender mRender;

    private final SurfaceViewInnerListener mSurfaceListenerDelegate = new SurfaceViewInnerListener(this);

    public FTXSurfaceView(Context context) {
        this(context, false);
    }

    public FTXSurfaceView(Context context, boolean forcePassThrough) {
        super(context);
        this.mPassThrough = forcePassThrough;
        init();
    }

    private void init() {
        getHolder().addCallback(mSurfaceListenerDelegate);
    }

    @Override
    public void clearLastImg() {
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
                    updateVideoRenderModeOnRender();
                }
            }
        }
    }

    @Override
    public void notifyTextureRotation(float rotation) {
        if (mRotation == rotation) {
            return;
        }
        mRotation = rotation;
        if (!mPassThrough && null != mRender) {
            mRender.updateRotation(rotation);
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        if (!mPassThrough && null != mRender) {
            mRender.stopRender();
        }
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
    }

    @Override
    public void updateRenderMode(long renderMode) {
        if (mRenderMode != renderMode) {
            mRenderMode = renderMode;
            if (mPassThrough) {
                applyLayoutParams();
            } else {
                updateVideoRenderModeOnRender();
            }
        }
    }

    @Override
    public void requestLayoutSizeByContainerSize(int viewWidth, int viewHeight) {
        if (mPassThrough) {
            updateContainerSizeIfNeed(viewWidth, viewHeight);
        } else {
            updateRenderSizeIfNeed(viewWidth, viewHeight);
            post(new Runnable() {
                @Override
                public void run() {
                    reDrawVod(false);
                }
            });
        }
    }

    private void updateVideoRenderModeOnRender() {
        if (mRender != null) {
            mRender.updateSizeAndRenderMode(mVideoWidth, mVideoHeight, mRenderMode);
        }
    }

    @Override
    public void bindPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        LiteavLog.i(TAG, "bindPlayer");
        if (null != surfaceHost && null == mPlayer) {
            if (!mPassThrough && null == mRender) {
                mRender = new FTXEGLRender(1080, 720);
            }
        }

        if (mPlayer == surfaceHost) {
            if (mPassThrough) {
                if (null != mPlayer && null != mSurface && mSurface.isValid()) {
                    surfaceHost.setSurface(mSurface);
                }
            } else {
                if (null != mPlayer) {
                    surfaceHost.setSurface(mRender.getInputSurface());
                    updateRenderSizeIfCan();
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
                updateVideoRenderModeOnRender();
                if (null != mRender) {
                    mRender.updateRotation(mRotation);
                }
            }
        }
    }

    private void connectPlayer(FTXPlayerRenderSurfaceHost surfaceHost) {
        if (null == mSurface || null == surfaceHost) {
            return;
        }
        if (mPassThrough) {
            if (mSurface.isValid()) {
                updateHostSurface(mSurface);
                updateContainerSizeIfCan();
            } else {
                LiteavLog.w(TAG, "invalid surface");
            }
        } else {
            if (mSurface.isValid()) {
                updateHostSurface(mSurface);
                updateRenderSizeIfCan();
            } else {
                LiteavLog.w(TAG, "invalid surface");
            }
        }
    }

    /** OES 视口尺寸同步 */
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

    private void updateHostSurface(Surface surface) {
        if (null == mPlayer) {
            return;
        }
        if (mPassThrough) {
            if (null != surface) {
                mPlayer.setSurface(surface);
            }
        } else {
            mRender.initOpengl(surface);
            mPlayer.setSurface(mRender.getInputSurface());
            mRender.startRender();
        }
    }

    private void applySurfaceConfig(Surface surface, int width, int height) {
        updateSurfaceTexture(surface);
    }

    private void updateSurfaceTexture(Surface surface) {
        if (mSurface != surface) {
            mSurface = surface;
            updateHostSurface(surface);
            if (mPassThrough) {
                applyLayoutParams();
            }
        }
    }

    @Override
    public void destroyRender() {
        if (!mPassThrough && null != mRender) {
            mRender.stopRender();
        }
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

    // ===================== SurfaceHolder.Callback =====================

    private static class SurfaceViewInnerListener implements SurfaceHolder.Callback {

        private final List<FTXCarrierSurfaceListener> mExternalSurfaceListeners = new CopyOnWriteArrayList<>();
        private final FTXSurfaceView mContainer;

        private SurfaceViewInnerListener(FTXSurfaceView container) {
            this.mContainer = container;
        }

        @Override
        public void surfaceCreated(@NonNull SurfaceHolder holder) {
            mContainer.applySurfaceConfig(holder.getSurface(), 0, 0);
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
        public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
            mContainer.applySurfaceConfig(holder.getSurface(), width, height);
            if (mContainer.mPassThrough) {
                mContainer.applyLayoutParams();
            } else {
                if (null != mContainer.mRender) {
                    mContainer.mRender.setViewPortSize(width, height);
                }
                mContainer.reDrawVod(true);
            }
        }

        @Override
        public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
            LiteavLog.i(TAG, "surfaceDestroyed");
            final Surface destroyed = mContainer.mSurface;
            if (mContainer.mPassThrough) {
                if (null != mContainer.mPlayer) {
                    mContainer.mPlayer.setSurface(null);
                }
            } else {
                if (null != mContainer.mRender) {
                    mContainer.mRender.stopRender();
                }
            }
            for (FTXCarrierSurfaceListener listener : mExternalSurfaceListeners) {
                listener.onSurfaceTextureDestroyed(destroyed);
            }
            mContainer.mSurface = null;
        }
    }
}
