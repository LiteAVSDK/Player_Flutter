// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXTEXTUREVIEW_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXTEXTUREVIEW_H_

#import <Foundation/Foundation.h>
#import "FTXBasePlayer.h"
#import "FTXRenderControl.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXTextureView : UIView<FTXRenderControl>

- (void)bindPlayer:(nullable FTXBasePlayer*)player;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_UI_RENDER_FTXTEXTUREVIEW_H_
