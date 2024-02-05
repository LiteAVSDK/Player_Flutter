// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.text.TextUtils;

import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXVodPlayConfig;

import com.tencent.vod.flutter.messages.FtxMessages.FTXLivePlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXVodPlayConfigPlayerMsg;
import java.util.HashMap;
import java.util.Map;

/**
 * Object conversion.
 *
 * 对象转化
 */
public class FTXTransformation {

    /**
     * Convert msg to config.
     *
     * 将msg转换为config
     */
    public static TXVodPlayConfig transformToVodConfig(FTXVodPlayConfigPlayerMsg configPlayerMsg) {
        TXVodPlayConfig playConfig = new TXVodPlayConfig();
        if (null != configPlayerMsg.getConnectRetryCount()) {
            playConfig.setConnectRetryCount(configPlayerMsg.getConnectRetryCount().intValue());
        }
        if (null != configPlayerMsg.getProgressInterval()) {
            playConfig.setConnectRetryInterval(configPlayerMsg.getProgressInterval().intValue());
        }
        if (null != configPlayerMsg.getTimeout()) {
            playConfig.setTimeout(configPlayerMsg.getTimeout().intValue());
        }
        if (null != configPlayerMsg.getPlayerType()) {
            playConfig.setPlayerType(configPlayerMsg.getPlayerType().intValue());
        }
        playConfig.setHeaders(configPlayerMsg.getHeaders());
        if (null != configPlayerMsg.getEnableAccurateSeek()) {
            playConfig.setEnableAccurateSeek(configPlayerMsg.getEnableAccurateSeek());
        }
        if (null != configPlayerMsg.getAutoRotate()) {
            playConfig.setAutoRotate(configPlayerMsg.getAutoRotate());
        }
        if (null != configPlayerMsg.getSmoothSwitchBitrate()) {
            playConfig.setSmoothSwitchBitrate(configPlayerMsg.getSmoothSwitchBitrate());
        }
        playConfig.setCacheMp4ExtName(configPlayerMsg.getCacheMp4ExtName());
        if (null != configPlayerMsg.getProgressInterval()) {
            playConfig.setProgressInterval(configPlayerMsg.getProgressInterval().intValue());
        }
        if (null != configPlayerMsg.getMaxBufferSize()) {
            playConfig.setMaxBufferSize(configPlayerMsg.getMaxBufferSize().floatValue());
        }
        if (null != configPlayerMsg.getMaxPreloadSize()) {
            playConfig.setMaxPreloadSize(configPlayerMsg.getMaxPreloadSize().floatValue());
        }
        if (null != configPlayerMsg.getFirstStartPlayBufferTime()) {
            playConfig.setFirstStartPlayBufferTime(configPlayerMsg.getFirstStartPlayBufferTime().intValue());
        }
        if (null != configPlayerMsg.getNextStartPlayBufferTime()) {
            playConfig.setNextStartPlayBufferTime(configPlayerMsg.getNextStartPlayBufferTime().intValue());
        }
        playConfig.setOverlayKey(configPlayerMsg.getOverlayKey());
        playConfig.setOverlayIv(configPlayerMsg.getOverlayIv());
        playConfig.setExtInfo(configPlayerMsg.getExtInfoMap());
        if (null != configPlayerMsg.getEnableRenderProcess()) {
            playConfig.setEnableRenderProcess(configPlayerMsg.getEnableRenderProcess());
        }
        if (null != configPlayerMsg.getPreferredResolution()) {
            playConfig.setPreferredResolution(configPlayerMsg.getPreferredResolution());
        }

        return playConfig;
    }

