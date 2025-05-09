package com.tencent.vod.flutter.player.render.gl;

import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.Matrix;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.common.FTXPlayerConstants;

import java.nio.FloatBuffer;

public class FTXTextureRender {
    private static final int FLOAT_SIZE_BYTES = 4;
    private static final String TAG = "FTXTextureRender";


    private static final float[] FULL_RECTANGLE_COORDS = {
            -1.0f, -1.0f, 1.0f,   // 0 bottom left
            1.0f, -1.0f, 1.0f,   // 1 bottom right
            -1.0f, 1.0f, 1.0f,   // 2 top left
            1.0f, 1.0f, 1.0f   // 3 top right
    };

    private static final float[] FULL_RECTANGLE_TEX_COORDS = {
            0.0f, 1.0f, 1f, 1.0f,    // 0 bottom left
            1.0f, 1.0f, 1f, 1.0f,     // 1 bottom right
            0.0f, 0.0f, 1f, 1.0f,    // 2 top left
            1.0f, 0.0f, 1f, 1.0f     // 3 top right
    };

    private static final FloatBuffer FULL_RECTANGLE_BUF =
            TXGlUtilVideo.createFloatBuffer(FULL_RECTANGLE_COORDS);
    private static final FloatBuffer FULL_RECTANGLE_TEX_BUF =
            TXGlUtilVideo.createFloatBuffer(FULL_RECTANGLE_TEX_COORDS);

    private static final String VERTEX_SHADER =
            "uniform mat4 uMVPMatrix;\n" +
                    "uniform mat4 uSTMatrix;\n" +
                    "attribute vec4 aPosition;\n" +
                    "attribute vec4 aTextureCoord;\n" +
                    "varying vec4 vTextureCoord;\n" +
                    "void main() {\n" +
                    "    gl_Position = uMVPMatrix * aPosition;\n" +
                    "    vTextureCoord = uSTMatrix * aTextureCoord;\n" +
                    "}\n";

    private static final String FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
                    "precision mediump float;\n" +      // highp here doesn't seem to matter
                    "varying vec4 vTextureCoord;\n" +
                    "uniform samplerExternalOES sTexture;\n" +
                    "void main() {\n" +
                    "    gl_FragColor = texture2D(sTexture, vTextureCoord.xy/vTextureCoord.z);" +
                    "}\n";

    private final float[] mSTMatrix = new float[16];
    private final float[] projectionMatrix = new float[16];

    private int mProgram;
    private int muMVPMatrixHandle;
    private int muSTMatrixHandle;
    private int maPositionHandle;
    private int maTextureHandle;
    private int mVideoWidth;
    private int mVideoHeight;
    private final int[] textureID = new int[1];
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;
    int mPortWidth;
    int mPortHeight;

    public FTXTextureRender(int width, int height) {
        Matrix.setIdentityM(mSTMatrix, 0);
        mPortWidth = width;
        mPortHeight = height;
    }

    /**
     * Initializes GL state.  Call this after the EGL surface has been created and made current.
     */
    public void surfaceCreated() {
        mProgram = TXGlUtilVideo.createProgram(VERTEX_SHADER, FRAGMENT_SHADER);
        if (mProgram == 0) {
            throw new RuntimeException("failed creating program");
        }

        maPositionHandle = GLES20.glGetAttribLocation(mProgram, "aPosition");
        maTextureHandle = GLES20.glGetAttribLocation(mProgram, "aTextureCoord");
        muMVPMatrixHandle = GLES20.glGetUniformLocation(mProgram, "uMVPMatrix");
        muSTMatrixHandle = GLES20.glGetUniformLocation(mProgram, "uSTMatrix");

        textureID[0] = initTex();
    }

    public int getTextureID() {
        return textureID[0];
    }

    public void deleteTexture() {
        GLES20.glDeleteProgram(mProgram);
        GLES20.glDeleteTextures(1, textureID, 0);
    }

    /**
     * create external texture
     *
     * @return texture ID
     */
    public int initTex() {
        int[] tex = new int[1];
        GLES20.glGenTextures(1, tex, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, tex[0]);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
        return tex[0];
    }

