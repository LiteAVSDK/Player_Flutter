// Copyright (c) 2022 Tencent. All rights reserved.

#import <TXLiteAVSDK_Professional/TXVodDownloadManager.h>
#import <Foundation/Foundation.h>
#import "FTXEvent.h"
#import "FtxMessages.h"

@interface TXCommonUtil : NSObject

+(NSNumber*)getDownloadEventByState:(int)downloadState;

+(PlayerMsg*)playerMsgWith:(NSNumber*)playerId;

+(StringMsg*)stringMsgWith:(NSString*)str;

+(DoubleMsg*)doubleMsgWith:(double)value;

+(BoolMsg*)boolMsgWith:(bool)value;

+(IntMsg*)intMsgWith:(NSNumber*)value;

+(UInt8ListMsg*)uInt8MsgWith:(NSData*)value;

+(ListMsg*)listMsgWith:(NSArray*)value;

@end
