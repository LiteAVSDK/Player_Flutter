// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_SUPERPLAYERPLUGIN_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_SUPERPLAYERPLUGIN_H_

#import <Flutter/Flutter.h>
#import "TXCommonUtil.h"

@interface SuperPlayerPlugin : NSObject<FlutterPlugin>

-(void) releaseAllPlayer;

-(void) destroy;

/// Forwards the process-level License-loaded event into this engine's Dart side.
/// Invoked by VodGlobalResource when fanning out onLicenceLoaded across attached plugins.
- (void)dispatchLicenceLoaded:(int)result reason:(NSString *)reason;

/// Forwards the process-level orientation change into this engine's Dart side.
/// Invoked by VodGlobalResource when fanning out orientation change across attached plugins.
- (void)dispatchOrientationChanged:(int)orientation;

@end
#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_SUPERPLAYERPLUGIN_H_
