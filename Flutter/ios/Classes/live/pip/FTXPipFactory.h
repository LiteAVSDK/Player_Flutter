// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPFACTORY_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPFACTORY_H_

#import <Foundation/Foundation.h>
#import "FTXPipCaller.h"

NS_ASSUME_NONNULL_BEGIN

@interface FTXPipFactory : NSObject


- (id<FTXPipCaller>)createPipCaller;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPFACTORY_H_
