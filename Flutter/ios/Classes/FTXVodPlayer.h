// Copyright (c) 2022 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@protocol FTXVodPlayerDelegate <NSObject>

- (void)onPlayerPipRequestStart;

- (void)onPlayerPipStateDidStart;

- (void)onPlayerPipStateWillStop;

- (void)onPlayerPipStateDidStop;

- (void)onPlayerPipStateRestoreUI;

- (void)onPlayerPipStateError:(NSInteger)errorId;

@end

@interface FTXVodPlayer : FTXBasePlayer

@property (nonatomic, weak) id<FTXVodPlayerDelegate> delegate;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
