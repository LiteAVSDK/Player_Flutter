package com.tencent.vod.flutter.live.render;

import android.graphics.SurfaceTexture;
import android.opengl.EGLContext;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.util.Pair;
import android.view.Surface;
import android.widget.ImageView;

import androidx.annotation.NonNull;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.live2.V2TXLiveDef;
import com.tencent.vod.flutter.live.egl.EGL10Helper;
import com.tencent.vod.flutter.live.egl.EGL14Helper;
import com.tencent.vod.flutter.live.egl.EGLHelper;
import com.tencent.vod.flutter.live.egl.OpenGlUtils;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.ArrayDeque;
import java.util.Queue;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class FTXV2LiveRender {

    private static final String TAG = "FTXV2LiveRender";
    private static final long WAIT_FRAME_DURATION_MILL = 2000;
    private static final AtomicLong mRenderId = new AtomicLong();
    private static final int WHAT_DRAW_FRAME = 0x01;
    private static final int WHAT_UN_INIT = 0x02;
    private static final int WHAT_DESTROY = 0x03;
    private static final int WHAT_STOP = 0x04;
    private static final int WHAT_OFFER_FRAME = 0x05;
    private static final int WHAT_START_DRAW = 0x06;

    private Surface mSurface;
    private ExecutorService mRenderService = Executors.newFixedThreadPool(1);
    private final Queue<V2TXLiveDef.V2TXLiveVideoFrame> mDataPool = new ArrayDeque<>();
    private final Lock mDrawLock = new ReentrantLock();
    private final Condition mDrawCondition = mDrawLock.newCondition();
    private volatile boolean mIsInDrawing = false;
    private boolean mIsDestroyed = false;
    private final FloatBuffer mCubeBuffer;
    private final FloatBuffer mTextureBuffer;
    private final SurfaceTexture mSurfaceTexture;

    private FTXSize mSurfaceFTXSize = new FTXSize();
    private FTXSize mLastInputFTXSize = new FTXSize();
    private FTXSize mLastOutputFTXSize = new FTXSize();

    private FTXGPUImageFilter mImageFilter;
    /**
     * @noinspection rawtypes
     */
    private EGLHelper mEglHelper;
    private final HandlerThread mOptHandlerThread = new HandlerThread(TAG + mRenderId.getAndIncrement());
    private final Handler mOptHandler;
    private Future<?> mDrawServiceFuture;

    public FTXV2LiveRender(SurfaceTexture surfaceTexture) {
        mCubeBuffer = ByteBuffer.allocateDirect(OpenGlUtils.CUBE.length * 4)
                .order(ByteOrder.nativeOrder()).asFloatBuffer();
        mCubeBuffer.put(OpenGlUtils.CUBE).position(0);
        mTextureBuffer = ByteBuffer.allocateDirect(OpenGlUtils.TEXTURE.length * 4)
                .order(ByteOrder.nativeOrder()).asFloatBuffer();
        mTextureBuffer.put(OpenGlUtils.TEXTURE).position(0);
        mSurfaceTexture = surfaceTexture;
        mSurface = new Surface(surfaceTexture);
        // wait videoFrame to set size
        mSurfaceFTXSize = new FTXSize(1, 1);
        mOptHandlerThread.start();
        mOptHandler = new Handler(mOptHandlerThread.getLooper()) {
            @Override
            public void handleMessage(@NonNull Message msg) {
                switch (msg.what) {
                    case WHAT_DRAW_FRAME: {
                        if (mIsDestroyed || !mIsInDrawing) {
                            break;
                        }
                        V2TXLiveDef.V2TXLiveVideoFrame videoFrame = (V2TXLiveDef.V2TXLiveVideoFrame) msg.obj;
                        onDrawFrame(videoFrame);
                    }
                    break;
                    case WHAT_UN_INIT:
                        unInitEGL();
                        break;
                    case WHAT_STOP:
                        try {
                            stopInner();
                            if (null != mDrawServiceFuture) {
                                mDrawServiceFuture.get();
                            }
                            unInitEGL();
                        } catch (ExecutionException | InterruptedException e) {
                            LiteavLog.e(TAG, "stop render service error:" + e);
                        }
                        break;
                    case WHAT_DESTROY:
                        destroyInner();
                        break;
                    case WHAT_OFFER_FRAME: {
                        if (mIsDestroyed) {
                            break;
                        }
                        V2TXLiveDef.V2TXLiveVideoFrame videoFrame = (V2TXLiveDef.V2TXLiveVideoFrame) msg.obj;
                        mDrawLock.lock();
                        mDataPool.offer(videoFrame);
                        mDrawCondition.signalAll();
                        mDrawLock.unlock();
                    }
                    break;
                    case WHAT_START_DRAW:
                        startDrawInner();
                        break;
                    default:
                        LiteavLog.e(TAG, "un hit handler msg, what:" + msg.what);
                        break;
                }
            }
        };
    }

    public void updateFrame(V2TXLiveDef.V2TXLiveVideoFrame videoFrame) {
        if (mIsInDrawing) {
            Message message = new Message();
            message.what = WHAT_OFFER_FRAME;
            message.obj = videoFrame;
            mOptHandler.sendMessage(message);
        }
    }

    private void startDrawInner() {
        if (null == mRenderService || mRenderService.isShutdown()) {
            LiteavLog.e(TAG, "render service is already shutdown, please reCreated it");
            return;
        }
        mIsInDrawing = true;
        mDrawServiceFuture = mRenderService.submit(new Runnable() {
            @Override
            public void run() {
                while (mIsInDrawing) {
                    try {
                        mDrawLock.lock();
                        V2TXLiveDef.V2TXLiveVideoFrame videoFrame = mDataPool.poll();
                        while (null == videoFrame) {
                            boolean waitResult = mDrawCondition.await(WAIT_FRAME_DURATION_MILL, TimeUnit.MILLISECONDS);
                            if (!mIsInDrawing) {
                                LiteavLog.w(TAG, "render thread is interrupted by set drawing status");
                                return;
                            }
                            if (!waitResult) {
                                LiteavLog.w(TAG, "poll a null frame, please ensure "
                                        + "frame provider is working! wait time:"
                                        + WAIT_FRAME_DURATION_MILL);
                            } else {
                                videoFrame = mDataPool.poll();
                            }
                        }
                        Message message = new Message();
                        message.what = WHAT_DRAW_FRAME;
                        message.obj = videoFrame;
                        mOptHandler.sendMessage(message);
                    } catch (InterruptedException e) {
                        LiteavLog.w(TAG, "render service is interrupted:" + e);
                    } finally {
                        mDrawLock.unlock();
                    }
                }
            }
        });
    }

    public void startDraw() {
        mOptHandler.sendEmptyMessage(WHAT_START_DRAW);
    }

    private synchronized void onDrawFrame(V2TXLiveDef.V2TXLiveVideoFrame videoFrame) {
        V2TXLiveDef.V2TXLiveTexture txLiveTexture = videoFrame.texture;
        final int textureId = txLiveTexture.textureId;

        if (null == mEglHelper) {
            LiteavLog.e(TAG, "start create mEglHelper");
            Object eglContext = txLiveTexture.eglContext10 != null ? txLiveTexture.eglContext10
                    : txLiveTexture.eglContext14;
            initEGL(eglContext);
        }

        if (mEglHelper == null) {
            LiteavLog.e(TAG, "unSupport eglContext!pls check your params");
            return;
        }

        if (mLastInputFTXSize.width != videoFrame.width
                || mLastInputFTXSize.height != videoFrame.height
                || mLastOutputFTXSize.width != mSurfaceFTXSize.width
                || mLastOutputFTXSize.height != mSurfaceFTXSize.height) {
            final Pair<float[], float[]> cubeAndTextureBuffer = OpenGlUtils.calcCubeAndTextureBuffer(
                    ImageView.ScaleType.CENTER,
                    FTXRotation.ROTATION_180, false, videoFrame.width,
                    videoFrame.height, mSurfaceFTXSize.width, mSurfaceFTXSize.height);
            mSurfaceTexture.setDefaultBufferSize(videoFrame.width, videoFrame.height);
            mSurface = new Surface(mSurfaceTexture);
            mCubeBuffer.clear();
            mCubeBuffer.put(cubeAndTextureBuffer.first);
            mTextureBuffer.clear();
            mTextureBuffer.put(cubeAndTextureBuffer.second);

            mLastInputFTXSize = new FTXSize(videoFrame.width, videoFrame.height);
            mLastOutputFTXSize = new FTXSize(mSurfaceFTXSize.width, mSurfaceFTXSize.height);
            mSurfaceFTXSize.width = videoFrame.width;
            mSurfaceFTXSize.height = videoFrame.height;
        }

        mEglHelper.makeCurrent();
        GLES20.glViewport(0, 0, mSurfaceFTXSize.width, mSurfaceFTXSize.height);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glClearColor(0, 0, 0, 1.0f);
        GLES20.glClear(GLES20.GL_DEPTH_BUFFER_BIT | GLES20.GL_COLOR_BUFFER_BIT);
        mImageFilter.onDraw(textureId, mCubeBuffer, mTextureBuffer);
        mEglHelper.swapBuffers();
    }

    private void initEGL(Object eglContext) {
        if (eglContext instanceof javax.microedition.khronos.egl.EGLContext) {
            mEglHelper = EGL10Helper.createEGLSurface(null,
                    (javax.microedition.khronos.egl.EGLContext) eglContext, mSurface, 0, 0);
            LiteavLog.e(TAG, "create EGL10Helper done");
        } else {
            mEglHelper = EGL14Helper.createEGLSurface(null, (EGLContext) eglContext, mSurface, 0, 0);
            LiteavLog.e(TAG, "create EGL14Helper done");
        }
        if (null == mEglHelper) {
            LiteavLog.e(TAG, "unSupport eglContext!pls check your params");
            return;
        }
        mEglHelper.makeCurrent();
        mImageFilter = new FTXGPUImageFilter(true);
        mImageFilter.init();
    }

    private void unInitEGL() {
        LiteavLog.w(TAG, "start unInitEGL");
        if (mImageFilter != null) {
            mImageFilter.destroy();
            mImageFilter = null;
        }
        if (mEglHelper != null) {
            mEglHelper.unmakeCurrent();
            mEglHelper.destroy();
            mEglHelper = null;
        }
    }

    private void stopInner() {
        LiteavLog.w(TAG, "start stop live render");
        mDrawLock.lock();
        mIsInDrawing = false;
        mDataPool.clear();
        mDrawCondition.signalAll();
        mDrawLock.unlock();
    }

    private void destroyInner() {
        try {
            stopInner();
            mIsDestroyed = true;
            mRenderService.shutdown();
            if (mDrawServiceFuture != null) {
                mDrawServiceFuture.get();
                unInitEGL();
            }
        } catch (Exception e) {
            LiteavLog.e(TAG, "render service wait error:" + e);
            mRenderService.shutdownNow();
        } finally {
            mRenderService = null;
            mOptHandlerThread.quitSafely();
            mDataPool.clear();
        }
    }

    public void stopRender() {
        mOptHandler.sendEmptyMessage(WHAT_STOP);
    }

    public void destroy() {
        mOptHandler.sendEmptyMessage(WHAT_DESTROY);
    }

    public boolean isDrawing() {
        return mIsInDrawing;
    }

}
