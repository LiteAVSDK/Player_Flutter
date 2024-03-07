// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_

#import <Foundation/Foundation.h>
#import "FtxMessages.h"
#import "ITXPlayersBridge.h"

@interface FTXLivePlayerDispatcher : NSObject<TXFlutterLivePlayerApi>

@property(atomic, strong) id<ITXPlayersBridge> bridge;

- (instancetype)initWithBridge:(id<ITXPlayersBridge>)dataBridge;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_
