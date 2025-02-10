// Copyright (c) 2022 Tencent. All rights reserved.

#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXBASEPLAYER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXBASEPLAYER_H_

#import <Foundation/Foundation.h>
#import "FTXRenderControl.h"

NS_ASSUME_NONNULL_BEGIN

@class FTXTextureView;

@interface FTXBasePlayer : NSObject

@property(atomic, readonly) NSNumber *playerId;
@property(nonatomic, strong, nullable) id<FTXRenderControl> renderControl;

- (void)setRenderView:(nullable FTXTextureView*)renderView;

- (void)destory;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXBASEPLAYER_H_
