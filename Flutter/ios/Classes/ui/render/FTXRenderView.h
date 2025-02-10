// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEW_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEW_H_

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "FTXLiteAVSDKHeader.h"
#import "FTXBasePlayer.h"
#import "FTXTextureView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXRenderView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
                    messenger:(id<FlutterBinaryMessenger>)binaryMessenger;

- (void)setPlayer:(nullable FTXBasePlayer*)player;

- (nonnull FTXTextureView*)getRenderView;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEW_H_
