// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPRENDERVIEW_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPRENDERVIEW_H_

#import <Foundation/Foundation.h>
#import "FTXBackPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXPipRenderView : UIView

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPRENDERVIEW_H_
