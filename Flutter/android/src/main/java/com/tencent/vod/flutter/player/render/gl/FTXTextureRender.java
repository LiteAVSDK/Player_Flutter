package com.tencent.vod.flutter.player.render.gl;

import android.opengl.GLES11Ext;
import android.opengl.GLES30;
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
            "#version 300 es\n" +
                    "uniform mat4 uMVPMatrix;\n" +
                    "in vec4 aPosition;\n" +
                    "in vec2 aTextureCoord;\n" +
                    "out vec2 vTextureCoord;\n" +
                    "void main() {\n" +
                    "    gl_Position = uMVPMatrix * aPosition;\n" +
                    "    vTextureCoord = aTextureCoord;\n" +
                    "}\n";

    private static final String VIDEO_FRAGMENT_SHADER =
            "#version 300 es\n" +
                    "#extension GL_OES_EGL_image_external_essl3 : require\n" +
                    "precision mediump float;\n" +
                    "uniform samplerExternalOES sTexture;\n" +
                    "in vec2 vTextureCoord;\n" +
                    "out vec4 outColor;\n" +
                    "void main() {\n" +
                    "    outColor = texture(sTexture, vTextureCoord);\n" +
                    "}";

    private final float[] projectionMatrix = new float[16];
    private final float[] rotationMatrix = new float[16];
    private final float[] mResultMatrix = new float[16];

    private int mVideoFragmentProgram;
    private int muMVPMatrixHandle;
    private int maPositionHandle;
    private int maTexCoordHandle;
    private int maTextureHandle;
    private int mVideoWidth;
    private int mVideoHeight;
    private final int[] textureID = new int[1];
    private long mRenderMode = FTXPlayerConstants.FTXRenderMode.FULL_FILL_CONTAINER;
    private int mPortWidth;
    private int mPortHeight;

    private float rotationAngle = 0;

    public FTXTextureRender(int width, int height) {
        mPortWidth = width;
        mPortHeight = height;
    }

    /**
     * Initializes GL state.  Call this after the EGL surface has been created and made current.
     */
    public void surfaceCreated() {
        mVideoFragmentProgram = TXGlUtilVideo.createProgram(VERTEX_SHADER, VIDEO_FRAGMENT_SHADER);
        maPositionHandle = GLES30.glGetAttribLocation(mVideoFragmentProgram, "aPosition");
        maTexCoordHandle = GLES30.glGetAttribLocation(mVideoFragmentProgram, "aTextureCoord");
        muMVPMatrixHandle = GLES30.glGetUniformLocation(mVideoFragmentProgram, "uMVPMatrix");
        maTextureHandle = GLES30.glGetUniformLocation(mVideoFragmentProgram, "sTexture");

        textureID[0] = initTex();
    }

    public int getTextureID() {
        return textureID[0];
    }

    public void deleteTexture() {
        GLES30.glDeleteProgram(mVideoFragmentProgram);
        GLES30.glDeleteTextures(1, textureID, 0);
    }

    /**
     * create external texture
     *
     * @return texture ID
     */
    public int initTex() {
        int[] tex = new int[1];
        GLES30.glGenTextures(1, tex, 0);
        GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
        GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, tex[0]);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
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
            updateProjection(left, right, bottom, top);
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

    private void updateProjection(float left, float right, float bottom, float top) {
        // reset
        Matrix.setIdentityM(projectionMatrix, 0);
        Matrix.orthoM(projectionMatrix, 0, left, right, bottom, top, -1f, 1f);
        // merge
        mergerMatrix();
    }

    public void setRotationAngle(float angle) {
        rotationAngle = angle;
        // reset
        Matrix.setIdentityM(rotationMatrix, 0);
        Matrix.setRotateM(rotationMatrix, 0, rotationAngle, 0, 0, -1);
        // merge
        mergerMatrix();
    }

    private void mergerMatrix() {
        // reset
        Matrix.setIdentityM(mResultMatrix, 0);
        Matrix.multiplyMM(mResultMatrix, 0, rotationMatrix, 0, projectionMatrix, 0);
        System.arraycopy(mResultMatrix, 0, projectionMatrix, 0, 16);
    }

    public void cleanDrawCache() {
        GLES30.glViewport(0, 0, mPortWidth, mPortHeight);
        GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT);
    }

    /**
     * Draws the external texture in SurfaceTexture onto the current EGL surface.
     */
    public void drawFrame() {
        cleanDrawCache();
        // video frame
        GLES30.glUseProgram(mVideoFragmentProgram);

        // OpenGL rotates counterclockwise, here it needs to be modified to rotate clockwise
        GLES30.glUniformMatrix4fv(muMVPMatrixHandle, 1, false, mResultMatrix, 0);

        GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
        GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureID[0]);
        GLES30.glUniform1i(maTextureHandle, 0);

        // Enable the "aPosition" vertex attribute.
        GLES30.glEnableVertexAttribArray(maPositionHandle);
        // Connect vertexBuffer to "aPosition".
        GLES30.glVertexAttribPointer(maPositionHandle, 3,
                GLES30.GL_FLOAT, false, 3 * FLOAT_SIZE_BYTES, FULL_RECTANGLE_BUF);
        // Enable the "aTextureCoord" vertex attribute.
        GLES30.glEnableVertexAttribArray(maTexCoordHandle);
        // Connect texBuffer to "aTextureCoord".
        GLES30.glVertexAttribPointer(maTexCoordHandle, 4,
                GLES30.GL_FLOAT, false, 4 * FLOAT_SIZE_BYTES, FULL_RECTANGLE_TEX_BUF);
        // Draw the rect.
        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4);
        // Done -- disable vertex array, texture, and program.
        GLES30.glDisableVertexAttribArray(maPositionHandle);
        GLES30.glDisableVertexAttribArray(maTexCoordHandle);
        GLES30.glUseProgram(0);
    }
}
