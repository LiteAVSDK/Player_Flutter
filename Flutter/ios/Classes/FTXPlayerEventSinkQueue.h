//
//  FTXPlayerEventSink.h
//  super_player
//
//  Created by Zhirui Ou on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXPlayerEventSinkQueue : NSObject

- (void)success:(NSObject *)event;
- (void)setDelegate:(_Nullable FlutterEventSink)sink;

- (void)error:(NSString *)code
      message:(NSString *_Nullable)message
      details:(id _Nullable)details;

@end

NS_ASSUME_NONNULL_END
