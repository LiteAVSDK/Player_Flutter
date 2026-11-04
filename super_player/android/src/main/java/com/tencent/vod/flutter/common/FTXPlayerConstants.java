package com.tencent.vod.flutter.common;

public class FTXPlayerConstants {

    public interface FTXRenderMode {

        /**
         * 根据视频比例，完整展示出视频画面
         * Display the video content fully according to the video aspect ratio.
         */
        long ADJUST_RESOLUTION = 0;

        /**
         * 根据视频比例，填充满容器，超出部分裁剪
         * Fill the container completely according to the video aspect ratio, and crop the overflowing parts.
         */
        long FULL_FILL_CONTAINER = 1;

        /**
         * 根据视频比例，填充满容器，形变填充满容器
         * Fill the container completely according to the video aspect ratio, and deform to fill the container.
         */
        long SCALE_FULL_FILL_CONTAINER = 2;
    }

    public interface FTXDrmProvisionEnvInt {

        long DRM_PROVISION_ENV_COM = 0;

        long DRM_PROVISION_ENV_CN = 1;
    }

}
