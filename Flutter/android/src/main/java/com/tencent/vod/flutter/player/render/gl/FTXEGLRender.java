package com.tencent.vod.flutter.player.render.gl;

import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.os.Handler;
import android.os.HandlerThread;
import android.view.Choreographer;
import android.view.Surface;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;
import com.tencent.vod.flutter.player.render.FTXPixelFrame;
import com.tencent.vod.flutter.player.render.trtc.FVodTRTCHelper;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class FTXEGLRender implements SurfaceTexture.OnFrameAvailableListener {

    private static final String TAG = "FTXEGLRender";

    private static final long FRAME_WAIT_TIME = 5000;
    private static final int FPS_DEFAULT = 30;
    // 与硬件 VSync 对齐时，覆盖三缓冲翻转 + Surface 重建竞态窗口所需的最小帧数
    private static final int REFRESH_FRAME_COUNT = 3;

    // EGL_OPENGL_ES3_BIT_KHR 在 EGL14 中无公开常量，使用扩展定义值；用于优先选择 ES3 配置
    private static final int EGL_OPENGL_ES3_BIT_KHR = 0x0040;

    private SurfaceTexture mSurfaceTexture;
    private FTXTextureRender mTextureRender;
    private Surface mInputSurface;
    private Surface mOutPutSurface;

    private EGLDisplay mEGLDisplay = EGL14.EGL_NO_DISPLAY;
    private final EGLContext mEGLContext = EGL14.EGL_NO_CONTEXT;
    private EGLContext mEGLContextEncoder = EGL14.EGL_NO_CONTEXT;
    private final EGLSurface mEGLSurface = EGL14.EGL_NO_SURFACE;
    private EGLSurface mEGLSurfaceEncoder = EGL14.EGL_NO_SURFACE;

    private EGLContext mEGLSavedContext = EGL14.EGL_NO_CONTEXT;
    private EGLDisplay mEGLSavedDisplay = EGL14.EGL_NO_DISPLAY;
    private EGLSurface mEGLSaveReadSurface = EGL14.EGL_NO_SURFACE;
    private EGLSurface mEGLSaveDrawSurface = EGL14.EGL_NO_SURFACE;

    private int mWidth;
    private int mHeight;
    private float mRotation = 0;
    private boolean mStart = false;
    private final Lock mLock = new ReentrantLock();
    private long mPreTime = 0;
    private long mCurrentTime;
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;
    private int mViewWidth;
    private int mViewHeight;
    private int mFps;
    private float frameInterval = 0;
    private HandlerThread mDrawHandlerThread = new HandlerThread(TAG);
    private Handler mDrawHandler = null;
    private boolean isReleased = false;
    private boolean mIsFirstFrame = false;

    // 当前 EGLContext 实际使用的 GLES 主版本：3 = GLES 3.0；2 = GLES 2.0 fallback；0 = 未初始化
    private volatile int mActiveGLESMajor = 0;

    // 渲染线程上的 Choreographer，用于把刷新动作对齐到硬件 VSync 信号
    private Choreographer mChoreographer;
    // 剩余需要刷新的 VSync 帧数（仅在渲染线程读写，无需加锁）
    private int mRefreshFramesLeft = 0;

    /**
     * 与硬件 VSync 信号对齐的自调度回调。
     * 每收到一个 VSync 信号绘制一帧，绘制完后判断是否需要继续提交下一帧。
     * 该回调全生命周期只创建一次，避免重复对象分配。
     */
    private final Choreographer.FrameCallback mRefreshFrameCallback = new Choreographer.FrameCallback() {
        @Override
        public void doFrame(long frameTimeNanos) {
            mLock.lock();
            try {
                startDrawSurface(false);
            } finally {
                mLock.unlock();
            }
            mRefreshFramesLeft--;
            if (mRefreshFramesLeft > 0 && mChoreographer != null) {
                mChoreographer.postFrameCallback(this);
            }
        }
    };

    private FVodTRTCHelper mTRTCHelper;
    private boolean mEnableFrameCopy = false;
    private OnFrameCopyListener mFrameCopyListener;
    private FTXPixelFrame mCachedPixelFrame;  // 复用的帧对象，避免频繁创建

    public interface OnFrameCopyListener {

        void onFrameCopied(FTXPixelFrame frame);
    }

    public FTXEGLRender(int width, int height) {
        this(width, height, FPS_DEFAULT);
    }

    public FTXEGLRender(int width, int height, int fps) {
        mWidth = width;
        mHeight = height;
        this.mFps = fps;
        frameInterval = (float) 1000 / fps - (float) ((float) 1000 / fps * 0.15);
        LiteavLog.i(TAG, "initFPs fps: " + fps + "video_interval: " + frameInterval);
    }

    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        /*
        onFrameAvailable 默认在主线程回调，导致使用 onFrameAvailable 触发的渲染动作，会受到主线程其他操作的影响，导致渲染产生延迟。
        一般情况下会晚两到五帧左右，尤其表现在起播的时候，首帧事件已经来临，但是画面延迟了一点（播放过程中不受影响，因为渲染的虽然晚了，但是画面拉取的仍然是当前最新的画面）
        。或者暂停状态下 seek，seek 之后画面改变，纹理上的画面仍然是 seek 之前或者上一次 seek 的画面。
        所以这里使用独立线程主动拉取画面进行渲染，但是一直拉取画面，会导致发热情况严重，所以默认有 60帧率的限制。所以这块播放器默认帧率为 60帧。
         */
        if (mStart) {
            mDrawHandler.post(new Runnable() {
                @Override
                public void run() {
                    if (!mIsFirstFrame) {
                        mLock.lock();
                        startDrawSurface(true);
                        mLock.unlock();
                    } else {
                        mIsFirstFrame = false;
                        refreshRender(true);
                    }
                }
            });
        }
    }

    private synchronized void startDrawSurface(boolean isNewFrame) {
        try {
            if (!mStart) {
                LiteavLog.e(TAG, "draw thread is dead");
                return;
            }
            saveCurrentEglEnvironment();
            if (!makeCurrent(1)) {
                return;
            }
            if (!mOutPutSurface.isValid()) {
                return;
            }

            mCurrentTime = System.currentTimeMillis();

            if (isNewFrame) {
                try {
                    mSurfaceTexture.updateTexImage();
                } catch (Exception e) {
                    LiteavLog.e(TAG, "updateTexImage failed: " + e.getMessage());
                    return;
                }
            }

            mTextureRender.drawFrame();
            swapBuffers();
            mPreTime = mCurrentTime;

            // 如果启用了帧复制，在绘制前复制一份纹理
            if (mEnableFrameCopy) {
                copyFrameForTRTC();
            }

        } catch (Exception e) {
            LiteavLog.e(TAG, "startDrawSurface error: " + e);
        } finally {
            restoreEglEnvironment();
        }
    }

    public boolean initOpengl(Surface surface, boolean needClearOld) {
        LiteavLog.i(TAG, "initOpengl " + (null == surface ? "null" : ""));
        isReleased = false;
        mIsFirstFrame = true;
        boolean bRet = true;
        do {
            saveCurrentEglEnvironment();
            if (!eglSetup(surface)) {
                LiteavLog.e(TAG, "eglSetup error");
                bRet = false;
                break;
            }

            if (!makeCurrent(1)) {
                bRet = false;
                break;
            }
        } while (false);

        if (!bRet) {
            releaseEgl();
            restoreEglEnvironment();
            return bRet;
        }

        setup(needClearOld);

        restoreEglEnvironment();
        return true;
    }

    public boolean initOpengl(Surface surface) {
        return initOpengl(surface, true);
    }

    /**
     * Creates interconnected instances of TextureRender, SurfaceTexture, and Surface.
     */
    private void setup(boolean needClearOld) {
        mTextureRender = new FTXTextureRender(mViewWidth, mViewHeight);
        mTextureRender.surfaceCreated();
        mTextureRender.updateSizeAndRenderMode(mWidth, mHeight, mRenderMode);
        mTextureRender.setRotationAngle(mRotation);
        LiteavLog.d(TAG, "textureID=" + mTextureRender.getTextureID());
        if (null == mInputSurface || needClearOld) {
            mSurfaceTexture = new SurfaceTexture(mTextureRender.getTextureID());
            // vide size for soft encode surface
            mSurfaceTexture.setDefaultBufferSize(mViewWidth, mViewHeight);
            mSurfaceTexture.setOnFrameAvailableListener(this);
            mInputSurface = new Surface(mSurfaceTexture);
        }
    }

    public void updateSizeAndRenderMode(int width, int height, long renderMode) {
        mWidth = width;
        mHeight = height;
        mRenderMode = renderMode;
        if (null != mTextureRender) {
            mTextureRender.updateSizeAndRenderMode(width, height, renderMode);
        } else {
            LiteavLog.w(TAG, "mTextureRender is null");
        }
    }

    public void updateRotation(float rotation) {
        mRotation = rotation;
        if (null != mTextureRender) {
            mTextureRender.setRotationAngle(rotation);
        } else {
            LiteavLog.w(TAG, "mTextureRender is null");
        }
    }

    public void setViewPortSize(final int width, final int height) {
        // 渲染未启动时的 fallback：直接更新堆变量，后续 startRender 会使用该尺寸
        if (null == mDrawHandler) {
            mViewWidth = width;
            mViewHeight = height;
            if (null != mTextureRender) {
                mTextureRender.setViewPortSize(width, height);
            }
            return;
        }
        // 切到渲染线程串行执行，避免与 drawFrame 发生数据竞争导致的画面几何错位
        mDrawHandler.post(new Runnable() {
            @Override
            public void run() {
                mLock.lock();
                try {
                    mViewWidth = width;
                    mViewHeight = height;
                    if (null != mSurfaceTexture) {
                        mSurfaceTexture.setDefaultBufferSize(width, height);
                    }
                    if (null != mTextureRender) {
                        mTextureRender.setViewPortSize(width, height);
                    }
                } finally {
                    mLock.unlock();
                }
            }
        });
    }

    private boolean eglSetup(Surface surface) {
        mEGLDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
        if (mEGLDisplay == EGL14.EGL_NO_DISPLAY) {
            checkEglError("unable to get EGL10 display");
            return false;
        }

        int[] version = new int[2];
        if (!EGL14.eglInitialize(mEGLDisplay, version, 0, version, 1)) {
            checkEglError("unable to initialize EGL10");
            return false;
        }

        // Try GLES 3.0 first, fall back to GLES 2.0 if the device GPU/driver does not support it.
        // GLES3 context is required as a foundation for HDR10 rendering (10bit framebuffer / BT2020).
        EGLConfig pickedConfig = null;
        EGLContext pickedContext = EGL14.EGL_NO_CONTEXT;
        EGLConfig configEs3 = chooseEGLConfig(EGL_OPENGL_ES3_BIT_KHR);
        if (configEs3 != null) {
            EGLContext ctx = tryCreateContext(configEs3, 3);
            if (ctx != EGL14.EGL_NO_CONTEXT) {
                pickedConfig = configEs3;
                pickedContext = ctx;
                mActiveGLESMajor = 3;
                LiteavLog.i(TAG, "EGLContext created with GLES 3.0");
            }
        }
        if (pickedContext == EGL14.EGL_NO_CONTEXT) {
            // clear any error code left by the failed ES3 attempt
            EGL14.eglGetError();
            EGLConfig configEs2 = chooseEGLConfig(EGL14.EGL_OPENGL_ES2_BIT);
            if (configEs2 == null) {
                checkEglError("eglChooseConfig error");
                return false;
            }
            EGLContext ctx = tryCreateContext(configEs2, 2);
            if (ctx == EGL14.EGL_NO_CONTEXT) {
                LiteavLog.e(TAG, "create GLES2 context failed");
                return false;
            }
            pickedConfig = configEs2;
            pickedContext = ctx;
            mActiveGLESMajor = 2;
            LiteavLog.i(TAG, "EGLContext created with GLES 2.0 (fallback)");
        }
        mEGLContextEncoder = pickedContext;

        int[] surfaceAttribs2 = {
                EGL14.EGL_NONE
        };
        mEGLSurfaceEncoder = EGL14.eglCreateWindowSurface(mEGLDisplay, pickedConfig, surface,
                surfaceAttribs2, 0);   //creates an EGL window surface and returns its handle
        checkEglError("eglCreateWindowSurface", false);

        if (mEGLSurfaceEncoder == EGL14.EGL_NO_SURFACE) {
            LiteavLog.e(TAG, "surface was null");
            return false;
        }
        mOutPutSurface = surface;
        return true;
    }

    /**
     * Choose an EGLConfig with RGBA8888 + window surface and the requested renderable type bit.
     * Returns null on failure (error code is cleared internally so callers can retry safely).
     */
    private EGLConfig chooseEGLConfig(int renderableType) {
        int[] attribList = new int[]{
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, renderableType,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_NONE
        };
        EGLConfig[] configs = new EGLConfig[1];
        int[] num = new int[1];
        boolean ok = EGL14.eglChooseConfig(mEGLDisplay, attribList, 0,
                configs, 0, configs.length, num, 0);
        if (!ok || num[0] <= 0 || configs[0] == null) {
            // clear error code, do not pollute subsequent checkEglError
            EGL14.eglGetError();
            return null;
        }
        return configs[0];
    }

    /**
     * Attempt to create an EGLContext with the given GLES major version.
     * Returns EGL14.EGL_NO_CONTEXT on failure (with error code cleared).
     */
    private EGLContext tryCreateContext(EGLConfig config, int glesMajor) {
        int[] attribList = {
                EGL14.EGL_CONTEXT_CLIENT_VERSION, glesMajor,
                EGL14.EGL_NONE
        };
        EGLContext ctx = EGL14.eglCreateContext(mEGLDisplay, config,
                EGL14.EGL_NO_CONTEXT, attribList, 0);
        if (ctx == EGL14.EGL_NO_CONTEXT) {
            // clear error code, fallback path will retry with a different version
            EGL14.eglGetError();
        }
        return ctx;
    }

    /**
     * Whether the current EGLContext was created with GLES 3.0 capability.
     * Should only be queried after initOpengl() has been called.
     */
    public boolean isGLES3Available() {
        return mActiveGLESMajor >= 3;
    }

    private boolean checkEglError(String msg) {
        return checkEglError(msg, true);
    }

    private boolean checkEglError(String msg, boolean needPrintMsg) {
        int error = 0;
        if ((error = EGL14.eglGetError()) != EGL14.EGL_SUCCESS) {
            LiteavLog.e(TAG, "checkEglError: " + msg + "error: " + error);
            return false;
        } else if (needPrintMsg) {
            LiteavLog.e(TAG, msg);
        }

        return true;
    }

    public boolean makeCurrent(int index) {
        if (index == 0) {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurface, mEGLSurface, mEGLContext)) {
                checkEglError("makeCurrent");
                return false;
            }
        } else {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurfaceEncoder, mEGLSurfaceEncoder, mEGLContextEncoder)) {
                checkEglError("makeCurrent");
                return false;
            }
        }
        return true;
    }

    public boolean swapBuffers() {
        boolean result = EGL14.eglSwapBuffers(mEGLDisplay, mEGLSurfaceEncoder);
        checkEglError("eglSwapBuffers", false);
        return result;
    }

    private void saveCurrentEglEnvironment() {
        try {
            // 获取当前环境
            mEGLSavedDisplay = EGL14.eglGetCurrentDisplay();
            mEGLSavedContext = EGL14.eglGetCurrentContext();
            mEGLSaveDrawSurface = EGL14.eglGetCurrentSurface(EGL14.EGL_DRAW);
            mEGLSaveReadSurface = EGL14.eglGetCurrentSurface(EGL14.EGL_READ);
        } catch (Exception e) {
            LiteavLog.e(TAG, "Save EGL error: " + e);
            resetSavedEnvironment();
        }
    }

    private void resetSavedEnvironment() {
        mEGLSavedDisplay = EGL14.EGL_NO_DISPLAY;
        mEGLSaveDrawSurface = EGL14.EGL_NO_SURFACE;
        mEGLSaveReadSurface = EGL14.EGL_NO_SURFACE;
        mEGLSavedContext = EGL14.EGL_NO_CONTEXT;
    }

    private void restoreEglEnvironment() {
        try {
            // 检查是否有效保存了EGL环境
            if (mEGLSavedDisplay != EGL14.EGL_NO_DISPLAY
                    && mEGLSavedContext != EGL14.EGL_NO_CONTEXT
                    && mEGLSaveDrawSurface != EGL14.EGL_NO_SURFACE) {

                // 检查当前环境是否已被更改
                EGLDisplay currentDisplay = EGL14.eglGetCurrentDisplay();
                EGLContext currentContext = EGL14.eglGetCurrentContext();
                EGLSurface currentDrawSurface = EGL14.eglGetCurrentSurface(EGL14.EGL_DRAW);

                // 仅在必要时才恢复环境
                if (!mEGLSavedDisplay.equals(currentDisplay)
                        || !mEGLSavedContext.equals(currentContext)
                        || !mEGLSaveDrawSurface.equals(currentDrawSurface)) {

                    // 安全恢复操作
                    if (!EGL14.eglMakeCurrent(
                            mEGLSavedDisplay,
                            mEGLSaveDrawSurface,
                            mEGLSaveReadSurface,
                            mEGLSavedContext)) {

                        int error = EGL14.eglGetError();
                        LiteavLog.e(TAG, "Restore failed: EGL error 0x" + Integer.toHexString(error));

                        // 恢复失败时的安全回退
                        EGL14.eglMakeCurrent(
                                mEGLSavedDisplay,
                                EGL14.EGL_NO_SURFACE,
                                EGL14.EGL_NO_SURFACE,
                                EGL14.EGL_NO_CONTEXT
                        );
                    }
                }
            } else {
                if (mEGLDisplay != EGL14.EGL_NO_DISPLAY) {
                    EGL14.eglMakeCurrent(
                            mEGLDisplay,
                            EGL14.EGL_NO_SURFACE,
                            EGL14.EGL_NO_SURFACE,
                            EGL14.EGL_NO_CONTEXT
                    );
                }
            }
        } catch (Exception e) {
            LiteavLog.e(TAG, "Critical restore error: " + e);
        } finally {
            // 重置保存的环境状态
            mEGLSavedDisplay = EGL14.EGL_NO_DISPLAY;
            mEGLSaveDrawSurface = EGL14.EGL_NO_SURFACE;
            mEGLSaveReadSurface = EGL14.EGL_NO_SURFACE;
            mEGLSavedContext = EGL14.EGL_NO_CONTEXT;
        }
    }

    private void releaseEgl() {
        if (mEGLDisplay != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(mEGLDisplay, EGL14.EGL_NO_SURFACE,
                    EGL14.EGL_NO_SURFACE,
                    EGL14.EGL_NO_CONTEXT);
        }
        if (mEGLSurfaceEncoder != EGL14.EGL_NO_SURFACE) {
            EGL14.eglDestroySurface(mEGLDisplay, mEGLSurfaceEncoder);
        }
        if (mEGLContextEncoder != EGL14.EGL_NO_CONTEXT) {
            EGL14.eglDestroyContext(mEGLDisplay, mEGLContextEncoder);
        }

        EGL14.eglTerminate(mEGLDisplay);

        mEGLDisplay = EGL14.EGL_NO_DISPLAY;
        mEGLSurfaceEncoder = EGL14.EGL_NO_SURFACE;
        mEGLContextEncoder = EGL14.EGL_NO_CONTEXT;
        mActiveGLESMajor = 0;
    }

    private void eglUninstall(boolean needReleaseDecodeSurface) {
        if (!makeCurrent(1)) {
            LiteavLog.e(TAG, "makeCurrent error");
            return;
        }
        if (mTextureRender != null) {
            mTextureRender.deleteTexture();
        }
        
        if (mTRTCHelper != null) {
            mTRTCHelper.release();
            mTRTCHelper = null;
        }

        releaseEgl();

        if (needReleaseDecodeSurface && mInputSurface != null) {
            mInputSurface.release();
            mInputSurface = null;
        }
        
        if (mSurfaceTexture != null) {
            mSurfaceTexture.release();
            mSurfaceTexture = null;
        }
    }

    public void startRender() {
        LiteavLog.i(TAG, "called start render");
        if (mDrawHandlerThread.isAlive()) {
            LiteavLog.e(TAG, "old draw thread is alive, stop first");
            mDrawHandlerThread.quitSafely();
        }
        mDrawHandlerThread = new HandlerThread(TAG);
        mDrawHandlerThread.start();
        mDrawHandler = new Handler(mDrawHandlerThread.getLooper());
        mStart = true;

        // 在渲染线程上初始化 Choreographer，使 VSync 回调直接派发到本线程，零线程切换
        mDrawHandler.post(new Runnable() {
            @Override
            public void run() {
                mChoreographer = Choreographer.getInstance();
            }
        });
    }

    public void refreshRender() {
        refreshRender(false);
    }

    public void refreshRender(final boolean isForcePullFrame) {
        if (null == mDrawHandler) {
            return;
        }
        mDrawHandler.post(new Runnable() {
            @Override
            public void run() {
                // 强制拉帧：立即同步执行一次 updateTexImage，保证首帧/seek 后画面及时更新
                if (isForcePullFrame) {
                    mLock.lock();
                    try {
                        startDrawSurface(true);
                    } finally {
                        mLock.unlock();
                    }
                }

                // 防抖：序列进行中则只续命剩余帧数，回调实例永远只有一个
                boolean needSchedule = (mRefreshFramesLeft <= 0);
                mRefreshFramesLeft = REFRESH_FRAME_COUNT;

                if (needSchedule && mChoreographer != null) {
                    mChoreographer.postFrameCallback(mRefreshFrameCallback);
                }
            }
        });
    }

    public synchronized void resumeRender() {
        mLock.lock();
        mStart = true;
        mLock.unlock();
    }

    public synchronized void pauseRender() {
        mLock.lock();
        mStart = false;
        mLock.unlock();
    }

    public synchronized void stopRender() {
        stopRender(true);
    }

    public synchronized void stopRender(boolean isCompleteRelease) {
        if (isReleased) {
            LiteavLog.i(TAG, "stopRender return, already released");
            return;
        }
        LiteavLog.i(TAG, "stopRender");
        // unLock render thread
        mStart = false;
        mRefreshFramesLeft = 0;
        if (mChoreographer != null) {
            mChoreographer.removeFrameCallback(mRefreshFrameCallback);
            mChoreographer = null;
        }
        mRotation = 0;
        if (null != mTextureRender) {
            mTextureRender.setRotationAngle(0);
        }
        saveCurrentEglEnvironment();
        final boolean contextCompare = mEGLContextEncoder.equals(mEGLSavedContext);
        eglUninstall(isCompleteRelease);
        if (null != mDrawHandlerThread) {
            mDrawHandlerThread.quitSafely();
            mDrawHandler = null;
        }

        mEnableFrameCopy = false;
        mFrameCopyListener = null;
        mCachedPixelFrame = null;

        if (!contextCompare) {
            LiteavLog.d(TAG, "restoreEglEnvironment");
            restoreEglEnvironment();
        }
        isReleased = true;
    }

    public Surface getInputSurface() {
        return mInputSurface;
    }

    public void clearSurfaceIfCan() {
        if (null != mTextureRender) {
            mTextureRender.cleanDrawCache();
        }
    }

    public void setEnableFrameCopy(boolean enable, OnFrameCopyListener listener) {
        mEnableFrameCopy = enable;
        mFrameCopyListener = listener;
    }

    /**
     * 复制当前帧用于 TRTC 推流
     */
    private void copyFrameForTRTC() {
        if (!mEnableFrameCopy || mTextureRender == null) {
            return;
        }

        int textureId = mTextureRender.getTextureID();
        if (textureId <= 0) {
            return;
        }

        if (mTRTCHelper == null) {
            mTRTCHelper = new FVodTRTCHelper();
        }

        int copyWidth = mWidth;
        int copyHeight = mHeight;
        if (copyWidth <= 0 || copyHeight <= 0) {
            return;
        }

        if (!mTRTCHelper.isInitialized()
                || mTRTCHelper.getTextureWidth() != copyWidth
                || mTRTCHelper.getTextureHeight() != copyHeight) {
            if (!mTRTCHelper.init(copyWidth, copyHeight)) {
                LiteavLog.e(TAG, "Failed to init TRTCHelper");
                return;
            }
        }

        int copyTextureId = mTRTCHelper.copyFrame(textureId);
        if (copyTextureId > 0 && mFrameCopyListener != null) {
            // 单线程模型使用成员变量
            if (mCachedPixelFrame == null) {
                mCachedPixelFrame = new FTXPixelFrame();
            }
            mCachedPixelFrame.setTextureId(copyTextureId);
            mCachedPixelFrame.setWidth(copyWidth);
            mCachedPixelFrame.setHeight(copyHeight);
            mCachedPixelFrame.setGLContext(mEGLContextEncoder);
            mFrameCopyListener.onFrameCopied(mCachedPixelFrame);
        }
    }
}
