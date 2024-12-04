// Copyright (c) 2022 Tencent. All rights reserved.

#import "TXCommonUtil.h"
#import <Flutter/Flutter.h>
#include "FTXLiteAVSDKHeader.h"

#if __has_include(<TXLiteAVSDK_Player/TXVodDownloadManager.h>)
#import <TXLiteAVSDK_Player/TXVodDownloadManager.h>
#elif __has_include(<TXLiteAVSDK_Player_Premium/TXVodDownloadManager.h>)
#import <TXLiteAVSDK_Player_Premium/TXVodDownloadManager.h>
#elif __has_include(<TXLiteAVSDK_Professional/TXVodDownloadManager.h>)
#import <TXLiteAVSDK_Professional/TXVodDownloadManager.h>
#else
#import <TXVodDownloadManager.h>
#endif


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

+ (NSMutableDictionary *)getParamsWithEvent:(int)EvtID withParams:(NSDictionary *)params
{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtID) forKey:EVT_KEY_PLAYER_EVENT];
    if (params != nil && params.count != 0) {
        // Iterate over each key-value pair in the original dictionary
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            // Check if the value is NSNull
            if (![value isKindOfClass:[NSNull class]] && value != nil) {
                // If it is not NSNull, then add it to the new dictionary
                [dict setObject:value forKey:key];
            }
        }];
    }
    return dict;
}

@end
