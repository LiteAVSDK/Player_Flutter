// Copyright (c) 2022 Tencent. All rights reserved.

#import "SuperPlayerPlugin.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import "FTXDownloadManager.h"
#import <TXLiteAVSDK_Professional/TXVodPreloadManager.h>
#import "FTXEvent.h"

@interface FTXDownloadManager ()<FlutterStreamHandler, TXVodPreloadManagerDelegate>
    
@end

@implementation FTXDownloadManager {
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;
    FTXPlayerEventSinkQueue *_eventSink;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        __weak typeof(self) weakSelf = self;
        _methodChannel = [FlutterMethodChannel methodChannelWithName:@"cloud.tencent.com/txvodplayer/download/api" binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        
        _eventSink = [FTXPlayerEventSinkQueue new];
        _eventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/txvodplayer/download/event" binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        NSLog(@"dokie initWithRegistrar");
    }
    return self;
}

- (void)destroy
{
    [_methodChannel setMethodCallHandler:nil];
    _methodChannel = nil;
    
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    
    [_eventSink setDelegate:nil];
    _eventSink = nil;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    if([@"startPreLoad" isEqualToString:call.method]) {
        NSString *playUrl = args[@"playUrl"];
        int preloadSizeMB = [args[@"preloadSizeMB"] intValue];
        int preferredResolution = [args[@"preferredResolution"] intValue];
        int taskID = [[TXVodPreloadManager sharedManager] startPreload:playUrl
                                                           preloadSize:preloadSizeMB
                                                   preferredResolution:preferredResolution
                                                              delegate:self];
        result(@(taskID));
    } else if([@"stopPreLoad" isEqualToString:call.method]) {
        int taskId = [args[@"taskId"] intValue];
        [[TXVodPreloadManager sharedManager] stopPreload:taskId];
        result(nil);
    }
}


#pragma mark - FlutterStreamHandler

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:events];
        }
    }
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:nil];
        }
    }
    return nil;
}


+ (NSDictionary *)getParamsWithEvent:(int)EvtID withParams:(NSDictionary *)params
{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtID) forKey:@"event"];
    if (params != nil && params.count != 0) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}

#pragma mark - TXVodPreloadManager delegate

- (void)onComplete:(int)taskID url:(NSString *)url
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(taskID) forKey:@"taskId"];
    [dict setObject:url forKey:@"url"];
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_PREDOWNLOAD_ON_COMPLETE withParams:dict]];
}

- (void)onError:(int)taskID url:(NSString *)url error:(NSError *)error
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(taskID) forKey:@"taskId"];
    [dict setObject:url forKey:@"url"];
    [dict setObject:error.code forKey:@"code"];
    if (nil != error.userInfo.description) {
        [dict setObject:error.userInfo.description forKey:@"msg"];
    }
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_PREDOWNLOAD_ON_ERROR withParams:dict]];
}

@end
