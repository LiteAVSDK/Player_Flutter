// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_

#import <Foundation/Foundation.h>
#import "FtxMessages.h"
#import "IPlayersBridge.h"

@interface FTXLivePlayerDispatcher : NSObject<TXFlutterLivePlayerApi>

@property(atomic, strong) id<IPlayersBridge> bridge;

- (instancetype)initWithBridge:(id<IPlayersBridge>)dataBridge;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_MESSAGES_FTXLIVEPLAYERDISPATCHER_H_
