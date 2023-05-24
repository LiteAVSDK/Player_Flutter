// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXVODPLAYER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXVODPLAYER_H_

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@protocol FTXVodPlayerDelegate <NSObject>

- (void)onPlayerPipRequestStart;

- (void)onPlayerPipStateDidStart;

- (void)onPlayerPipStateWillStop;

- (void)onPlayerPipStateDidStop;

- (void)onPlayerPipStateRestoreUI:(double)playTime;;

- (void)onPlayerPipStateError:(NSInteger)errorId;

@end

@interface FTXVodPlayer : FTXBasePlayer

@property(nonatomic, weak) id<FTXVodPlayerDelegate> delegate;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

- (void)notifyAppTerminate:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXVODPLAYER_H_
