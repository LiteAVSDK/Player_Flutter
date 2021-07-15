//
//  FTXLivePlayer.m
//  super_player
//
//  Created by Zhirui Ou on 2021/3/15.
//

#import "FTXLivePlayer.h"
#import "FTXPlayerEventSinkQueue.h"
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <Flutter/Flutter.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static const int uninitialized = -1;

@interface FTXLivePlayer ()<FlutterStreamHandler, FlutterTexture, TXLivePlayListener, TXVideoCustomProcessDelegate>

@end

@implementation FTXLivePlayer {
    TXLivePlayer *_txLivePlayer;
    FTXPlayerEventSinkQueue *_eventSink;
    FTXPlayerEventSinkQueue *_netStatusSink;
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;
    FlutterEventChannel *_netStatusChannel;
    // 最新的一帧
    CVPixelBufferRef volatile _latestPixelBuffer;
    // 旧的一帧
    CVPixelBufferRef _lastBuffer;
    int64_t _textureId;
    
    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        _registrar = registrar;
        _lastBuffer = nil;
        _latestPixelBuffer = nil;
        _textureId = -1;
        _eventSink = [FTXPlayerEventSinkQueue new];
        _netStatusSink = [FTXPlayerEventSinkQueue new];
        
        __weak typeof(self) weakSelf = self;
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[@"cloud.tencent.com/txliveplayer/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txliveplayer/event/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        
        _netStatusChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txliveplayer/net/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_netStatusChannel setStreamHandler:self];
    }
    
    return self;
}

- (void)destory
{
    [self stopPlay];
    [_txLivePlayer removeVideoWidget];
    _txLivePlayer = nil;
    
    if (_textureId >= 0) {
        [_textureRegistry unregisterTexture:_textureId];
        _textureId = -1;
        _textureRegistry = nil;
    }

    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, nil,
                                             (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old) {
        CFRelease(old);
    }

    if (_lastBuffer) {
        CVPixelBufferRelease(_lastBuffer);
        _lastBuffer = nil;
    }
    
    [_methodChannel setMethodCallHandler:nil];
    _methodChannel = nil;

    [_eventSink setDelegate:nil];
    _eventSink = nil;
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    [_netStatusSink setDelegate:nil];
    _netStatusSink = nil;
}

- (void)setupPlayerWithBool:(BOOL)onlyAudio
{
    if (!onlyAudio) {
        if (_textureId < 0) {
            _textureRegistry = [_registrar textures];
            int64_t tId = [_textureRegistry registerTexture:self];
            _textureId = tId;
        }
        
        if (_txLivePlayer != nil) {
            TXLivePlayConfig *config = [TXLivePlayConfig new];
            [config setPlayerPixelFormatType:kCVPixelFormatType_32BGRA];
            [_txLivePlayer setConfig:config];
            [_txLivePlayer setVideoProcessDelegate:self];
            _txLivePlayer.enableHWAcceleration = YES;
        }
    }
}

#pragma mark -

- (NSNumber*)createPlayer:(BOOL)onlyAudio
{
    if (_txLivePlayer == nil) {
        _txLivePlayer = [TXLivePlayer new];
        _txLivePlayer.delegate = self;
        [self setupPlayerWithBool:onlyAudio];
    }
    return [NSNumber numberWithLongLong:_textureId];
}

- (void)setIsAutoPlay:(BOOL)b
{
    if (_txLivePlayer != nil) {
        _txLivePlayer.isAutoPlay = b;
    }
}

- (void)setRenderRotation:(int)rotation
{
    if (_txLivePlayer != nil) {
        [_txLivePlayer setRenderRotation:rotation];
    }
}

- (void)switchStream:(NSString *)url
{
    if (_txLivePlayer != nil) {
        [_txLivePlayer switchStream:url];
    }
}

- (void)seek:(float)progress
{
    if (_txLivePlayer != nil) {
        [_txLivePlayer seek:progress];
    }
}

- (int)startPlay:(NSString *)url type:(TX_Enum_PlayType)playType
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer startPlay:url type:playType];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer stopPlay];
    }
    return NO;
}

- (BOOL)isPlaying
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer isPlaying];
    }
    return NO;
}

- (void)pause
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer pause];
    }
}

- (void)resume
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer resume];
    }
}

- (void)setMute:(BOOL)bEnable
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer setMute:bEnable];
    }
}

- (void)setVolume:(int)volume
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer setVolume:volume];
    }
}

- (void)setLiveMode:(int)type
{
    TXLivePlayConfig *config = _txLivePlayer.config;
    
    if (type == 0) {
        //自动模式
        config.bAutoAdjustCacheTime   = YES;
        config.minAutoAdjustCacheTime = 1;
        config.maxAutoAdjustCacheTime = 5;
    }else if(type == 1){
        //极速模式
        config.bAutoAdjustCacheTime   = YES;
        config.minAutoAdjustCacheTime = 1;
        config.maxAutoAdjustCacheTime = 1;
    }else{
        //流畅模式
        config.bAutoAdjustCacheTime   = NO;
        config.minAutoAdjustCacheTime = 5;
        config.maxAutoAdjustCacheTime = 5;
    }
    [_txLivePlayer setConfig:config];
}

- (void)setAppID:(NSString *)appId
{
    [TXLiveBase setAppID:appId];
}

- (int)prepareLiveSeek:(NSString *)domain
                 bizId:(NSInteger)bizId
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer prepareLiveSeek:domain bizId:bizId];
    }
    
    return uninitialized;
}

