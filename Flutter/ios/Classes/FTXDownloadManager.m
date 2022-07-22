// Copyright (c) 2022 Tencent. All rights reserved.

#import "SuperPlayerPlugin.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import "FTXDownloadManager.h"
#import <TXLiteAVSDK_Player/TXVodPreloadManager.h>
#import <TXLiteAVSDK_Player/TXVodDownloadManager.h>
#import "FTXEvent.h"
#import "CommonUtil.h"

@interface FTXDownloadManager ()<FlutterStreamHandler, TXVodPreloadManagerDelegate, TXVodDownloadDelegate>
    
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
        [[TXVodDownloadManager shareInstance] setDelegate:self];
        // 设置下载存储路径
        NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [NSString stringWithFormat:@"%@/videoCache",cachesDir];
        [[TXVodDownloadManager shareInstance] setDownloadPath:path];
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
    } else if([@"startDownload" isEqualToString:call.method]) {
        NSNumber *quality = args[@"quality"];
        NSString *videoUrl = args[@"url"];
        NSNumber *appIdNum = args[@"appId"];
        NSString *fileId = args[@"fileId"];
        NSString *pSign = args[@"pSign"];
        NSString *userName = args[@"userName"];
        if([NSNull null] != (NSNull *)videoUrl) {
            [[TXVodDownloadManager shareInstance] startDownload:userName url:videoUrl];
        } else if([NSNull null] != (NSNull *)appIdNum && [NSNull null] != (NSNull *)fileId) {
            TXVodDownloadDataSource *dataSource = [[TXVodDownloadDataSource alloc] init];
            dataSource.appId = [appIdNum intValue];
            dataSource.fileId = fileId;
            dataSource.userName = userName;
            dataSource.quality = [self optQuality:quality];
            if([NSNull null] != (NSNull *)pSign) {
                dataSource.pSign = pSign;
            }
            [[TXVodDownloadManager shareInstance] startDownload:dataSource];
        }
        result(nil);
    } else if([@"stopDownload" isEqualToString:call.method]) {
        NSNumber *quality = args[@"quality"];
        NSString *videoUrl = args[@"url"];
        NSNumber *appIdNum = args[@"appId"];
        NSString *fileId = args[@"fileId"];
        TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:quality url:videoUrl appId:appIdNum fileId:fileId];
        [[TXVodDownloadManager shareInstance] stopDownload:mediaInfo];
        result(nil);
    } else if([@"setDownloadHeaders" isEqualToString:call.method]) {
        [[TXVodDownloadManager shareInstance] setHeaders:args];
        result(nil);
    } else if([@"getDownloadList" isEqualToString:call.method]) {
        NSArray<TXVodDownloadMediaInfo *> *mediaInfoList = [[TXVodDownloadManager shareInstance] getDownloadMediaInfoList];
        NSMutableArray<NSDictionary *> *resultDicArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < mediaInfoList.count; i++) {
            [resultDicArray addObject:[self buildMapFromDownloadMediaInfo:mediaInfoList[i]]];
        }
        result(resultDicArray);
    } else if([@"getDownloadInfo" isEqualToString:call.method]) {
        NSNumber *quality = args[@"quality"];
        NSString *videoUrl = args[@"url"];
        NSNumber *appIdNum = args[@"appId"];
        NSString *fileId = args[@"fileId"];
        TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:quality url:videoUrl appId:appIdNum fileId:fileId];
        NSDictionary *resultDic = [self buildMapFromDownloadMediaInfo:mediaInfo];
        result(resultDic);
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
    [dict setObject:@(error.code) forKey:@"code"];
    if (nil != error.userInfo.description) {
        [dict setObject:error.userInfo.description forKey:@"msg"];
    }
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_PREDOWNLOAD_ON_ERROR withParams:dict]];
}

#pragma mark - TXDownloadManager


- (int)optQuality:(NSNumber *)quality {
     return ([NSNull null] == (NSNull *)quality || nil == quality) ? TXVodQualityFLU : [quality intValue];
 }

