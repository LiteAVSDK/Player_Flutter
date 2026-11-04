package com.tencent.vod.flutter.live.render;

import android.opengl.GLES20;

import com.tencent.vod.flutter.live.egl.OpenGlUtils;

import java.nio.FloatBuffer;
import java.util.LinkedList;

public class FTXGPUImageFilter {

    public static final String NO_FILTER_VERTEX_SHADER = ""
            + "attribute vec4 position;\n"
            + "attribute vec4 inputTextureCoordinate;\n"
            + " \n"
            + "varying vec2 textureCoordinate;\n"
            + " \n"
            + "void main()\n"
            + "{\n"
            + "    gl_Position = position;\n"
            + "    textureCoordinate = inputTextureCoordinate.xy;\n"
            + "}";

    public static final String NO_FILTER_FRAGMENT_SHADER = ""
            + "varying highp vec2 textureCoordinate;\n"
            + " \n"
            + "uniform sampler2D inputImageTexture;\n"
            + " \n"
            + "void main()\n"
            + "{\n"
            + "     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n"
            + "}";

    public static final String NO_FILTER_FRAGMENT_SHADER_FLIP = ""
            + "varying highp vec2 textureCoordinate;\n"
            + " \n"
            + "uniform sampler2D inputImageTexture;\n" + " \n"
            + "void main()\n"
            + "{\n"
            + "     gl_FragColor = texture2D(inputImageTexture, vec2(1.0 - textureCoordinate.x, "
            + "textureCoordinate.y));\n"
            + "}";

    protected FTXProgram mProgram;
    private final LinkedList<Runnable> mRunOnDraw;
    protected float[] mTextureMatrix;
    private int mGLAttribPosition;
    private int mGLUniformTexture;
    private int mGLAttribTextureCoordinate;
    private boolean mIsInitialized;

    public FTXGPUImageFilter() {
        this(false);
    }

    public FTXGPUImageFilter(boolean flip) {
        mRunOnDraw = new LinkedList<>();
        mProgram = new FTXProgram(NO_FILTER_VERTEX_SHADER,
                flip ? NO_FILTER_FRAGMENT_SHADER_FLIP : NO_FILTER_FRAGMENT_SHADER);
    }

    public final void init() {
        onInit();
        mIsInitialized = true;
    }

    protected void onInit() {
        mProgram.build();
        mGLAttribPosition = GLES20.glGetAttribLocation(mProgram.getProgramId(), "position");
        mGLUniformTexture = GLES20.glGetUniformLocation(mProgram.getProgramId(), "inputImageTexture");
        mGLAttribTextureCoordinate = GLES20.glGetAttribLocation(mProgram.getProgramId(), "inputTextureCoordinate");
        mIsInitialized = true;
    }

    public void onOutputSizeChanged(final int width, final int height) {
    }

    protected void onUninit() {
    }

    public final void destroy() {
        runPendingOnDrawTasks();
        onUninit();
        mIsInitialized = false;
        mProgram.destroy();
    }

    public int getTarget() {
        return GLES20.GL_TEXTURE_2D;
    }

    public void setTexutreTransform(float[] matrix) {
        mTextureMatrix = matrix;
    }

    public boolean isInitialized() {
        return mIsInitialized;
    }

    /**
     * Use OpenGL to render the screen.
     */
    public void onDraw(final int textureId, final FloatBuffer cubeBuffer, final FloatBuffer textureBuffer) {
        GLES20.glUseProgram(mProgram.getProgramId());
        runPendingOnDrawTasks();
        if (!mIsInitialized) {
            return;
        }

        cubeBuffer.position(0);
        GLES20.glVertexAttribPointer(mGLAttribPosition, 2, GLES20.GL_FLOAT, false, 0, cubeBuffer);
        GLES20.glEnableVertexAttribArray(mGLAttribPosition);
        textureBuffer.position(0);
        GLES20.glVertexAttribPointer(mGLAttribTextureCoordinate, 2, GLES20.GL_FLOAT, false, 0,
                textureBuffer);
        GLES20.glEnableVertexAttribArray(mGLAttribTextureCoordinate);

        if (textureId != OpenGlUtils.NO_TEXTURE) {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
            OpenGlUtils.bindTexture(getTarget(), textureId);
            GLES20.glUniform1i(mGLUniformTexture, 0);
        }

        beforeDrawArrays(textureId);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(mGLAttribPosition);
        GLES20.glDisableVertexAttribArray(mGLAttribTextureCoordinate);

        OpenGlUtils.bindTexture(getTarget(), 0);
    }

    protected void beforeDrawArrays(int textureId) {
    }

    protected void runPendingOnDrawTasks() {
        //Copy the current one to be run to a new array,
        // and then start execution to prevent the execution from being added again.
        LinkedList<Runnable> runList;
        synchronized (mRunOnDraw) {
            runList = new LinkedList<>(mRunOnDraw);
            mRunOnDraw.clear();
        }

        while (!runList.isEmpty()) {
            runList.removeFirst().run();
        }
    }
}
