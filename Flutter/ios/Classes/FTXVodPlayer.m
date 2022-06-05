//
//  FTXVodPlayer.m
//  super_player
//
//  Created by Zhirui Ou on 2021/3/15.
//

#import "FTXVodPlayer.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXTransformation.h"
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import <Flutter/Flutter.h>

static const int uninitialized = -1;

@interface FTXVodPlayer ()<FlutterStreamHandler, FlutterTexture, TXVodPlayListener, TXVideoCustomProcessDelegate>

@end
/**
 点播TXVodPlayer处理类
 */
@implementation FTXVodPlayer {
    TXVodPlayer *_txVodPlayer;
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
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[@"cloud.tencent.com/txvodplayer/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txvodplayer/event/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        
        _netStatusChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txvodplayer/net/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_netStatusChannel setStreamHandler:self];
    }
    
    return self;
}

- (void)destory
{
    [self stopPlay];
    [_txVodPlayer removeVideoWidget];
    _txVodPlayer = nil;
    
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
    [_netStatusSink setDelegate:nil];
    _netStatusSink = nil;
    
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    
    [_netStatusChannel setStreamHandler:nil];
    _netStatusChannel = nil;
}

- (void)setupPlayerWithBool:(BOOL)onlyAudio
{
    if (!onlyAudio) {
        if (_textureId < 0) {
            _textureRegistry = [_registrar textures];
            int64_t tId = [_textureRegistry registerTexture:self];
            _textureId = tId;
        }
        
        if (_txVodPlayer != nil) {
            [_txVodPlayer setVideoProcessDelegate:self];
            _txVodPlayer.enableHWAcceleration = YES;
        }
    }
}

#pragma mark -

- (NSNumber*)createPlayer:(BOOL)onlyAudio
{
    if (_txVodPlayer == nil) {
        _txVodPlayer = [TXVodPlayer new];
        _txVodPlayer.vodDelegate = self;
        [self setupPlayerWithBool:onlyAudio];
    }
    return [NSNumber numberWithLongLong:_textureId];
}

- (void)setIsAutoPlay:(BOOL)b
{
    if (_txVodPlayer != nil) {
        _txVodPlayer.isAutoPlay = b;
    }
}

- (int)startPlay:(NSString *)url
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer startPlay:url];
    }
    return uninitialized;
}

- (int)startPlayWithParams:(NSDictionary *)params
{
    if (_txVodPlayer != nil) {
        TXPlayerAuthParams *p = [TXPlayerAuthParams new];
        NSString *timeout = params[@"timeout"];
        NSString *us = params[@"us"];
        NSString *sign = params[@"sign"];
        int exper = [params[@"exper"] intValue];
        
        p.appId = [params[@"appId"] unsignedIntValue];
        
        p.fileId = params[@"fileId"];
        if (timeout.length > 0) {
            p.timeout = timeout;
        }
        if (exper != 0) {
            p.exper = exper;
        }
        if (us.length > 0) {
            p.us = us;
        }
        if (sign.length > 0) {
            p.sign = params[@"sign"];
        }

        p.https = [params[@"https"] boolValue];
        return [_txVodPlayer startPlayWithParams:p];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer stopPlay];
    }
    return NO;
}

- (BOOL)isPlaying
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer isPlaying];
    }
    return NO;
}

- (void)pause
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer pause];
    }
}

- (void)resume
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer resume];
    }
}

- (void)setMute:(BOOL)bEnable
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer setMute:bEnable];
    }
}

- (void)setLoop:(BOOL)bLoop
{
    if (_txVodPlayer != nil) {
        _txVodPlayer.loop = bLoop;
    }
}

- (void)seek:(float)progress
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer seek:progress];
    }
}

- (void)setRate:(float)rate
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setRate:rate];
    }
}

- (NSArray *)supportedBitrates
{
    if (_txVodPlayer != nil) {
        NSArray *itemList = _txVodPlayer.supportedBitrates;
        NSMutableArray *bitrates = @[].mutableCopy;
        for (TXBitrateItem *item in itemList) {
            [bitrates addObject:@{@"index": @(item.index), @"width": @(item.width), @"height": @(item.height), @"bitrate": @(item.bitrate)}];
        }
        return bitrates;
    }
    
    return @[];
}

- (void)setBitrateIndex:(int)index
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setBitrateIndex:index];
    }
}

- (void)setStartTime:(float)startTime//这个接口有bug
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setStartTime:startTime];
    }
}

- (void)setAudioPlayoutVolume:(int)volume
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setAudioPlayoutVolume:volume];
    }
}

- (void)setRenderRotation:(int)rotation
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setRenderRotation:rotation];
    }
}

- (void)setMirror:(BOOL)isMirror
{
    if (_txVodPlayer != nil) {
        [_txVodPlayer setMirror:isMirror];
    }
}

