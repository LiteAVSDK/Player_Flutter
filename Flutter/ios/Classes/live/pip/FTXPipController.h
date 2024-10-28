// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCONTROLLER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCONTROLLER_H_

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FTXLiteAVSDKHeader.h"
#import "FTXLivePipDelegate.h"
#import "FTXPipPlayerDelegate.h"

@interface FTXPipController : NSObject

@property(nonatomic, strong)id<FTXLivePipDelegate> pipDelegate;
@property(nonatomic, strong)id<FTXPipPlayerDelegate> playerDelegate;

+ (instancetype)shareInstance;

- (int)startOpenPip:(V2TXLivePlayer*)livePlayer withSize:(CGSize)size;

- (void)pausePipVideo;

- (void)resumePipVideo;

- (void)exitPip;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCONTROLLER_H_
