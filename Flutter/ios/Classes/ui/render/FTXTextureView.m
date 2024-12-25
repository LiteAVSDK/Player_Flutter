// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXTextureView.h"
#import "FTXImgTools.h"
#import "FTXRenderControl.h"
#import "FTXLog.h"

@interface FTXTextureView()

@property (nonatomic, strong) CALayer *videoLayer;
@property (nonatomic, strong) FTXBasePlayer *curRenderPlayer;

@end

@implementation FTXTextureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.videoLayer = [CALayer layer];
        self.videoLayer.frame = self.bounds;
        [self.layer addSublayer:self.videoLayer];
    }
    return self;
}

- (void)clearLastImg {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新CALayer的内容
        self.videoLayer.contents = nil;
    });
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

- (void)renderFrameByPixel:(nonnull CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [FTXImgTools ciImageFromPixelBuffer:pixelBuffer];
    
    // 创建一个CIContext
    CIContext *context = [CIContext contextWithOptions:nil];
    
    // 将CIImage渲染到CGImage
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    
    // 在主线程中更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新CALayer的内容
        self.videoLayer.contents = (__bridge id _Nullable)(cgImage);
        
        // 释放CGImage
        CGImageRelease(cgImage);
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize oldSize = self.videoLayer.frame.size;
    CGRect newRect = self.frame;
    CGSize newSize = newRect.size;
    if (oldSize.width != newSize.width || oldSize.height != newSize.height) {
        self.videoLayer.frame = newRect;
    }
}

- (void)onRenderFrame:(CVPixelBufferRef)pixelBuffer {
    [self renderFrameByPixel:pixelBuffer];
}

@end
