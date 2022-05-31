package com.tencent.vod.flutter;

import android.text.TextUtils;

import com.tencent.rtmp.TXPlayerGlobalSetting;
import com.tencent.rtmp.TXVodPlayConfig;

import java.util.HashMap;
import java.util.Map;

/**
 * 对象转化
 */
public class FTXTransformation {

    @SuppressWarnings("unchecked")
    public static TXVodPlayConfig transformToConfig(Map<Object, Object> config) {
        TXVodPlayConfig playConfig = new TXVodPlayConfig();

        Integer connectRetryCount = (Integer) config.get("connectRetryCount");
        if (intIsNotEmpty(connectRetryCount)) {
            playConfig.setConnectRetryCount(connectRetryCount);
        }

        Integer connectRetryInterval = (Integer) config.get("connectRetryInterval");
        if (intIsNotEmpty(connectRetryInterval)) {
            playConfig.setConnectRetryInterval(connectRetryInterval);
        }

        Integer timeout = (Integer) config.get("timeout");
        if (intIsNotEmpty(timeout)) {
            playConfig.setTimeout(timeout);
        }

        Integer playerType = (Integer) config.get("playerType");
        if(null != playerType) {
            playConfig.setPlayerType(playerType);
        }

        Map<String, String> headers = (Map<String, String>) config.get("headers");
        if (null == headers) {
            headers = new HashMap<>();
        }
        playConfig.setHeaders(headers);

        Boolean enableAccurateSeek = (Boolean) config.get("enableAccurateSeek");
        if(null != enableAccurateSeek) {
            playConfig.setEnableAccurateSeek(enableAccurateSeek);
        }

        Boolean autoRotate = (Boolean) config.get("autoRotate");
        if(null != autoRotate) {
            playConfig.setAutoRotate(autoRotate);
        }

        Boolean smoothSwitchBitrate = (Boolean) config.get("smoothSwitchBitrate");
        if(null != smoothSwitchBitrate) {
            playConfig.setSmoothSwitchBitrate(smoothSwitchBitrate);
        }

        String cacheMp4ExtName = (String) config.get("cacheMp4ExtName");
        if (!TextUtils.isEmpty(cacheMp4ExtName)) {
            playConfig.setCacheMp4ExtName(cacheMp4ExtName);
        }

        Integer progressInterval = (Integer) config.get("progressInterval");
        if (intIsNotEmpty(progressInterval)) {
            playConfig.setProgressInterval(progressInterval);
        }

        Integer maxBufferSize = (Integer) config.get("maxBufferSize");
        if (intIsNotEmpty(maxBufferSize)) {
            playConfig.setMaxBufferSize(maxBufferSize);
        }

        Integer maxPreloadSize = (Integer) config.get("maxPreloadSize");
        if (intIsNotEmpty(maxPreloadSize)) {
            playConfig.setMaxPreloadSize(maxPreloadSize);
        }

        Integer firstStartPlayBufferTime = (Integer) config.get("firstStartPlayBufferTime");
        if(null != firstStartPlayBufferTime) {
            playConfig.setFirstStartPlayBufferTime(firstStartPlayBufferTime);
        }

        Integer nextStartPlayBufferTime = (Integer) config.get("nextStartPlayBufferTime");
        if(null != nextStartPlayBufferTime) {
            playConfig.setNextStartPlayBufferTime(nextStartPlayBufferTime);
        }

        String overlayKey = (String) config.get("overlayKey");
        if (!TextUtils.isEmpty(overlayKey)) {
            playConfig.setOverlayKey(overlayKey);
        }

        String overlayIv = (String) config.get("overlayIv");
        if (!TextUtils.isEmpty(overlayIv)) {
            playConfig.setOverlayIv(overlayIv);
        }

        Map<String, Object> extInfoMap = (Map<String, Object>) config.get("extInfoMap");
        if (null == extInfoMap) {
            extInfoMap = new HashMap<>();
        }
        playConfig.setExtInfo(extInfoMap);

        Boolean enableRenderProcess = (Boolean) config.get("enableRenderProcess");
        if(null != enableRenderProcess) {
            playConfig.setEnableRenderProcess(enableRenderProcess);
        }

        String preferredResolutionStr = (String) config.get("preferredResolution");
        if (null != preferredResolutionStr) {
            long preferredResolution = Long.parseLong(preferredResolutionStr);
            playConfig.setPreferredResolution(preferredResolution);
        }

        return playConfig;
    }

    private static boolean intIsNotEmpty(Integer value) {
        return null != value && value > 0;
    }

}
