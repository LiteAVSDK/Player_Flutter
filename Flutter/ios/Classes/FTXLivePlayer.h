// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXLIVEPLAYER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXLIVEPLAYER_H_

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@interface FTXLivePlayer : FTXBasePlayer

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

- (void)notifyAppTerminate:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXLIVEPLAYER_H_
