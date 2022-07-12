// Copyright (c) 2022 Tencent. All rights reserved.

#import <TXLiteAVSDK_Player/TXVodDownloadManager.h>
#import <Foundation/Foundation.h>
#import "FTXEvent.h"

@interface CommonUtil : NSObject
    
+(int)getCacheVideoQuality:(int)width height:(int)pHeight;

+(int)getDownloadEventByState:(int)downloadState;
    
@end
