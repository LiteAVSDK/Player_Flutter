// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXTextureView.h"
#import "FTXImgTools.h"
#import "FTXRenderControl.h"
#import "FTXLog.h"

@interface FTXTextureView()

@property (nonatomic, strong) FTXBasePlayer *curRenderPlayer;

@end

@implementation FTXTextureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // do nothing
    }
    return self;
}

- (void)bindPlayer:(FTXBasePlayer *)player {
    if (self.curRenderPlayer != player) {
        if (self.curRenderPlayer != nil && self.curRenderPlayer.renderControl == self) {
            self.curRenderPlayer.renderControl = nil;
        }
        self.curRenderPlayer = player;
        player.renderControl = self;
    } else {
        FTXLOGW(@"bindPlayer met same player");
        self.curRenderPlayer = player;
        player.renderControl = self;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // do nothing
}

- (void)dealloc
{
    FTXLOGW(@"texture view is dealloc");
}

@end
