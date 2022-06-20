// Copyright (c) 2022 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@interface FTXLivePlayer : FTXBasePlayer

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
