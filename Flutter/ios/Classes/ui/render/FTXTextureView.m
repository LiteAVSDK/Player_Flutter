// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXTextureView.h"
#import "FTXImgTools.h"
#import "FTXRenderControl.h"
#import "FTXLog.h"

@interface FTXTextureView()

@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic, strong) FTXBasePlayer *curRenderPlayer;
@property (nonatomic, strong) CIContext *ciContext;

@end

@implementation FTXTextureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.videoLayer = [AVSampleBufferDisplayLayer layer];
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.videoLayer.backgroundColor = [UIColor blackColor].CGColor;
        [self.layer addSublayer:self.videoLayer];
        self.ciContext = [CIContext contextWithOptions:nil];
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

- (CMSampleBufferRef)createSampleBufferWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                           formatDesc:(CMVideoFormatDescriptionRef)formatDesc
                                               timing:(CMSampleTimingInfo)timing {
    CMSampleBufferRef sampleBuffer = NULL;
    OSStatus status;
    
    // 创建 CMSampleBuffer
    status = CMSampleBufferCreateForImageBuffer(
        NULL,
        pixelBuffer,
        YES,
        NULL,
        NULL,
        formatDesc,
        &timing,
        &sampleBuffer
    );
    
    if (status != noErr || !sampleBuffer) {
        NSLog(@"Failed to create CMSampleBuffer: %d", (int)status);
        return NULL;
    }
    
    // 关键设置：标记为未压缩数据
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    if (attachments) {
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    }
    
    return sampleBuffer;
}

- (void)renderFrameByPixel:(nonnull CVPixelBufferRef)pixelBuffer {
    @synchronized (self) {
        CVPixelBufferRetain(pixelBuffer);
        @try {
            // 创建 CMVideoFormatDescription
            CMVideoFormatDescriptionRef formatDesc = NULL;
            CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &formatDesc);
            
            // 封装为 CMSampleBuffer
            CMSampleTimingInfo timing = { CMTimeMake(1, 30), kCMTimeInvalid, kCMTimeInvalid };
            CMSampleBufferRef sampleBuffer = [self createSampleBufferWithPixelBuffer:pixelBuffer
                                                                          formatDesc:formatDesc
                                                                              timing:timing];
            
            // 提交到 AVSampleBufferDisplayLayer
            if (sampleBuffer && [self.videoLayer isReadyForMoreMediaData]) {
                [self.videoLayer enqueueSampleBuffer:sampleBuffer];
            }
            
            // 释放资源
            if (formatDesc) CFRelease(formatDesc);
            if (sampleBuffer) CFRelease(sampleBuffer);
        } @catch (NSException *exception) {
            FTXLOGE(@"renderFrameByPixel failed, error:%@", exception);
        } @finally {
            // do nothing
        }
    }
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
