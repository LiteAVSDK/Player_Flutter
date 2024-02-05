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

@end