    /**
     * Convert map to config.
     *
     * 将map转换为config
     */
    @SuppressWarnings("unchecked")
    public static TXVodPlayConfig transformToVodConfig(Map<Object, Object> config) {
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
        if (null != playerType) {
            playConfig.setPlayerType(playerType);
        }
        Map<String, String> headers = (Map<String, String>) config.get("headers");
        if (null == headers) {
            headers = new HashMap<>();
        }
        playConfig.setHeaders(headers);
        Boolean enableAccurateSeek = (Boolean) config.get("enableAccurateSeek");
        if (null != enableAccurateSeek) {
            playConfig.setEnableAccurateSeek(enableAccurateSeek);
        }
        Boolean autoRotate = (Boolean) config.get("autoRotate");
        if (null != autoRotate) {
            playConfig.setAutoRotate(autoRotate);
        }
        Boolean smoothSwitchBitrate = (Boolean) config.get("smoothSwitchBitrate");
        if (null != smoothSwitchBitrate) {
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
        Float maxBufferSize = (Float) config.get("maxBufferSize");
        if (floatIsNotEmpty(maxBufferSize)) {
            playConfig.setMaxBufferSize(maxBufferSize);
        }
        Float maxPreloadSize = (Float) config.get("maxPreloadSize");
        if (floatIsNotEmpty(maxPreloadSize)) {
            playConfig.setMaxPreloadSize(maxPreloadSize);
        }
        Integer firstStartPlayBufferTime = (Integer) config.get("firstStartPlayBufferTime");
        if (null != firstStartPlayBufferTime) {
            playConfig.setFirstStartPlayBufferTime(firstStartPlayBufferTime);
        }
        Integer nextStartPlayBufferTime = (Integer) config.get("nextStartPlayBufferTime");
        if (null != nextStartPlayBufferTime) {
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
        if (null != enableRenderProcess) {
            playConfig.setEnableRenderProcess(enableRenderProcess);
        }
        String preferredResolutionStr = (String) config.get("preferredResolution");
        if (null != preferredResolutionStr) {
            long preferredResolution = Long.parseLong(preferredResolutionStr);
            playConfig.setPreferredResolution(preferredResolution);
        }

        return playConfig;
    }

    /**
     * Convert msg to config.
     *
     * msg转config
     */
    public static TXLivePlayConfig transformToLiveConfig(FTXLivePlayConfigPlayerMsg config) {
        TXLivePlayConfig livePlayConfig = new TXLivePlayConfig();
        if (null != config.getCacheTime()) {
            livePlayConfig.setCacheTime(config.getCacheTime().floatValue());
        }
        if (null != config.getMaxAutoAdjustCacheTime()) {
            livePlayConfig.setMaxAutoAdjustCacheTime(config.getMaxAutoAdjustCacheTime().floatValue());
        }
        if (null != config.getMinAutoAdjustCacheTime()) {
            livePlayConfig.setMinAutoAdjustCacheTime(config.getMinAutoAdjustCacheTime().floatValue());
        }
        if (null != config.getVideoBlockThreshold()) {
            livePlayConfig.setVideoBlockThreshold(config.getVideoBlockThreshold().intValue());
        }
        if (null != config.getConnectRetryCount()) {
            livePlayConfig.setConnectRetryCount(config.getConnectRetryCount().intValue());
        }
        if (null != config.getConnectRetryInterval()) {
            livePlayConfig.setConnectRetryInterval(config.getConnectRetryInterval().intValue());
        }
        if (null != config.getAutoAdjustCacheTime()) {
            livePlayConfig.setAutoAdjustCacheTime(config.getAutoAdjustCacheTime());
        }
        if (null != config.getEnableAec()) {
            livePlayConfig.setEnableAEC(config.getEnableAec());
        }
        if (null != config.getEnableMessage()) {
            livePlayConfig.setEnableMessage(config.getEnableMessage());
        }
        if (null != config.getEnableMetaData()) {
            livePlayConfig.setEnableMetaData(config.getEnableMetaData());
        }
        livePlayConfig.setFlvSessionKey(config.getFlvSessionKey());
        return livePlayConfig;
    }

    /**
     * Convert map to config.
     * 
     * map转config
     */
    public static TXLivePlayConfig transformToLiveConfig(Map<Object, Object> config) {
        TXLivePlayConfig livePlayConfig = new TXLivePlayConfig();
        Double cacheTime = (Double) config.get("cacheTime");
        if (doubleIsNotEmpty(cacheTime)) {
            livePlayConfig.setCacheTime(cacheTime.floatValue());
        }
        Double maxAutoAdjustCacheTime = (Double) config.get("maxAutoAdjustCacheTime");
        if (doubleIsNotEmpty(maxAutoAdjustCacheTime)) {
            livePlayConfig.setMaxAutoAdjustCacheTime(maxAutoAdjustCacheTime.floatValue());
        }
        Double minAutoAdjustCacheTime = (Double) config.get("minAutoAdjustCacheTime");
        if (doubleIsNotEmpty(minAutoAdjustCacheTime)) {
            livePlayConfig.setMinAutoAdjustCacheTime(minAutoAdjustCacheTime.floatValue());
        }
        Integer videoBlockThreshold = (Integer) config.get("videoBlockThreshold");
        if (intIsNotEmpty(videoBlockThreshold)) {
            livePlayConfig.setVideoBlockThreshold(videoBlockThreshold);
        }
        Integer connectRetryCount = (Integer) config.get("connectRetryCount");
        if (intIsNotEmpty(connectRetryCount)) {
            livePlayConfig.setConnectRetryCount(connectRetryCount);
        }
        Integer connectRetryInterval = (Integer) config.get("connectRetryInterval");
        if (intIsNotEmpty(connectRetryInterval)) {
            livePlayConfig.setConnectRetryInterval(connectRetryInterval);
        }
        Boolean autoAdjustCacheTime = (Boolean) config.get("autoAdjustCacheTime");
        if (null != autoAdjustCacheTime) {
            livePlayConfig.setAutoAdjustCacheTime(autoAdjustCacheTime);
        }
        Boolean enableAec = (Boolean) config.get("enableAec");
        if (null != enableAec) {
            livePlayConfig.setEnableAEC(enableAec);
        }
        Boolean enableMessage = (Boolean) config.get("enableMessage");
        if (null != enableMessage) {
            livePlayConfig.setEnableMessage(enableMessage);
        }
        Boolean enableMetaData = (Boolean) config.get("enableMetaData");
        if (null != enableMetaData) {
            livePlayConfig.setEnableMetaData(enableMetaData);
        }
        String flvSessionKey = (String) config.get("flvSessionKey");
        if (!TextUtils.isEmpty(flvSessionKey)) {
            livePlayConfig.setFlvSessionKey(flvSessionKey);
        }
        return livePlayConfig;
    }

    private static boolean intIsNotEmpty(Integer value) {
        return null != value && value > 0;
    }

    private static boolean floatIsNotEmpty(Float value) {
        return null != value && value > 0;
    }

    private static boolean doubleIsNotEmpty(Double value) {
        return null != value && value > 0;
    }
}
