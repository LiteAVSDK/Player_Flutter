package com.tencent.vod.flutter.tools;

import android.graphics.Bitmap;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.os.Bundle;

import com.tencent.live2.V2TXLiveDef;
import com.tencent.vod.flutter.FTXEvent;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;

public class FTXV2LiveTools {

    public static V2TXLiveDef.V2TXLiveRotation transRotationFromDegree(int rotation) {
        V2TXLiveDef.V2TXLiveRotation rotationCode;
        if (rotation <= 0) {
            rotationCode = V2TXLiveDef.V2TXLiveRotation.V2TXLiveRotation0;
        } else if (rotation <= 90) {
            rotationCode = V2TXLiveDef.V2TXLiveRotation.V2TXLiveRotation90;
        } else if (rotation <= 180) {
            rotationCode = V2TXLiveDef.V2TXLiveRotation.V2TXLiveRotation180;
        } else {
            rotationCode = V2TXLiveDef.V2TXLiveRotation.V2TXLiveRotation270;
        }
        return rotationCode;
    }

    public static ByteBuffer yuv420ToARGB8888(ByteBuffer yuv420Buffer, int width, int height) {
        // 将YUV420格式的ByteBuffer转换为byte数组
        byte[] yuv420Bytes = new byte[yuv420Buffer.remaining()];
        yuv420Buffer.get(yuv420Bytes);

        // 将YUV420格式的byte数组转换为Bitmap
        YuvImage yuvImage = new YuvImage(yuv420Bytes, ImageFormat.YUV_420_888, width, height, null);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Rect rect = new Rect(0, 0, width, height);
        yuvImage.compressToJpeg(rect, 100, outputStream);
        byte[] argbBytes = outputStream.toByteArray();

        // 将ARGB8888格式的byte数组转换为ByteBuffer
        return ByteBuffer.wrap(argbBytes);
    }

    public static Bundle buildNetBundle(V2TXLiveDef.V2TXLivePlayerStatistics statistics) {
        Bundle bundle = new Bundle();
        if (null != statistics) {
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_CPU_USAGE, statistics.appCpu);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_WIDTH, statistics.width);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_HEIGHT, statistics.height);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_NET_SPEED, statistics.netSpeed);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_FPS, statistics.fps);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_BITRATE, statistics.videoBitrate);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_AUDIO_BITRATE, statistics.audioBitrate);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_NET_JITTER, statistics.jitterBufferDelay);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_SYSTEM_CPU, statistics.systemCpu);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_LOSS, statistics.videoPacketLoss);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_AUDIO_LOSS, statistics.audioPacketLoss);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_AUDIO_TOTAL_BLOCK_TIME, statistics.audioTotalBlockTime);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_TOTAL_BLOCK_TIME, statistics.videoTotalBlockTime);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_VIDEO_BLOCK_RATE, statistics.videoBlockRate);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_AUDIO_BLOCK_RATE, statistics.audioBlockRate);
            bundle.putInt(FTXEvent.TUINetConst.NET_STATUS_RTT, statistics.rtt);
        }
        return bundle;
    }

}
