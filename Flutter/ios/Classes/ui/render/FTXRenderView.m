// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXRenderView.h"

@interface FTXRenderView()

@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) FTXBasePlayer* mBasePlayer;

@end

@implementation FTXRenderView

- (nonnull instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args messenger:(nonnull id<FlutterBinaryMessenger>)binaryMessenger {
    self = [super init];
    if (self) {
        self.videoView = [[UIView alloc] initWithFrame:frame];
        self.mBasePlayer = nil;
    }
    return self;
}

- (nonnull UIView *)view {
    return self.videoView;
}

- (void)setPlayer:(FTXBasePlayer *)player {
    if (self.mBasePlayer != player) {
        if (nil != self.mBasePlayer) {
            [self.mBasePlayer setRenderView:nil];
        }
        [self.videoView setHidden:NO];
        self.mBasePlayer = player;
        [player setRenderView:self.videoView];
    } else {
        [player setRenderView:self.videoView];
    }
}

@end
