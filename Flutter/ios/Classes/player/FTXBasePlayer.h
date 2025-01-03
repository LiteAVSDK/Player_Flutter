// Copyright (c) 2022 Tencent. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXBasePlayer : NSObject

@property(atomic, readonly) NSNumber *playerId;

- (void)setRenderView:(nullable UIView*)renderView;

- (void)destory;

@end

NS_ASSUME_NONNULL_END
