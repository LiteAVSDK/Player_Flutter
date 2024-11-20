// Copyright (c) 2022 Tencent. All rights reserved.
#import <Foundation/Foundation.h>
#import "FTXTransformation.h"
#import "FtxMessages.h"

@implementation FTXTransformation

+ (TXVodPlayConfig *)transformMsgToVodConfig:(FTXVodPlayConfigPlayerMsg*)msg {
    TXVodPlayConfig *config = [[TXVodPlayConfig alloc] init];
    config.connectRetryCount = msg.connectRetryCount.intValue;
    config.connectRetryInterval = msg.connectRetryInterval.intValue;
    config.timeout = msg.timeout.intValue;
    config.playerType = msg.playerType.intValue;
    config.enableAccurateSeek = msg.enableAccurateSeek.boolValue;
    config.autoRotate = msg.autoRotate.boolValue;
    config.smoothSwitchBitrate = msg.smoothSwitchBitrate.boolValue;
    config.maxBufferSize = msg.maxBufferSize.floatValue;
    config.maxPreloadSize = msg.maxPreloadSize.floatValue;
    config.firstStartPlayBufferTime = msg.firstStartPlayBufferTime.intValue;
    config.nextStartPlayBufferTime = msg.nextStartPlayBufferTime.intValue;
    config.enableRenderProcess = msg.enableRenderProcess.boolValue;
    config.preferredResolution = msg.preferredResolution.longValue;
    config.mediaType = msg.mediaType.intValue;
    config.encryptedMp4Level = msg.encryptedMp4Level.intValue;
    NSTimeInterval progressInerval = msg.progressInterval.intValue / 1000.0;
    if(progressInerval > 0) {
        config.progressInterval = progressInerval;
    }
    config.overlayKey = msg.overlayKey;
    config.overlayIv = msg.overlayIv;
    config.headers = msg.headers;
    config.extInfoMap = msg.extInfoMap;
    return config;
}

+ (TXLivePlayConfig *)transformMsgToLiveConfig:(FTXLivePlayConfigPlayerMsg *)msg {
    TXLivePlayConfig *config = [[TXLivePlayConfig alloc] init];
    config.cacheTime = msg.cacheTime.floatValue;
    config.maxAutoAdjustCacheTime = msg.maxAutoAdjustCacheTime.floatValue;
    config.minAutoAdjustCacheTime = msg.minAutoAdjustCacheTime.floatValue;
    config.videoBlockThreshold = msg.videoBlockThreshold.intValue;
    config.connectRetryCount = msg.connectRetryCount.intValue;
    config.connectRetryInterval = msg.connectRetryInterval.intValue;
    config.bAutoAdjustCacheTime = msg.autoAdjustCacheTime.boolValue;
    config.enableAEC = msg.enableAec.boolValue;
    config.enableMessage = msg.enableMessage.boolValue;
    config.enableMetaData = msg.enableMetaData.boolValue;
    config.flvSessionKey = msg.flvSessionKey;
    return config;
}

+ (TXPlayerSubtitleRenderModel *)transformToTitleRenderModel:(SubTitleRenderModelPlayerMsg *)msg {
    TXPlayerSubtitleRenderModel *model = [[TXPlayerSubtitleRenderModel alloc] init];
    if (msg.canvasWidth) {
        model.canvasWidth = msg.canvasWidth.intValue;
    }
    if (msg.canvasHeight) {
        model.canvasHeight = msg.canvasHeight.intValue;
    }
    model.familyName = msg.familyName;
    if (msg.fontSize) {
        model.fontSize = msg.fontSize.floatValue;
    }
    if (msg.fontScale) {
        model.fontScale = msg.fontScale.floatValue;
    }
    if (msg.fontColor) {
        model.fontColor = msg.fontColor.intValue;
    }
    if (msg.isBondFontStyle) {
        model.isBondFontStyle = msg.isBondFontStyle.boolValue;
    }
    if (msg.outlineWidth) {
        model.outlineWidth = msg.outlineWidth.floatValue;
    }
    if (msg.outlineColor) {
        model.outlineColor = msg.outlineColor.intValue;
    }
    if (msg.lineSpace) {
        model.lineSpace = msg.lineSpace.floatValue;
    }
    if (msg.startMargin) {
        model.startMargin = msg.startMargin.floatValue;
    }
    if (msg.endMargin) {
        model.endMargin = msg.endMargin.floatValue;
    }
    if (msg.verticalMargin) {
        model.verticalMargin = msg.verticalMargin.floatValue;
    }
    return model;
}

@end


