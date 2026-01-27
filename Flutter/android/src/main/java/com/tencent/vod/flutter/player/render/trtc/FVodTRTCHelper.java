package com.tencent.vod.flutter.player.render.trtc;

import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.Matrix;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.player.render.gl.TXGlUtilVideo;

import java.nio.FloatBuffer;

public class FVodTRTCHelper {

    private static final String TAG = "FVodTRTCHelper";
    private static final int FLOAT_SIZE_BYTES = 4;

    private final int[] mFrameBuffer = new int[1];
    private final int[] mCopyTextureId = new int[1];
    private int mTextureWidth;
    private int mTextureHeight;
    private boolean mIsInitialized = false;

    private int mProgram;
    private int mPositionHandle;
    private int mTexCoordHandle;
    private int mMVPMatrixHandle;
    private int mTextureHandle;

    private final float[] mIdentityMatrix = new float[16];

    private static final float[] VERTEX_COORDS = {
            -1.0f, -1.0f, 0.0f,   // 左下
            1.0f, -1.0f, 0.0f,    // 右下
            -1.0f, 1.0f, 0.0f,    // 左上
            1.0f, 1.0f, 0.0f      // 右上
    };

    private static final float[] TEXTURE_COORDS = {
            0.0f, 0.0f,   // 左下
            1.0f, 0.0f,   // 右下
            0.0f, 1.0f,   // 左上
            1.0f, 1.0f    // 右上
    };

    private static final FloatBuffer VERTEX_BUFFER = TXGlUtilVideo.createFloatBuffer(VERTEX_COORDS);
    private static final FloatBuffer TEX_COORD_BUFFER = TXGlUtilVideo.createFloatBuffer(TEXTURE_COORDS);

    private static final String VERTEX_SHADER =
            "uniform mat4 uMVPMatrix;\n"
                    + "attribute vec4 aPosition;\n"
                    + "attribute vec2 aTextureCoord;\n"
                    + "varying vec2 vTextureCoord;\n"
                    + "void main() {\n"
                    + "    gl_Position = uMVPMatrix * aPosition;\n"
                    + "    vTextureCoord = aTextureCoord;\n"
                    + "}\n";

    private static final String FRAGMENT_SHADER_OES =
            "#extension GL_OES_EGL_image_external : require\n"
                    + "precision mediump float;\n"
                    + "varying vec2 vTextureCoord;\n"
                    + "uniform samplerExternalOES sTexture;\n"
                    + "void main() {\n"
                    + "    gl_FragColor = texture2D(sTexture, vTextureCoord);\n"
                    + "}\n";

    public FVodTRTCHelper() {
        Matrix.setIdentityM(mIdentityMatrix, 0);
    }

    /**
     * 初始化 FBO 和复制纹理
     * 必须在 GL 线程中调用
     *
     * @param width  纹理宽度
     * @param height 纹理高度
     * @return 是否初始化成功
     */
    public boolean init(int width, int height) {
        if (mIsInitialized && mTextureWidth == width && mTextureHeight == height) {
            LiteavLog.d(TAG, "Already initialized with same size");
            return true;
        }

        // 如果已初始化但尺寸不同，先释放
        if (mIsInitialized) {
            release();
        }

        mTextureWidth = width;
        mTextureHeight = height;

        mProgram = TXGlUtilVideo.createProgram(VERTEX_SHADER, FRAGMENT_SHADER_OES);
        if (mProgram == 0) {
            LiteavLog.e(TAG, "Failed to create program");
            return false;
        }

        mPositionHandle = GLES20.glGetAttribLocation(mProgram, "aPosition");
        mTexCoordHandle = GLES20.glGetAttribLocation(mProgram, "aTextureCoord");
        mMVPMatrixHandle = GLES20.glGetUniformLocation(mProgram, "uMVPMatrix");
        mTextureHandle = GLES20.glGetUniformLocation(mProgram, "sTexture");

        // 创建 2D 纹理用于存储复制的图像
        GLES20.glGenTextures(1, mCopyTextureId, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mCopyTextureId[0]);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, width, height, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);

        GLES20.glGenFramebuffers(1, mFrameBuffer, 0);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mFrameBuffer[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_TEXTURE_2D, mCopyTextureId[0], 0);

        int status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER);
        if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            LiteavLog.e(TAG, "Framebuffer not complete, status: " + status);
            release();
            return false;
        }

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        mIsInitialized = true;
        LiteavLog.i(TAG, "Initialized successfully, size: " + width + "x" + height);
        return true;
    }

    public int copyFrame(int oesTextureId) {
        return copyFrame(oesTextureId, mIdentityMatrix);
    }

    /**
     * 从 OES 纹理复制帧到 2D 纹理，支持变换矩阵
     * 必须在 GL 线程中调用
     */
    public int copyFrame(int oesTextureId, float[] mvpMatrix) {
        if (!mIsInitialized) {
            LiteavLog.e(TAG, "Not initialized");
            return -1;
        }

        int[] savedViewport = new int[4];
        GLES20.glGetIntegerv(GLES20.GL_VIEWPORT, savedViewport, 0);
        int[] savedFramebuffer = new int[1];
        GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, savedFramebuffer, 0);
        int[] savedProgram = new int[1];
        GLES20.glGetIntegerv(GLES20.GL_CURRENT_PROGRAM, savedProgram, 0);

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mFrameBuffer[0]);
        GLES20.glViewport(0, 0, mTextureWidth, mTextureHeight);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

        GLES20.glUseProgram(mProgram);

        GLES20.glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix, 0);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId);
        GLES20.glUniform1i(mTextureHandle, 0);

        GLES20.glEnableVertexAttribArray(mPositionHandle);
        GLES20.glVertexAttribPointer(mPositionHandle, 3, GLES20.GL_FLOAT, false,
                3 * FLOAT_SIZE_BYTES, VERTEX_BUFFER);

        GLES20.glEnableVertexAttribArray(mTexCoordHandle);
        GLES20.glVertexAttribPointer(mTexCoordHandle, 2, GLES20.GL_FLOAT, false,
                2 * FLOAT_SIZE_BYTES, TEX_COORD_BUFFER);

        // 绘制
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mPositionHandle);
        GLES20.glDisableVertexAttribArray(mTexCoordHandle);

        GLES20.glUseProgram(savedProgram[0]);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, savedFramebuffer[0]);
        GLES20.glViewport(savedViewport[0], savedViewport[1], savedViewport[2], savedViewport[3]);

        return mCopyTextureId[0];
    }

    public int getCopyTextureId() {
        return mIsInitialized ? mCopyTextureId[0] : -1;
    }

    public int getTextureWidth() {
        return mTextureWidth;
    }

    public int getTextureHeight() {
        return mTextureHeight;
    }

    public boolean isInitialized() {
        return mIsInitialized;
    }

    /**
     * 必须在 GL 线程中调用
     */
    public void release() {
        if (!mIsInitialized) {
            return;
        }

        if (mFrameBuffer[0] != 0) {
            GLES20.glDeleteFramebuffers(1, mFrameBuffer, 0);
            mFrameBuffer[0] = 0;
        }

        if (mCopyTextureId[0] != 0) {
            GLES20.glDeleteTextures(1, mCopyTextureId, 0);
            mCopyTextureId[0] = 0;
        }

        if (mProgram != 0) {
            GLES20.glDeleteProgram(mProgram);
            mProgram = 0;
        }

        mIsInitialized = false;
        mTextureWidth = 0;
        mTextureHeight = 0;
        LiteavLog.i(TAG, "Released");
    }
}
