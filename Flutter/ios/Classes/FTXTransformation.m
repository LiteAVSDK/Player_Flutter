// Copyright (c) 2022 Tencent. All rights reserved.
#import <Foundation/Foundation.h>
#import "FTXTransformation.h"

@implementation FTXTransformation

+ (TXVodPlayConfig *)transformToVodConfig:(NSDictionary *)args
{
    TXVodPlayConfig *playConfig = [[TXVodPlayConfig alloc] init];
    playConfig.connectRetryCount = [args[@"config"][@"connectRetryCount"] intValue];
    playConfig.connectRetryInterval = [args[@"config"][@"connectRetryInterval"] intValue];
    playConfig.timeout = [args[@"config"][@"timeout"] intValue];
    playConfig.playerType = [args[@"config"][@"playerType"] intValue];
    playConfig.connectRetryInterval = [args[@"config"][@"connectRetryInterval"] intValue];
    playConfig.enableAccurateSeek = [args[@"config"][@"enableAccurateSeek"] boolValue];
    playConfig.autoRotate = [args[@"config"][@"autoRotate"] boolValue];
    playConfig.smoothSwitchBitrate = [args[@"config"][@"smoothSwitchBitrate"] boolValue];
    playConfig.progressInterval = [args[@"config"][@"progressInterval"] intValue];
    playConfig.maxBufferSize = [args[@"config"][@"maxBufferSize"] intValue];
    playConfig.maxPreloadSize = [args[@"config"][@"maxPreloadSize"] intValue];
    playConfig.firstStartPlayBufferTime = [args[@"config"][@"firstStartPlayBufferTime"] intValue];
    playConfig.nextStartPlayBufferTime = [args[@"config"][@"nextStartPlayBufferTime"] intValue];
    playConfig.enableRenderProcess = [args[@"config"][@"enableRenderProcess"] boolValue];
    
    NSString *preferredResolutionStr = args[@"config"][@"preferredResolution"];
    playConfig.preferredResolution = [preferredResolutionStr longLongValue];
    
    NSString *overlayKey =  args[@"config"][@"overlayKey"];
    if(overlayKey != nil && overlayKey.length > 0) {
        playConfig.overlayKey = overlayKey;
    }
    
    NSString *overlayIv =  args[@"config"][@"overlayIv"];
    if(overlayIv != nil && overlayIv.length > 0) {
        playConfig.overlayIv = overlayIv;
    }
    
    NSDictionary *headers = args[@"config"][@"headers"];
    if(headers != nil) {
        playConfig.headers = headers;
    }
    
    NSDictionary *extInfoMap = args[@"config"][@"extInfoMap"];
    if(headers != nil) {
        playConfig.extInfoMap = extInfoMap;
    }

    return playConfig;
}

+ (TXLivePlayConfig *)transformToLiveConfig:(NSDictionary *)args
{
    TXLivePlayConfig *playConfig = [[TXLivePlayConfig alloc] init];

    playConfig.cacheTime = [args[@"config"][@"cacheTime"] floatValue];
    playConfig.maxAutoAdjustCacheTime = [args[@"config"][@"maxAutoAdjustCacheTime"] floatValue];
    playConfig.minAutoAdjustCacheTime = [args[@"config"][@"minAutoAdjustCacheTime"] floatValue];
    playConfig.videoBlockThreshold = [args[@"config"][@"videoBlockThreshold"] intValue];
    playConfig.connectRetryCount = [args[@"config"][@"connectRetryCount"] intValue];
    playConfig.connectRetryInterval = [args[@"config"][@"connectRetryInterval"] intValue];
    playConfig.bAutoAdjustCacheTime = [args[@"config"][@"autoAdjustCacheTime"] boolValue];
    playConfig.enableAEC = [args[@"config"][@"enableAec"] boolValue];
    playConfig.enableMessage = [args[@"config"][@"enableMessage"] intValue];
    playConfig.enableMetaData = [args[@"config"][@"enableMetaData"] intValue];
    NSString *flvSessionKey = args[@"config"][@"flvSessionKey"];

    if(flvSessionKey != nil && flvSessionKey.length > 0) {
        playConfig.flvSessionKey = flvSessionKey;
    }

    return playConfig;
}

@end


