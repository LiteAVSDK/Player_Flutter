// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXV2LiveTools.h"
#import "FTXEvent.h"

@implementation FTXV2LiveTools

+ (V2TXLiveRotation)transRotationFromDegree:(int)rotation {
    V2TXLiveRotation rotationCode = V2TXLiveRotation270;
    if (rotation <= 0) {
        rotationCode = V2TXLiveRotation0;
    } else if (rotation <= 90) {
        rotationCode = V2TXLiveRotation90;
    } else if (rotation <= 180) {
        rotationCode = V2TXLiveRotation180;
    } else {
        rotationCode = V2TXLiveRotation270;
    }
    return rotationCode;
}

+ (NSDictionary *)buildNetBundle:(V2TXLivePlayerStatistics *)statistics {
    NSMutableDictionary *dic = @{}.mutableCopy;
    [dic setValue:@(statistics.appCpu) forKey:NET_STATUS_CPU_USAGE];
    [dic setValue:@(statistics.width) forKey:NET_STATUS_VIDEO_WIDTH];
    [dic setValue:@(statistics.height) forKey:NET_STATUS_VIDEO_HEIGHT];
    [dic setValue:@(statistics.netSpeed) forKey:NET_STATUS_NET_SPEED];
    [dic setValue:@(statistics.fps) forKey:NET_STATUS_VIDEO_FPS];
    [dic setValue:@(statistics.videoBitrate) forKey:NET_STATUS_VIDEO_BITRATE];
    [dic setValue:@(statistics.audioBitrate) forKey:NET_STATUS_AUDIO_BITRATE];
    [dic setValue:@(statistics.jitterBufferDelay) forKey:NET_STATUS_NET_JITTER];
    [dic setValue:@(statistics.systemCpu) forKey:NET_STATUS_SYSTEM_CPU];
    [dic setValue:@(statistics.videoPacketLoss) forKey:NET_STATUS_VIDEO_LOSS];
    [dic setValue:@(statistics.audioPacketLoss) forKey:NET_STATUS_AUDIO_LOSS];
    [dic setValue:@(statistics.audioTotalBlockTime) forKey:NET_STATUS_AUDIO_TOTAL_BLOCK_TIME];
    [dic setValue:@(statistics.videoTotalBlockTime) forKey:NET_STATUS_VIDEO_TOTAL_BLOCK_TIME];
    [dic setValue:@(statistics.videoBlockRate) forKey:NET_STATUS_VIDEO_BLOCK_RATE];
    [dic setValue:@(statistics.audioBlockRate) forKey:NET_STATUS_AUDIO_BLOCK_RATE];
    [dic setValue:@(statistics.rtt) forKey:NET_STATUS_RTT];
    return dic;;
}

@end
