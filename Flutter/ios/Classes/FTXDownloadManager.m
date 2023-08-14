// Copyright (c) 2022 Tencent. All rights reserved.

#import "SuperPlayerPlugin.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import "FTXDownloadManager.h"
#import <TXLiteAVSDK_Player/TXVodPreloadManager.h>
#import <TXLiteAVSDK_Player/TXVodDownloadManager.h>
#import "FTXEvent.h"
#import "CommonUtil.h"
#import "FtxMessages.h"

@interface FTXDownloadManager ()<FlutterStreamHandler, TXVodPreloadManagerDelegate, TXVodDownloadDelegate, TXFlutterDownloadApi>
    
@end

@implementation FTXDownloadManager {
    FlutterEventChannel *_eventChannel;
    FTXPlayerEventSinkQueue *_eventSink;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        TXFlutterDownloadApiSetup([registrar messenger], self);
        
        _eventSink = [FTXPlayerEventSinkQueue new];
        _eventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/txvodplayer/download/event" binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        [[TXVodDownloadManager shareInstance] setDelegate:self];
        // Set the download storage path.
        NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [NSString stringWithFormat:@"%@/videoCache",cachesDir];
        [[TXVodDownloadManager shareInstance] setDownloadPath:path];
    }
    return self;
}

- (void)destroy
{
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    
    [_eventSink setDelegate:nil];
    _eventSink = nil;
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
     return nil == quality ? TXVodQualityFLU : [quality intValue];
 }

- (TXVodDownloadMediaInfo *)parseMediaInfoFromInfo:(NSNumber *)quality url:(NSString *)videoUrl appId:(NSNumber *)pAppId fileId:(NSString *)pFileId name:(NSString*)name {
    TXVodDownloadMediaInfo *mediaInfo = nil;
    if(name == nil) {
        name = @"default";
    }
    if(nil != pFileId && nil != pAppId) {
        TXVodDownloadMediaInfo *fileIdInfo = [[TXVodDownloadMediaInfo alloc] init];
        TXVodDownloadDataSource *dataSource = [[TXVodDownloadDataSource alloc] init];
        dataSource.appId = [pAppId intValue];
        dataSource.fileId = pFileId;;
        dataSource.quality = [self optQuality:quality];
        dataSource.userName = name;
        fileIdInfo.dataSource = dataSource;
        mediaInfo = [[TXVodDownloadManager shareInstance] getDownloadMediaInfo:fileIdInfo];
    } else if(nil != videoUrl) {
        TXVodDownloadMediaInfo *urlInfo = [[TXVodDownloadMediaInfo alloc] init];
        urlInfo.url = videoUrl;
        urlInfo.userName = name;
        mediaInfo = [[TXVodDownloadManager shareInstance] getDownloadMediaInfo:urlInfo];
    }
    return mediaInfo;
}

- (NSMutableDictionary *)buildMapFromDownloadMediaInfo:(TXVodDownloadMediaInfo *)info{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if(nil != info) {
        [dict setValue:info.playPath forKey:@"playPath"];
        [dict setValue:@(info.progress) forKey:@"progress"];
        [dict setValue:[CommonUtil getDownloadEventByState:(int)info.downloadState] forKey:@"downloadState"];
        [dict setValue:info.userName forKey:@"userName"];
        [dict setValue:@(info.duration) forKey:@"duration"];
        [dict setValue:@(info.playableDuration) forKey:@"playableDuration"];
        [dict setValue:@(info.size) forKey:@"size"];
        [dict setValue:@(info.downloadSize) forKey:@"downloadSize"];
        if(nil != info.url && info.url.length > 0) {
            [dict setValue:info.url forKey:@"url"];
        }
        if(nil != info.dataSource) {
            TXVodDownloadDataSource *dataSource = info.dataSource;
            [dict setValue:@(dataSource.appId) forKey:@"appId"];
            [dict setValue:dataSource.fileId forKey:@"fileId"];
            [dict setValue:dataSource.pSign forKey:@"pSign"];
            [dict setValue:@(dataSource.quality) forKey:@"quality"];
            [dict setValue:dataSource.token forKey:@"token"];
        }
        [dict setValue:@(info.speed) forKey:@"speed"];
        [dict setValue:@(info.isResourceBroken) forKey:@"isResourceBroken"];
    }
    return dict;
}

- (TXVodDownloadMediaMsg *)buildMsgFromDownloadInfo:(TXVodDownloadMediaInfo *)info{
    TXVodDownloadMediaMsg *msg = [[TXVodDownloadMediaMsg alloc] init];
    if(nil != info) {
        msg.playPath = info.playPath;
        msg.progress = @(info.progress);
        msg.downloadState = [CommonUtil getDownloadEventByState:(int)info.downloadState];
        msg.userName = info.userName;
        msg.duration = @(info.duration);
        msg.playableDuration = @(info.playableDuration);
        msg.size = @(info.size);
        msg.downloadSize = @(info.downloadSize);
        if(nil != info.url && info.url.length > 0) {
            msg.url = info.url;
        }
        if(nil != info.dataSource) {
            TXVodDownloadDataSource *dataSource = info.dataSource;
            msg.appId = @(dataSource.appId);
            msg.fileId = dataSource.fileId;
            msg.pSign = dataSource.pSign;
            msg.quality = @(dataSource.quality);
            msg.token = dataSource.token;
        }
    }
    return msg;
}

