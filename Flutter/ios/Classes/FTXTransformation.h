// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>

static NSString* cacheFolder = nil;
static int maxCacheItems = -1;
@interface FTXTransformation : NSObject

+ (TXVodPlayConfig *)transformToVodConfig:(NSDictionary*)map;

+ (TXLivePlayConfig *)transformToLiveConfig:(NSDictionary*)map;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXTRANSFORMATION_H_
