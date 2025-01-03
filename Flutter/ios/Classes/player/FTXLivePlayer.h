// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXLIVEPLAYER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXLIVEPLAYER_H_

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"
#import "FTXVodPlayerDelegate.h"
#import "FTXRenderViewFactory.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@interface FTXLivePlayer : FTXBasePlayer

@property(nonatomic, weak) id<FTXVodPlayerDelegate> delegate;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
                renderViewFactory:(FTXRenderViewFactory*)renderViewFactory
                        onlyAudio:(BOOL)onlyAudio;

- (void)notifyAppTerminate:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_FTXLIVEPLAYER_H_
