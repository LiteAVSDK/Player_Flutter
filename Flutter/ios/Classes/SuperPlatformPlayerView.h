//
//  SuperPlatformView.h
//  Pods
//
//  Created by Zhirui Ou on 2021/3/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SuperPlatformPlayerView : NSObject<FlutterPlatformView>

+ (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args registrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
