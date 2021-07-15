//
//  SuperPlatformPlayerViewFactory.m
//  super_player
//
//  Created by Zhirui Ou on 2021/3/10.
//

#import "SuperPlatformPlayerViewFactory.h"
#import "SuperPlatformPlayerView.h"

@interface SuperPlatformPlayerViewFactory ()

@property (nonatomic, strong) id<FlutterPluginRegistrar> registrar;

@end

@implementation SuperPlatformPlayerViewFactory

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        _registrar = registrar;
    }
    
    return self;
}

#pragma mark - FlutterPlatformViewFactory

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args
{
    return [SuperPlatformPlayerView createWithFrame:frame viewIdentifier:viewId arguments:args registrar:self.registrar];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec
{
    return FlutterStandardMessageCodec.sharedInstance;
}

@end
