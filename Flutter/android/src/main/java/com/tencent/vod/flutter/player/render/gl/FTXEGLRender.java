package com.tencent.vod.flutter.player.render.gl;

import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES30;
import android.os.Handler;
import android.os.HandlerThread;
import android.view.Surface;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class FTXEGLRender implements SurfaceTexture.OnFrameAvailableListener {

    private static final String TAG = "FTXEGLRender";

    private static final long FRAME_WAIT_TIME = 5000;
    private static final int FPS_DEFAULT = 30;
    // min refresh count for obtain new img
    private static final int RE_DRAW_COUNT = 30;

    private SurfaceTexture mSurfaceTexture;
    private FTXTextureRender mTextureRender;
    private Surface mInputSurface;

    private EGLDisplay mEGLDisplay = EGL14.EGL_NO_DISPLAY;
    private EGLContext mEGLContext = EGL14.EGL_NO_CONTEXT;
    private EGLContext mEGLContextEncoder = EGL14.EGL_NO_CONTEXT;
    private EGLSurface mEGLSurface = EGL14.EGL_NO_SURFACE;
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
                        startDrawSurface();
                        mLock.unlock();
                    } else {
                        mIsFirstFrame = false;
                        refreshRender();
                    }
                }
            });
        }
    }

    private synchronized void startDrawSurface() {
        try {
            if (!mStart) {
                LiteavLog.e(TAG, "end....... ");
                return;
            }
            saveCurrentEglEnvironment();
            if (!makeCurrent(1)) {
                LiteavLog.e(TAG, "makeCurrent error");
                return;
            }

            mCurrentTime = System.currentTimeMillis();
            mSurfaceTexture.updateTexImage();
            drawImage();
            swapBuffers();
            mPreTime = mCurrentTime;
        } catch (Exception e) {
            LiteavLog.e(TAG, "startDrawSurface error: " + e);
        } finally {
            restoreEglEnvironment();
        }
    }

    public void drawImage() {
        mTextureRender.drawFrame();
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
                LiteavLog.e(TAG, "makeCurrent error");
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

    public void setViewPortSize(int width, int height) {
        mViewWidth = width;
        mViewHeight = height;
        if (null != mSurfaceTexture) {
            mSurfaceTexture.setDefaultBufferSize(width, height);
        }
        if (null != mTextureRender) {
            mTextureRender.setViewPortSize(width, height);
        }
    }

    private boolean eglSetup(Surface surface) {
        mEGLDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
        if (mEGLDisplay == EGL14.EGL_NO_DISPLAY) {
            LiteavLog.e(TAG, "unable to get EGL10 display");
            return false;
        }

        int[] version = new int[2];
        if (!EGL14.eglInitialize(mEGLDisplay, version, 0, version, 1)) {
            LiteavLog.e(TAG, "unable to initialize EGL10");
            return false;
        }
        int[] maxSamples = new int[1];
        GLES30.glGetIntegerv(GLES30.GL_MAX_SAMPLES, maxSamples, 0);
        //noinspection ExtractMethodRecommender
        final int samples = Math.min(4, maxSamples[0]);
        // Configure EGL for pbuffer and OpenGL ES 2.0, 24-bit RGB.
        int[] attribList = new int[]{
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_DEPTH_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_SAMPLE_BUFFERS, 1,
                EGL14.EGL_SAMPLES, samples,
                EGL14.EGL_NONE
        };

        int[] numEglConfigs = new int[1];
        EGLConfig[] eglConfigs = new EGLConfig[1];
        if (!EGL14.eglChooseConfig(mEGLDisplay, attribList, 0, eglConfigs, 0,
                eglConfigs.length, numEglConfigs, 0)) {
            LiteavLog.e(TAG, "eglChooseConfig error");
            return false;
        }
        // Configure context for OpenGL ES 2.0.
        //6、创建 EglContext
        int[] attrib_list = new int[]{
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 3,
                EGL14.EGL_NONE
        };

        mEGLContextEncoder = EGL14.eglCreateContext(mEGLDisplay, eglConfigs[0], EGL14.EGL_NO_CONTEXT,
                attrib_list, 0);
        checkEglError("eglCreateContext");
        if (mEGLContextEncoder == EGL14.EGL_NO_CONTEXT) {
            LiteavLog.e(TAG, "null context2");
            return false;
        }

        int[] surfaceAttribs2 = {
                EGL14.EGL_NONE
        };
        mEGLSurfaceEncoder = EGL14.eglCreateWindowSurface(mEGLDisplay, eglConfigs[0], surface,
                surfaceAttribs2, 0);   //creates an EGL window surface and returns its handle
        checkEglError("eglCreateWindowSurface");

        if (mEGLSurfaceEncoder == EGL14.EGL_NO_SURFACE) {
            LiteavLog.e(TAG, "surface was null");
            return false;
        }
        return true;
    }

    private boolean checkEglError(String msg) {
        int error = 0;
        if ((error = EGL14.eglGetError()) != EGL14.EGL_SUCCESS) {
            LiteavLog.e(TAG, "checkEglError: " + msg + "error: " + error);
            return false;
        }

        return true;
    }

    public boolean makeCurrent(int index) {
        if (index == 0) {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurface, mEGLSurface, mEGLContext)) {
                LiteavLog.e(TAG, "eglMakeCurrent failed");
                return false;
            }
        } else {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurfaceEncoder, mEGLSurfaceEncoder, mEGLContextEncoder)) {
                LiteavLog.e(TAG, "eglMakeCurrent failed");
                return false;
            }
        }

        return true;
    }

    public boolean swapBuffers() {
        boolean result = EGL14.eglSwapBuffers(mEGLDisplay, mEGLSurfaceEncoder);
        checkEglError("eglSwapBuffers");
        return result;
    }

    private void saveCurrentEglEnvironment() {
        try {
            // 获取当前环境
            mEGLSavedDisplay = EGL14.eglGetCurrentDisplay();
            mEGLSavedContext = EGL14.eglGetCurrentContext();
            mEGLSaveDrawSurface = EGL14.eglGetCurrentSurface(EGL14.EGL_DRAW);
            mEGLSaveReadSurface = EGL14.eglGetCurrentSurface(EGL14.EGL_READ);

//            // 检查有效性
//            if (mEGLSavedDisplay == EGL14.EGL_NO_DISPLAY || mEGLSavedContext == EGL14.EGL_NO_CONTEXT) {
//                LiteavLog.w(TAG, "Saving invalid EGL state");
//            }
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
    }

    private void eglUninstall(boolean needReleaseDecodeSurface) {
        if (!makeCurrent(1)) {
            LiteavLog.e(TAG, "makeCurrent error");
            return;
        }
        if (mTextureRender != null) {
            mTextureRender.deleteTexture();
        }
        releaseEgl();

        if (needReleaseDecodeSurface && mInputSurface != null) {
            mInputSurface.release();
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
    }

    public void refreshRender() {
        if (null != mDrawHandler) {
            mDrawHandler.post(new Runnable() {
                @Override
                public void run() {
                    mLock.lock();
                    for (int i = 0; i < RE_DRAW_COUNT; i++) {
                        startDrawSurface();
                    }
                    mLock.unlock();
                }
            });
        }
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

}