#pragma mark -

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSDictionary *args = call.arguments;
    if([@"init" isEqualToString:call.method]){
        BOOL onlyAudio = [args[@"onlyAudio"] boolValue];
        NSNumber* textureId = [self createPlayer:onlyAudio];
        result(textureId);
    }else if([@"setIsAutoPlay" isEqualToString:call.method]) {
        BOOL isAutoPlay = [args[@"isAutoPlay"] boolValue];
        [self setIsAutoPlay:isAutoPlay];
        result(nil);
    }else if([@"play" isEqualToString:call.method]){
        NSString *url = args[@"url"];
        int r = [self startPlay:url];
        result(@(r));
    }else if([@"startPlayWithParams" isEqualToString:call.method]) {
        int r = [self startPlayWithParams:args];
        result(@(r));
    } else if([@"stop" isEqualToString:call.method]){
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
    }else if([@"setLiveMode" isEqualToString:call.method]){
        result(nil);
    }else if([@"setLoop" isEqualToString:call.method]){
        BOOL loop = [args[@"loop"] boolValue];
        [self setLoop:loop];
        result(nil);
    }else if ([@"seek" isEqualToString:call.method]) {
        double progress = [args[@"progress"] floatValue];
        [self seek:progress];
        result(nil);
    }else if ([@"setRate" isEqualToString:call.method]) {
        double rate = [args[@"rate"] floatValue];
        [self setRate:rate];
        result(nil);
    }else if([@"getSupportedBitrates" isEqualToString:call.method]) {
        NSArray *supportedBitrates = [self supportedBitrates];
        result(supportedBitrates);
    }else if([@"setBitrateIndex" isEqualToString:call.method]) {
        int index = [args[@"index"] intValue];
        [self setBitrateIndex:index];
        result(nil);
    }else if([@"setStartTime" isEqualToString:call.method]) {
//        float startTime = [args[@"startTime"] floatValue];
//        [self setStartTime:startTime];
        result(nil);
    }else if([@"setAudioPlayoutVolume" isEqualToString:call.method]) {
        int volume = [args[@"volume"] intValue];
        [self setAudioPlayoutVolume:volume];
        result(nil);
    }else if([@"setRenderRotation" isEqualToString:call.method]) {
        int rotation = [args[@"rotation"] intValue];
        [self setRenderRotation:rotation];
        result(nil);
    }
    else if([@"setMirror" isEqualToString:call.method]){
        BOOL isMirror = [args[@"isMirror"] boolValue];
        [self setMirror:isMirror];
        result(nil);
    }
    else if([@"setConfig" isEqualToString:call.method]){
        [self setPlayConfig:args];
        result(nil);
    }
    else if([@"getCurrentPlaybackTime" isEqualToString:call.method]){
        float time = [self getCurrentPlaybackTime];
        result(@(time));
    }
    else if([@"getBufferDuration" isEqualToString:call.method]){
        result(FlutterMethodNotImplemented);
    }
    else if([@"getWidth" isEqualToString:call.method]){
        int width = [self getWidth];
        result(@(width));
    }
    else if([@"getHeight" isEqualToString:call.method]){
        int height = [self getHeight];
        result(@(height));
    }
    else if([@"setToken" isEqualToString:call.method]){
        NSString *token = args[@"token"];
        [self setToken:token];
        result(nil);
    }
    else if([@"isLoop" isEqualToString:call.method]){
        BOOL r = [self isLoop];
        result(@(r));
    }
    else if([@"enableHardwareDecode" isEqualToString:call.method]){
        BOOL enable = [args[@"enable"] boolValue];
        BOOL r = [self enableHardwareDecode:enable];
        result(@(r));
    }
    else if([@"snapshot" isEqualToString:call.method]){
        [self snapShot:^(UIImage *image) {
            if(image != nil) {
                NSData *data = UIImagePNGRepresentation(image);
                result(data);
            } else {
                result(nil);
            }
        }];
    }
    else if([@"setRequestAudioFocus" isEqualToString:call.method]){
        result(FlutterMethodNotImplemented);
    }
    else if([@"getBitrateIndex" isEqualToString:call.method]){
        long index = [self getBitrateIndex];
        result(@(index));
    }
    else if([@"getPlayableDuration" isEqualToString:call.method]){
        float time = [self getCurrentPlaybackTime];
        result(@(time));
    }
    else if([@"getDuration" isEqualToString:call.method]){
        float time = [self getDuration];
        result(@(time));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
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

#pragma mark - TXVodPlayListener

- (void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param
{
    [_eventSink success:[FTXVodPlayer getParamsWithEvent:EvtID withParams:param]];
}

/**
 * 网络状态通知
 *
 * @param player 点播对象
 * @param param 参见TXLiveSDKTypeDef.h
 * @see TXVodPlayer
 */
- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary*)param
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

- (void)setPlayConfig:(NSDictionary *)args
{
    if (_txVodPlayer != nil && [args[@"config"] isKindOfClass:[NSDictionary class]]) {
        _txVodPlayer.config = [FTXTransformation transformToConfig:args];
    }
}

- (float)getCurrentPlaybackTime
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.currentPlaybackTime;
    }
    return 0;
}

- (float)getDuration
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.duration;
    }
    return 0;
}

- (float)getPlayableDuration
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.playableDuration;
    }
    return 0;
}

- (int)getWidth
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.width;
    }
    return 0;
}

- (int)getHeight
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.height;
    }
    return 0;
}

- (void)setToken:(NSString *)token
{
    if(_txVodPlayer != nil) {
        if(token && token.length > 0) {
            _txVodPlayer.token = token;
        } else {
            _txVodPlayer.token = nil;
        }
    }
}

- (BOOL)isLoop
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.loop;
    }
    return false;
}

- (BOOL)enableHardwareDecode:(BOOL)enable
{
    if(_txVodPlayer != nil) {
        _txVodPlayer.enableHWAcceleration = enable;
        return true;
    }
    return false;
}

- (void)snapShot:(void (^)(UIImage *))listener
{
    if(_txVodPlayer != nil) {
        [_txVodPlayer snapshot:listener];
    }
}

- (void)setRenderMode:(int)renderMode
{
    if(_txVodPlayer != nil) {
        [_txVodPlayer setRenderMode:renderMode];
    }
}

- (long)getBitrateIndex
{
    if(_txVodPlayer != nil) {
        return _txVodPlayer.bitrateIndex;
    }
    return -1;
}

@end
