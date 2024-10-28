// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPIPAUTH_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPIPAUTH_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TXPipAuth : NSObject

+ (instancetype)shareInstance;

+ (BOOL)cpa;

@end

NS_ASSUME_NONNULL_END

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPIPAUTH_H_
