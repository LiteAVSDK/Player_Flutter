// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXRenderViewFactory.h"

@interface FTXRenderViewFactory()

@property(nonatomic, strong) id<FlutterBinaryMessenger> binaryMessenger;
@property(nonatomic, strong) NSMapTable<NSNumber*, FTXRenderView*>* viewToPlatformViewMap;

@end

@implementation FTXRenderViewFactory

- (nonnull instancetype)initWithBinaryMessenger:(nonnull id<FlutterBinaryMessenger>)binaryMessenger {
    self = [super init];
    if (self) {
        self.viewToPlatformViewMap = [NSMapTable weakToWeakObjectsMapTable];
        self.binaryMessenger = binaryMessenger;
    }
    return self;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args { 
    FTXRenderView *renderView = [[FTXRenderView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args messenger:self.binaryMessenger];
    [self.viewToPlatformViewMap setObject:renderView forKey:@(viewId)];
    return renderView;
}

- (nonnull FTXRenderView *)findViewById:(NSUInteger)viewId {
    return [self.viewToPlatformViewMap objectForKey:@(viewId)];
}

@end
