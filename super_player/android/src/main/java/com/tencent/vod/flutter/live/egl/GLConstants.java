package com.tencent.vod.flutter.live.egl;

public class GLConstants {
    boolean debug = false;
    int noTexture = -1;
    int invalidProgramId = -1;

    static float[] CUBE_VERTICES_ARRAYS = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
    };

    static float[] TEXTURE_COORDS_NO_ROTATION = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f
    };
    static float[] TEXTURE_COORDS_ROTATE_LEFT = {
            1.0f, 0.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            0.0f, 1.0f
    };
    static float[] TEXTURE_COORDS_ROTATE_RIGHT = {
            0.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 1.0f,
            1.0f, 0.0f
    };
    static float[] TEXTURE_COORDS_ROTATED_180 = {
            1.0f, 1.0f,
            0.0f, 1.0f,
            1.0f, 0.0f,
            0.0f, 0.0f
    };

    enum GLScaleType {
        /**
         * 居中显示，不裁剪，宽或高留黑边
         */
        FIT_CENTER,

        /**
         * 居中裁剪
         */
        CENTER_CROP,
    }
}
