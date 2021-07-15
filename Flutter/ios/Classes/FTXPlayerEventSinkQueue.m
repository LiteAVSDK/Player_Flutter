//
//  FTXPlayerEventSink.m
//  super_player
//
//  Created by Zhirui Ou on 2021/3/16.
//

#import "FTXPlayerEventSinkQueue.h"

@interface FTXPlayerEventSinkQueue ()

@property (nonatomic, strong) NSMutableArray *eventQueue;
@property (nonatomic, copy) FlutterEventSink eventSink;


@end

@implementation FTXPlayerEventSinkQueue

#pragma mark - public

- (void)success:(NSObject *)event
{
    [self enqueue:event];
    [self flushIfNeed];
}

- (void)setDelegate:(nullable FlutterEventSink)sink
{
    self.eventSink = sink;
}

- (void)error:(NSString *)code
      message:(NSString *_Nullable)message
      details:(id _Nullable)details
{
    [self enqueue:[FlutterError errorWithCode:code
                                      message:message
                                      details:details]];
    [self flushIfNeed];
}

#pragma mark -

- (instancetype)init
{
    if (self = [super init]) {
        _eventQueue = @[].mutableCopy;
    }
    
    return self;
}

- (void)flushIfNeed
{
    if (self.eventSink == nil) {
        return;
    }
    
    for (NSObject *obj in self.eventQueue) {
        self.eventSink(obj);
    }
    [self.eventQueue removeAllObjects];
}

- (void)enqueue:(NSObject *)event
{
    [self.eventQueue addObject:event];
}

@end
