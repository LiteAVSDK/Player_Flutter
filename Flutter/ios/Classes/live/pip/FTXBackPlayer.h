// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXBACKPLAYER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXBACKPLAYER_H_

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import "FTXPipPlayerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXBackPlayer : NSObject

@property(nonatomic, strong)id<FTXPipPlayerDelegate> playerDelegate;

- (void)prepareVideo:(AVPlayerItem *)item;

- (void)replaceCurrentItemWithPlayerItem:(AVPlayerItem *)item;

- (void)play;

- (void)setContainerView:(UIView*)container;

- (void)setLoopback:(BOOL)isLoop;

- (void)seekTo:(int64_t)positionMs;

- (void)stop;

- (void)pause;

- (AVPlayerLayer*)getPlayerLayer;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXBACKPLAYER_H_
