// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXIMGTOOLS_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXIMGTOOLS_H_

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXImgTools : NSObject

+ (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img;

+ (CIImage *)ciImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

+ (CMSampleBufferRef)createBlankSampleBufferWithWidth:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXIMGTOOLS_H_
