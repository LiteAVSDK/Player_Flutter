// Copyright (c) 2022 Tencent. All rights reserved.

#import "TXCommonUtil.h"
#import <Flutter/Flutter.h>

@implementation TXCommonUtil

+ (NSNumber*)getDownloadEventByState:(int)downloadState{
    int result;
    switch (downloadState) {
        case TXVodDownloadMediaInfoStateInit:
            result = EVENT_DOWNLOAD_START;
            break;
        case TXVodDownloadMediaInfoStateStart:
            result = EVENT_DOWNLOAD_PROGRESS;
            break;
        case TXVodDownloadMediaInfoStateStop:
            result = EVENT_DOWNLOAD_STOP;
            break;
        case TXVodDownloadMediaInfoStateError:
            result = EVENT_DOWNLOAD_ERROR;
            break;
        case TXVodDownloadMediaInfoStateFinish:
            result = EVENT_DOWNLOAD_FINISH;
            break;
        default:
            result = EVENT_DOWNLOAD_ERROR;
            break;
    }
    return [NSNumber numberWithInt:result];;
}

+(PlayerMsg*)playerMsgWith:(NSNumber*)playerId {
    PlayerMsg* msg = [[PlayerMsg alloc] init];
    msg.playerId = playerId;
    return msg;
}

+(StringMsg*)stringMsgWith:(NSString*)str {
    StringMsg *msg = [[StringMsg alloc] init];
    msg.value = str;
    return msg;
}

+(DoubleMsg*)doubleMsgWith:(double)value {
    DoubleMsg *msg = [[DoubleMsg alloc] init];
    msg.value = @(value);
    return msg;
}

+(BoolMsg *)boolMsgWith:(bool)value {
    BoolMsg *msg = [[BoolMsg alloc] init];
    msg.value = @(value);
    return msg;
}

+ (IntMsg *)intMsgWith:(NSNumber *)value {
    IntMsg *msg = [[IntMsg alloc] init];
    msg.value = value;
    return msg;
}

+ (UInt8ListMsg *)uInt8MsgWith:(NSData *)value {
    UInt8ListMsg *msg = [[UInt8ListMsg alloc] init];
    if(nil != value) {
        msg.value = [FlutterStandardTypedData typedDataWithBytes:value];
    }
    return msg;
}

+ (ListMsg *)listMsgWith:(NSArray *)value {
    ListMsg *msg = [[ListMsg alloc] init];
    msg.value = value;
    return msg;
}

@end
