// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXPLAYEREVENTSINKQUEUE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXPLAYEREVENTSINKQUEUE_H_

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXPlayerEventSinkQueue : NSObject

- (void)success:(id)event;
- (void)setDelegate:(_Nullable FlutterEventSink)sink;

- (void)error:(NSString *)code
      message:(NSString *_Nullable)message
      details:(id _Nullable)details;

@end

NS_ASSUME_NONNULL_END
#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_FTXPLAYEREVENTSINKQUEUE_H_