/// Download started.
- (void)onDownloadStart:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_START withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// Download progress.
- (void)onDownloadProgress:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_PROGRESS withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// Download stopped.
- (void)onDownloadStop:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_STOP withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// Download completed.
- (void)onDownloadFinish:(TXVodDownloadMediaInfo *)mediaInfo {
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_FINISH withParams:[self buildMapFromDownloadMediaInfo:mediaInfo]]];
}

/// Download error.
- (void)onDownloadError:(TXVodDownloadMediaInfo *)mediaInfo errorCode:(TXDownloadError)code errorMsg:(NSString *)msg {
    NSMutableDictionary *dict = [self buildMapFromDownloadMediaInfo:mediaInfo];
    [dict setValue:@(code) forKey:@"errorCode"];
    [dict setValue:msg forKey:@"errorMsg"];
    [_eventSink success:[FTXDownloadManager getParamsWithEvent:EVENT_DOWNLOAD_ERROR withParams:dict]];
}

/**
 * Download HLS and encounter encrypted files. Provide the decryption key to the external for verification. Abandoned for now due to ijk legacy.
 * 下载HLS，遇到加密的文件，将解密key给外部校验，ijk遗留，暂时弃用
 * @param mediaInfo  Download object.
 *                  下载对象
 * @param url URL address.
 *            Url地址
 * @param data Server response.
 *             服务器返回
 * @return 0：If the verification is correct, continue downloading; otherwise, if the verification fails, throw a download error (SDK failed to obtain).
 *           校验正确，继续下载；否则校验失败，抛出下载错误（SDK 获取失败）
 */
- (int)hlsKeyVerify:(TXVodDownloadMediaInfo *)mediaInfo url:(NSString *)url data:(NSData *)data {
    return 0;
}

#pragma mark TXFlutterDownloadApi

- (nullable BoolMsg *)deleteDownloadMediaInfoMsg:(nonnull TXVodDownloadMediaMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:msg.quality url:msg.url appId:msg.appId fileId:msg.fileId name:msg.userName];
    BOOL deleteResult = [[TXVodDownloadManager shareInstance] deleteDownloadMediaInfo:mediaInfo];
    return [CommonUtil boolMsgWith:deleteResult];
}

- (nullable TXVodDownloadMediaMsg *)getDownloadInfoMsg:(nonnull TXVodDownloadMediaMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:msg.quality url:msg.url appId:msg.appId fileId:msg.fileId name:msg.userName];
    return [self buildMsgFromDownloadInfo:mediaInfo];
}

- (nullable TXDownloadListMsg *)getDownloadListWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSArray<TXVodDownloadMediaInfo *> *mediaInfoList = [[TXVodDownloadManager shareInstance] getDownloadMediaInfoList];
    NSMutableArray<TXVodDownloadMediaMsg *> *resultMsgArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < mediaInfoList.count; i++) {
        [resultMsgArray addObject:[self buildMsgFromDownloadInfo:mediaInfoList[i]]];
    }
    TXDownloadListMsg *res = [[TXDownloadListMsg alloc] init];
    res.infoList = resultMsgArray;
    return res;
}

- (void)resumeDownloadMsg:(nonnull TXVodDownloadMediaMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:msg.quality url:msg.url appId:msg.appId fileId:msg.fileId name:msg.userName];
    if (nil != mediaInfo) {
        TXVodDownloadDataSource *dataSource = mediaInfo.dataSource;
        if (nil != dataSource) {
            [[TXVodDownloadManager shareInstance] startDownload:dataSource];
        } else {
            [[TXVodDownloadManager shareInstance] startDownload:mediaInfo.userName url:mediaInfo.url];
        }
    }
}

- (void)setDownloadHeadersHeaders:(nonnull MapMsg *)headers error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [[TXVodDownloadManager shareInstance] setHeaders:headers.map];
}

- (void)startDownloadMsg:(nonnull TXVodDownloadMediaMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if(nil != msg.url && ![msg.url isEqual:[NSNull null]]) {
        [[TXVodDownloadManager shareInstance] startDownload:msg.userName url:msg.url];
    } else if(nil != msg.appId && nil != msg.fileId && ![msg.fileId isEqual:[NSNull null]]) {
        TXVodDownloadDataSource *dataSource = [[TXVodDownloadDataSource alloc] init];
        dataSource.appId = [msg.appId intValue];
        dataSource.fileId = msg.fileId;
        dataSource.userName = msg.userName;
        dataSource.quality = [self optQuality:msg.quality];
        if(msg.pSign != nil && [msg.pSign isEqual:[NSNull null]]) {
            dataSource.pSign = nil;
        } else {
            dataSource.pSign = msg.pSign;
        }
        [[TXVodDownloadManager shareInstance] startDownload:dataSource];
    }
}

- (nullable IntMsg *)startPreLoadMsg:(nonnull PreLoadMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int preloadSizeMB = [msg.preloadSizeMB intValue];
    int preferredResolution = [msg.preferredResolution intValue];
    int taskID = [[TXVodPreloadManager sharedManager] startPreload:msg.playUrl
                                                       preloadSize:preloadSizeMB
                                               preferredResolution:preferredResolution
                                                          delegate:self];
    return [CommonUtil intMsgWith:@(taskID)];
}

- (void)stopDownloadMsg:(nonnull TXVodDownloadMediaMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    TXVodDownloadMediaInfo *mediaInfo = [self parseMediaInfoFromInfo:msg.quality url:msg.url appId:msg.appId fileId:msg.fileId name:msg.userName];
    [[TXVodDownloadManager shareInstance] stopDownload:mediaInfo];
}

- (void)stopPreLoadMsg:(nonnull IntMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [[TXVodPreloadManager sharedManager] stopPreload:msg.value.intValue];
}

@end
