// Copyright (c) 2024 Tencent. All rights reserved.

#import "FTXPipRenderView.h"
#import "FTXImgTools.h"

@interface FTXPipRenderView()

@property (nonatomic, strong) CALayer *videoLayer;

@end

@implementation FTXPipRenderView

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

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [FTXImgTools ciImageFromPixelBuffer:pixelBuffer];
    
    // 创建一个CIContext
    CIContext *context = [CIContext contextWithOptions:nil];
    
    // 将CIImage渲染到CGImage
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    
    // 更新CALayer的内容
    self.videoLayer.contents = (__bridge id _Nullable)(cgImage);
    
    // 释放CGImage
    CGImageRelease(cgImage);
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

@end
