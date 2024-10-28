// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCALLER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCALLER_H_

#import "FTXLiteAVSDKHeader.h"
#import "FTXLivePipDelegate.h"
#import "FTXPipPlayerDelegate.h"
#import "FTXPipRenderView.h"

@protocol FTXPipCaller <NSObject>

@property(nonatomic, strong)id<FTXLivePipDelegate> pipDelegate;
@property(nonatomic, strong)id<FTXPipPlayerDelegate> playerDelegate;

- (int)handleStartPip:(CGSize)size;

- (void)exitPip;

- (FTXPipRenderView*)getVideoView;

- (TX_VOD_PLAYER_PIP_STATE)getStatus;

- (void)pausePipVideo;

- (void)resumePipVideo;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPCALLER_H_
