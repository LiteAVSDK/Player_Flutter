// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.text.TextUtils;

import com.tencent.liteav.txcplayer.model.TXSubtitleRenderModel;
import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXVodPlayConfig;

import com.tencent.vod.flutter.messages.FtxMessages;
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
        if (null != configPlayerMsg.getConnectRetryInterval()) {
            playConfig.setConnectRetryInterval(configPlayerMsg.getConnectRetryInterval().intValue());
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
        playConfig.setPreferredAudioTrack(configPlayerMsg.getPreferAudioTrack());
        playConfig.setMediaType(configPlayerMsg.getMediaType().intValue());
        playConfig.setEncryptedMp4Level(configPlayerMsg.getEncryptedMp4Level().intValue());
        return playConfig;
    }

    public static TXSubtitleRenderModel transToTitleRenderModel(FtxMessages.SubTitleRenderModelPlayerMsg msg) {
        TXSubtitleRenderModel renderModel = new TXSubtitleRenderModel();
        if (null != msg.getCanvasWidth()) {
            renderModel.canvasWidth = msg.getCanvasWidth().intValue();
        }
        if (null != msg.getCanvasHeight()) {
            renderModel.canvasHeight = msg.getCanvasHeight().intValue();
        }
        renderModel.familyName = msg.getFamilyName();
        if (null != msg.getFontSize()) {
            renderModel.fontSize = msg.getFontSize().floatValue();
        }
        if (null != msg.getFontScale()) {
            renderModel.fontScale = msg.getFontScale().floatValue();
        }
        if (null != msg.getFontColor()) {
            renderModel.fontColor = msg.getFontColor().intValue();
        }
        if (null != msg.getIsBondFontStyle()) {
            renderModel.isBondFontStyle = msg.getIsBondFontStyle();
        }
        if (null != msg.getOutlineWidth()) {
            renderModel.outlineWidth = msg.getOutlineWidth().floatValue();
        }
        if (null != msg.getOutlineColor()) {
            renderModel.outlineColor = msg.getOutlineColor().intValue();
        }
        if (null != msg.getLineSpace()) {
            renderModel.lineSpace = msg.getLineSpace().floatValue();
        }
        if (null != msg.getStartMargin()) {
            renderModel.startMargin = msg.getStartMargin().floatValue();
        }
        if (null != msg.getEndMargin()) {
            renderModel.endMargin = msg.getEndMargin().floatValue();
        }
        if (null != msg.getVerticalMargin()) {
            renderModel.verticalMargin = msg.getVerticalMargin().floatValue();
        }
        return renderModel;
    }

}
