// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXV2LIVETOOLS_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXV2LIVETOOLS_H_

#import <Foundation/Foundation.h>
#import "FTXLiteAVSDKHeader.h"

@interface FTXV2LiveTools : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (V2TXLiveRotation)transRotationFromDegree:(int)rotation;

+ (NSDictionary*)buildNetBundle:(V2TXLivePlayerStatistics *)statistics;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXV2LIVETOOLS_H_
