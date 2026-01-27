package com.tencent.vod.flutter.player.render.gl;

import android.os.Build;
import android.util.Log;

import com.tencent.liteav.base.system.LiteavSystemInfo;
import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.player.render.FTXPixelFrame;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

public class FTRTCCloudClassInvoker {

    private static final String TAG = "FTRTCCloudClassInvoker";

    private static final int VIDEO_STREAM_TYPE_SUB = 2;

    static final int VIDEO_PIXEL_FORMAT_Texture_2D = 2;
    static final int VIDEO_BUFFER_TYPE_TEXTURE = 3;

    private Class mClazzTRTCCloud;
    private Class mClazzTRTCTexture;
    private Class mClazzTRTCVideoFrame;
    private Field mFieldTextureId;
    private Field mFieldEglContext10;
    private Field mFieldEglContext14;
    private Field mFieldTexture;
    private Field mFieldWidth;
    private Field mFieldHeight;
    private Field mFieldPixelFormat;
    private Field mFieldBufferType;
    private Field mFieldTimestamp;

    private Object mTRTCCloudObj;

    public FTRTCCloudClassInvoker(Object trtcCloud) {
        try {
            mClazzTRTCCloud = trtcCloud.getClass();
            mClazzTRTCTexture = Class.forName("com.tencent.trtc.TRTCCloudDef$TRTCTexture");
            mClazzTRTCVideoFrame = Class.forName("com.tencent.trtc.TRTCCloudDef$TRTCVideoFrame");

            mFieldTextureId = mClazzTRTCTexture.getDeclaredField("textureId");
            mFieldEglContext10 = mClazzTRTCTexture.getDeclaredField("eglContext10");
            mFieldTexture = mClazzTRTCVideoFrame.getDeclaredField("texture");
            mFieldWidth = mClazzTRTCVideoFrame.getDeclaredField("width");
            mFieldHeight = mClazzTRTCVideoFrame.getDeclaredField("height");
            mFieldPixelFormat = mClazzTRTCVideoFrame.getDeclaredField("pixelFormat");
            mFieldBufferType = mClazzTRTCVideoFrame.getDeclaredField("bufferType");
            mFieldTimestamp = mClazzTRTCVideoFrame.getDeclaredField("timestamp");

            if (LiteavSystemInfo.getSystemOSVersionInt() >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                mFieldEglContext14 = mClazzTRTCTexture.getDeclaredField("eglContext14");
            }
            mTRTCCloudObj = trtcCloud;
        } catch (Exception e) {
            LiteavLog.e(TAG, "init TRTCCloudClassInvokeWrapper error ", e);
        }
    }

    public void sendCustomVideoData(FTXPixelFrame pixelFrame) {
        try {
            Object texture = mClazzTRTCTexture.newInstance();
            mFieldTextureId.set(texture, pixelFrame.getTextureId());
            if (pixelFrame.getGLContext() instanceof javax.microedition.khronos.egl.EGLContext) {
                mFieldEglContext10.set(texture, pixelFrame.getGLContext());
            } else {
                mFieldEglContext14.set(texture, pixelFrame.getGLContext());
            }

            Object videoFrame = mClazzTRTCVideoFrame.newInstance();
            mFieldTexture.set(videoFrame, texture);
            mFieldWidth.set(videoFrame, pixelFrame.getWidth());
            mFieldHeight.set(videoFrame, pixelFrame.getHeight());
            mFieldPixelFormat.set(videoFrame, VIDEO_PIXEL_FORMAT_Texture_2D);
            mFieldBufferType.set(videoFrame, VIDEO_BUFFER_TYPE_TEXTURE);
            mFieldTimestamp.set(videoFrame, 0);

            Method method = mClazzTRTCCloud.getDeclaredMethod("sendCustomVideoData", int.class, videoFrame.getClass());
            method.invoke(mTRTCCloudObj, VIDEO_STREAM_TYPE_SUB, videoFrame);

        } catch (Exception e) {
            LiteavLog.e(TAG, "sendCustomVideoData method error ", e);
        }
    }

    public void setTRTCCustomVideoCapture(boolean enable) {
        try {
            if (mTRTCCloudObj != null) {
                Class clazz = mTRTCCloudObj.getClass();
                Method method = clazz.getDeclaredMethod("enableCustomVideoCapture", int.class, boolean.class);
                method.invoke(mTRTCCloudObj, VIDEO_STREAM_TYPE_SUB, enable);
            }
        } catch (Exception e) {
            LiteavLog.e(TAG, "setTRTCCustomVideoCapture error " + Log.getStackTraceString(e));
        }
    }
}
