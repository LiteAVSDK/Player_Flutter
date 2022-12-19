// Copyright (c) 2022 Tencent. All rights reserved.

#import <TXLiteAVSDK_Professional/TXVodDownloadManager.h>
#import <Foundation/Foundation.h>
#import "FTXEvent.h"

@interface CommonUtil : NSObject

+(NSNumber*)getCacheVideoQuality:(int)width height:(int)pHeight;

+(NSNumber*)getDownloadEventByState:(int)downloadState;

@end
