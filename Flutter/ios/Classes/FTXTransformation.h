// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>

@class FTXVodPlayConfigPlayerMsg;
@class FTXLivePlayConfigPlayerMsg;

static NSString* cacheFolder = nil;
static int maxCacheItems = -1;
@interface FTXTransformation : NSObject

+ (TXVodPlayConfig *)transformMsgToVodConfig:(FTXVodPlayConfigPlayerMsg*)msg;

+ (TXLivePlayConfig *)transformMsgToLiveConfig:(FTXLivePlayConfigPlayerMsg *)msg;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_
