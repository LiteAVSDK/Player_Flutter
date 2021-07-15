//
//  SuperPlatformPlayerViewFactory.h
//  super_player
//
//  Created by Zhirui Ou on 2021/3/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SuperPlatformPlayerViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
