// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEWFACTORY_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEWFACTORY_H_

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "FTXRenderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXRenderViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>) binaryMessenger;

- (FTXRenderView*)findViewById:(NSUInteger)viewId;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXRENDERVIEWFACTORY_H_
