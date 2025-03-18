// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXRenderView.h"
#import "FTXLog.h"

@interface FTXRenderView()

@property (nonatomic, strong) FTXTextureView *videoView;
@property (nonatomic, strong) FTXBasePlayer* mBasePlayer;
@property (nonatomic, assign) int64_t mViewId;

@end

@implementation FTXRenderView

- (nonnull instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args messenger:(nonnull id<FlutterBinaryMessenger>)binaryMessenger {
    self = [super init];
    if (self) {
        self.mViewId = viewId;
        self.videoView = [[FTXTextureView alloc] initWithFrame:frame];
        self.mBasePlayer = nil;
    }
    return self;
}

- (FTXTextureView *)getRenderView {
    return self.videoView;
}

- (nonnull UIView *)view {
    return self.videoView;
}

- (void)setPlayer:(FTXBasePlayer *)player {
    if (self.mBasePlayer != player) {
        if (nil != self.mBasePlayer) {
            [self.mBasePlayer setRenderView:nil];
            [self.videoView bindPlayer:nil];
        }
        self.mBasePlayer = player;
        [player setRenderView:self.videoView];
    } else {
        [player setRenderView:self.videoView];
    }
}

- (void)dealloc
{
    FTXLOGW(@"render view is dealloc, id:%lld", self.mViewId);
}

@end
