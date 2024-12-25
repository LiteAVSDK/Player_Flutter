// Copyright (c) 2022 Tencent. All rights reserved.

#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_RENDER_FTXRENDERCONTROL_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_RENDER_FTXRENDERCONTROL_H_

#import <Foundation/Foundation.h>

@protocol FTXRenderControl <NSObject>

- (void)onRenderFrame:(CVPixelBufferRef)pixelBuffer;

- (void)clearLastImg;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_PLAYER_RENDER_FTXRENDERCONTROL_H_
