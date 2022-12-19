// Copyright (c) 2022 Tencent. All rights reserved./

#import "FTXPlayerEventSinkQueue.h"

@interface FTXPlayerEventSinkQueue ()

@property (nonatomic, strong) NSMutableArray *eventQueue;
@property (nonatomic, copy) FlutterEventSink eventSink;


@end

@implementation FTXPlayerEventSinkQueue

#pragma mark - public

- (void)success:(id)event
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
    
    // array Immutable handle
    NSArray *array = [NSArray arrayWithArray:self.eventQueue];
    for (NSObject *obj in array) {
        self.eventSink(obj);
    }
    [self.eventQueue removeAllObjects];
}

- (void)enqueue:(NSObject *)event
{
    [self.eventQueue addObject:event];
}

@end