    public void updateSizeAndRenderMode(int width, int height, long renderMode) {
        mVideoWidth = width;
        mVideoHeight = height;
        mRenderMode = renderMode;
        if (mPortWidth > 0 && mPortHeight > 0 && mVideoWidth > 0 && mVideoHeight > 0) {
            float left = -1;
            float right = 1;
            float top = 1;
            float bottom = 1;

            final float videoRadio = (float) mVideoWidth / mVideoHeight;
            final float viewRadio = (float) mPortWidth / mPortHeight;
            boolean isFixWidth = false;
            if (renderMode == FTXPlayerConstants.FTXRenderMode.ADJUST_RESOLUTION) {
                isFixWidth = videoRadio > viewRadio;
            } else if (renderMode == FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER) {
                isFixWidth = videoRadio <= viewRadio;
            }

            if (isFixWidth) {
                final float viewShouldHeight = mPortWidth / videoRadio;
                final float heightRadio = viewShouldHeight / mPortHeight;
                left = -1f;
                right = 1f;
                bottom = -1f / heightRadio;
                top = 1f / heightRadio;
                LiteavLog.i(TAG, "heightRadio:" + heightRadio + ",mWidth:" + mVideoWidth
                        + ",mHeight:" + mVideoHeight + ",viewWidth:" + mPortWidth + "，viewHeight:"
                        + mPortHeight + ",hashCode:" + hashCode());
            } else {
                final float viewShouldWidth = mPortHeight * videoRadio;
                final float widthRadio = viewShouldWidth / mPortWidth;
                left = -1f / widthRadio;
                right = 1f / widthRadio;
                bottom = -1f;
                top = 1f;
                LiteavLog.i(TAG, "widthRadio:" + widthRadio + ",mWidth:" + mVideoWidth
                        + ",mHeight:" + mVideoHeight + ",viewWidth:" + mPortWidth + "，viewHeight:"
                        + mPortHeight + ",hashCode:" + hashCode());
            }
            Matrix.orthoM(projectionMatrix, 0, left, right, bottom, top, -1f, 1f);
        } else {
            LiteavLog.w(TAG, "updateSizeAndRenderMode failed, size maybe zero, mWidth:" + mVideoWidth
                    + ",mHeight:" + mVideoHeight + ",viewWidth:" + mPortWidth + "，viewHeight:"
                    + mPortHeight + ",hashCode:" + hashCode());
        }
    }

    public void setViewPortSize(int width, int height) {
        mPortWidth = width;
        mPortHeight = height;
        LiteavLog.i(TAG, "setViewPortSize：,viewWidth:" + mPortWidth
                + "，viewHeight：" + mPortHeight + ",hashCode:" + hashCode());
        updateSizeAndRenderMode(mVideoWidth, mVideoHeight, mRenderMode);
    }

    public void cleanDrawCache() {
        GLES20.glViewport(0, 0, mPortWidth, mPortHeight);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
    }

    /**
     * Draws the external texture in SurfaceTexture onto the current EGL surface.
     */
    public void drawFrame() {
        cleanDrawCache();
        // video frame
        GLES20.glUseProgram(mProgram);
        // Enable the "aPosition" vertex attribute.
        GLES20.glEnableVertexAttribArray(maPositionHandle);
        // Connect vertexBuffer to "aPosition".
        GLES20.glVertexAttribPointer(maPositionHandle, 3,
                GLES20.GL_FLOAT, false, 3 * FLOAT_SIZE_BYTES, FULL_RECTANGLE_BUF);
        // Enable the "aTextureCoord" vertex attribute.
        GLES20.glEnableVertexAttribArray(maTextureHandle);
        // Connect texBuffer to "aTextureCoord".
        GLES20.glVertexAttribPointer(maTextureHandle, 4,
                GLES20.GL_FLOAT, false, 4 * FLOAT_SIZE_BYTES, FULL_RECTANGLE_TEX_BUF);
        GLES20.glUniformMatrix4fv(muMVPMatrixHandle, 1, false, projectionMatrix, 0);
        GLES20.glUniformMatrix4fv(muSTMatrixHandle, 1, false, mSTMatrix, 0);
        // Draw the rect.
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        // Done -- disable vertex array, texture, and program.
        GLES20.glDisableVertexAttribArray(maPositionHandle);
        GLES20.glDisableVertexAttribArray(maTextureHandle);
        GLES20.glUseProgram(0);
    }

}