- (TXVodDownloadMediaInfo *)parseMediaInfoFromInfo:(NSNumber *)quality url:(NSString *)videoUrl appId:(NSNumber *)pAppId fileId:(NSString *)pFileId {
    TXVodDownloadMediaInfo *mediaInfo = nil;
    if(nil != videoUrl && [NSNull null] != (NSNull *)videoUrl) {
        TXVodDownloadMediaInfo *urlInfo = [[TXVodDownloadMediaInfo alloc] init];
        urlInfo.url = videoUrl;
        mediaInfo = [[TXVodDownloadManager shareInstance] getDownloadMediaInfo:urlInfo];
    } else if([NSNull null] != (NSNull *)pFileId && [NSNull null] != (NSNull *)pAppId) {
        TXVodDownloadMediaInfo *fileIdInfo = [[TXVodDownloadMediaInfo alloc] init];
        TXVodDownloadDataSource *dataSource = [[TXVodDownloadDataSource alloc] init];
        dataSource.appId = [pAppId intValue];
        dataSource.fileId = pFileId;;
        dataSource.quality = [self optQuality:quality];
        fileIdInfo.dataSource = dataSource;
        mediaInfo = [[TXVodDownloadManager shareInstance] getDownloadMediaInfo:fileIdInfo];
    }
    return mediaInfo;
}

- (NSMutableDictionary *)buildMapFromDownloadMediaInfo:(TXVodDownloadMediaInfo *)info{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if(nil != info && [NSNull null] != (NSNull *)info) {
        [dict setValue:info.playPath forKey:@"playPath"];
        [dict setValue:@(info.progress) forKey:@"progress"];
        [dict setValue:@([CommonUtil getDownloadEventByState:(int)info.downloadState]) forKey:@"downloadState"];
        [dict setValue:info.userName forKey:@"userName"];
        [dict setValue:@(info.duration) forKey:@"duration"];
        [dict setValue:@(info.playableDuration) forKey:@"playableDuration"];
        [dict setValue:@(info.size) forKey:@"size"];
        [dict setValue:@(info.downloadSize) forKey:@"downloadSize"];
        if([NSNull null] != (NSNull *)info.url && info.url.length > 0) {
            [dict setValue:info.url forKey:@"url"];
        }
        if(nil != info.dataSource && [NSNull null] != (NSNull *)info.dataSource) {
            TXVodDownloadDataSource *dataSource = info.dataSource;
            [dict setValue:@(dataSource.appId) forKey:@"appId"];
            [dict setValue:dataSource.fileId forKey:@"fileId"];
            [dict setValue:dataSource.pSign forKey:@"pSign"];
            [dict setValue:@(dataSource.quality) forKey:@"quality"];
            [dict setValue:dataSource.token forKey:@"token"];
        }
    }
    return dict;
}

/// 下载开始
- (void)onDownloadStart:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_START withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// 下载进度
- (void)onDownloadProgress:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_PROGRESS withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// 下载停止
- (void)onDownloadStop:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_STOP withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// 下载完成
- (void)onDownloadFinish:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_FINISH withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// 下载错误
- (void)onDownloadError:(TXVodDownloadMediaInfo *)mediaInfo errorCode:(TXDownloadError)code errorMsg:(NSString *)msg {
    NSMutableDictionary *dict = [self buildMapFromDownloadMediaInfo:mediaInfo];
    [dict setValue:@(code) forKey:@"errorCode"];
    [dict setValue:msg forKey:@"errorMsg"];
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_ERROR withParams:dict]];
}

/**
 * 下载HLS，遇到加密的文件，将解密key给外部校验，ijk遗留，暂时弃用
 * @param mediaInfo 下载对象
 * @param url Url地址
 * @param data 服务器返回
 * @return 0：校验正确，继续下载；否则校验失败，抛出下载错误（SDK 获取失败）
 */
- (int)hlsKeyVerify:(TXVodDownloadMediaInfo *)mediaInfo url:(NSString *)url data:(NSData *)data {
    return 0;
}

@end