#pragma mark -

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSDictionary *args = call.arguments;
    
    if([@"init" isEqualToString:call.method]){
        BOOL onlyAudio = [args[@"onlyAudio"] boolValue];
        NSNumber* textureId = [self createPlayer:onlyAudio];
        result(textureId);
    }else if([@"isAutoPlay" isEqualToString:call.method]) {
        BOOL isAutoPlay = [args[@"isAutoPlay"] boolValue];
        [self setIsAutoPlay:isAutoPlay];
        result(nil);
    }else if([@"play" isEqualToString:call.method]){
        NSString *url = args[@"url"];
        int type = -1;
        if(![[args objectForKey:@"playType"] isEqual:[NSNull null]]){
            type = [args[@"playType"] intValue];
        }
        int r = [self startPlay:url type:type];
        result(@(r));
    }else if([@"stop" isEqualToString:call.method]){
        BOOL r = [self stopPlay];
        result([NSNumber numberWithBool:r]);
    }else if([@"isPlaying" isEqualToString:call.method]){
        result([NSNumber numberWithBool:[self isPlaying]]);
    }else if([@"pause" isEqualToString:call.method]){
        [self pause];
        result(nil);
    }else if([@"resume" isEqualToString:call.method]){
        [self resume];
        result(nil);
    }else if([@"setMute" isEqualToString:call.method]){
        BOOL mute = [args[@"mute"] boolValue];
        [self setMute:mute];
        result(nil);
    }else if([@"setVolume" isEqualToString:call.method]){
        int volume = [args[@"volume"] intValue];
        [self setVolume:volume];
        result(nil);
    }else if([@"setLiveMode" isEqualToString:call.method]){
        int type = [args[@"type"] intValue];
        [self setLiveMode:type];
        result(nil);
    }else if([@"destory" isEqualToString:call.method]) {
        [self destory];
    }else if([@"setRenderRotation" isEqualToString:call.method]) {
        int rotation = [args[@"rotation"] intValue];
        [self setRenderRotation:rotation];
    }else if([@"switchStream" isEqualToString:call.method]) {
        NSString *url = args[@"url"];
        [self switchStream:url];
    }else if ([@"seek" isEqualToString:call.method]) {
        double progress = [args[@"progress"] floatValue];
        [self seek:progress];
        result(nil);
    }else if ([@"setAppID" isEqualToString:call.method]) {
        [self setAppID:args[@"appId"]];
        result(nil);
    }else if ([@"prepareLiveSeek" isEqualToString:call.method]) {
        NSString *domain = args[@"domain"];
        NSInteger bizId = [args[@"bizId"] intValue];
        int r = [self prepareLiveSeek:domain bizId:bizId];
        result(@(r));
    }else {
      result(FlutterMethodNotImplemented);
    }
    
    NSLog(@"handleMethodCall ==== %@", call.method);
}

+ (NSDictionary *)getParamsWithEvent:(int)EvtID withParams:(NSDictionary *)params
{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtID) forKey:@"event"];
    if (params != nil && params.count != 0) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}

#pragma mark - FlutterStreamHandler

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:events];
        }else if ([arguments isEqualToString:@"net"]) {
            [_netStatusSink setDelegate:events];
        }
    }
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:nil];
        }else if ([arguments isEqualToString:@"net"]) {
            [_netStatusSink setDelegate:nil];
        }
    }
    return nil;
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef _Nullable)copyPixelBuffer
{
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil,
                                             (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    return pixelBuffer;
}

#pragma mark - TXLivePlayListener

/**
 * 直播事件通知
 * @param EvtID 参见 TXLiveSDKEventDef.h 
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary *)param
{
//    switch (EvtID) {
//        case PLAY_EVT_CONNECT_SUCC: //已经连接服务器
//        case PLAY_EVT_PLAY_PROGRESS:
//        case PLAY_EVT_RTMP_STREAM_BEGIN: //已经连接服务器，开始拉流（仅播放 RTMP 地址时会抛送）
//        case PLAY_EVT_RCV_FIRST_I_FRAME: //收到首帧数据，越快收到此消息说明链路质量越好
//        case PLAY_EVT_PLAY_BEGIN: //视频播放开始，如果您自己做 loading，会需要它
//        case PLAY_EVT_PLAY_END: //播放结束，HTTP-FLV 的直播流不抛这个事件
//        case PLAY_ERR_NET_DISCONNECT: //网络断连，且经多次重连亦不能恢复，更多重试请自行重启播放
//        case PLAY_EVT_CHANGE_RESOLUTION: //视频分辨率发生变化（分辨率在 EVT_PARAM 参数中）
//        case PLAY_WARNING_RECONNECT:
//        case PLAY_WARNING_DNS_FAIL:
//        case PLAY_WARNING_SEVER_CONN_FAIL:
//        case PLAY_WARNING_SHAKE_FAIL:
            [_eventSink success:[FTXLivePlayer getParamsWithEvent:EvtID withParams:param]];
//            break;
//        default:
//            break;
//    }
}

/**
 * 网络状态通知
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onNetStatus:(NSDictionary *)param;
{
    [_netStatusSink success:param];
}

#pragma mark - TXVideoCustomProcessDelegate

/**
 * 视频渲染对象回调
 * @param pixelBuffer   渲染图像
 * @return              返回YES则SDK不再显示；返回NO则SDK渲染模块继续渲染
 *  说明：渲染图像的数据类型为config中设置的renderPixelFormatType
 */
- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (_lastBuffer == nil) {
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    } else if (_lastBuffer != pixelBuffer) {
        CVPixelBufferRelease(_lastBuffer);
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    }

    CVPixelBufferRef newBuffer = pixelBuffer;

    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer,
                                             (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }

    if (old && old != pixelBuffer) {
        CFRelease(old);
    }
    if (_textureId >= 0) {
        [_textureRegistry textureFrameAvailable:_textureId];
    }
    
    return NO;
}

@end
