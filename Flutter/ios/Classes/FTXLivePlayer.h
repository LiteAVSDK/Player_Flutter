//
//  FTXLivePlayer.h
//  super_player
//
//  Created by Zhirui Ou on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@interface FTXLivePlayer : FTXBasePlayer

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
