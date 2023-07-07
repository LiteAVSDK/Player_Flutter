// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXLivePlayer.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXTransformation.h"
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <Flutter/Flutter.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import "FtxMessages.h"
#import "CommonUtil.h"

static const int uninitialized = -1;

@interface FTXLivePlayer ()<FlutterStreamHandler, FlutterTexture, TXLivePlayListener, TXVideoCustomProcessDelegate, TXFlutterLivePlayerApi>

@end

@implementation FTXLivePlayer {
    TXLivePlayer *_txLivePlayer;
    FTXPlayerEventSinkQueue *_eventSink;
    FTXPlayerEventSinkQueue *_netStatusSink;
    FlutterEventChannel *_eventChannel;
    FlutterEventChannel *_netStatusChannel;
    // 最新的一帧
    CVPixelBufferRef volatile _latestPixelBuffer;
    // 旧的一帧
    CVPixelBufferRef _lastBuffer;
    int64_t _textureId;
    
    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
    BOOL _isTerminate;
    BOOL _isStoped;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        _registrar = registrar;
        _lastBuffer = nil;
        _latestPixelBuffer = nil;
        _isTerminate = NO;
        _isStoped = NO;
        _textureId = -1;
        _eventSink = [FTXPlayerEventSinkQueue new];
        _netStatusSink = [FTXPlayerEventSinkQueue new];
        
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

    [_eventSink setDelegate:nil];
    _eventSink = nil;
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    [_netStatusSink setDelegate:nil];
    _netStatusSink = nil;
}

- (void)notifyAppTerminate:(UIApplication *)application {
    _isTerminate = YES;
    _textureRegistry = nil;
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
            [config setPlayerPixelFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
            [_txLivePlayer setConfig:config];
            [_txLivePlayer setVideoProcessDelegate:self];
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

- (void)setRenderRotation:(int)rotation
{
    if (_txLivePlayer != nil) {
        [_txLivePlayer setRenderRotation:rotation];
    }
}

- (int)switchStream:(NSString *)url
{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer switchStream:url];
    }
    return -1;
}

- (int)startLivePlay:(NSString *)url type:(TX_Enum_PlayType)playType
{
    if (_txLivePlayer != nil) {
        _isStoped = NO;
        return [_txLivePlayer startLivePlay:url type:playType];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (_txLivePlayer != nil) {
        _isStoped = YES;
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

- (void)setRenderMode:(int)renderMode {
    if (_txLivePlayer != nil) {
       [_txLivePlayer setRenderMode:renderMode];
    }
}

- (BOOL)enableHardwareDecode:(BOOL)enable {
    if (_txLivePlayer != nil) {
        _txLivePlayer.enableHWAcceleration = enable;
    }
    return false;
}

- (void)setPlayerConfig:(FTXLivePlayConfigPlayerMsg *)args
{
    if (_txLivePlayer != nil && nil != args) {
        _txLivePlayer.config = [FTXTransformation transformMsgToLiveConfig:args];
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
    NSLog(@"onLivePlayEvent:%i,%@", EvtID, param[EVT_PLAY_DESCRIPTION]);
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
    if(!_isTerminate && !_isStoped) {
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
        if (_textureId >= 0 && _textureRegistry) {
            [_textureRegistry textureFrameAvailable:_textureId];
        }
    }
    return NO;
}

#pragma mark - TXFlutterLivePlayerApi

- (nullable BoolMsg *)enableHardwareDecodeEnable:(nonnull BoolPlayerMsg *)enable error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self enableHardwareDecode:enable.value];
    return [CommonUtil boolMsgWith:r];
}

- (nullable IntMsg *)enterPictureInPictureModePipParamsMsg:(nonnull PipParamsPlayerMsg *)pipParamsMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    //FlutterMethodNotImplemented
    return nil;
}

- (void)exitPictureInPictureModePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    //FlutterMethodNotImplemented
}

- (nullable IntMsg *)initializeOnlyAudio:(nonnull BoolPlayerMsg *)onlyAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber* textureId = [self createPlayer:onlyAudio.value.boolValue];
    return [CommonUtil intMsgWith:textureId];
}

- (nullable BoolMsg *)isPlayingPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [CommonUtil boolMsgWith:[self isPlaying]];
}

- (void)pausePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self pause];
}

- (void)prepareLiveSeekPlayerMsg:(nonnull StringIntPlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // FlutterMethodNotImplemented
}

- (void)resumePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self resume];
}

- (void)seekProgress:(nonnull DoublePlayerMsg *)progress error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // FlutterMethodNotImplemented
}

- (void)setAppIDAppId:(nonnull StringPlayerMsg *)appId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setAppID:appId.value];
}

- (void)setConfigConfig:(nonnull FTXLivePlayConfigPlayerMsg *)config error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setPlayerConfig:config];
}

- (void)setLiveModeMode:(nonnull IntPlayerMsg *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setLiveMode:mode.value.intValue];
}

- (void)setMuteMute:(nonnull BoolPlayerMsg *)mute error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setMute:mute.value.boolValue];
}

- (void)setVolumeVolume:(nonnull IntPlayerMsg *)volume error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setVolume:volume.value.intValue];
}

- (nullable BoolMsg *)startLivePlayPlayerMsg:(nonnull StringIntPlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self startLivePlay:playerMsg.strValue type:playerMsg.intValue.intValue];
    return [CommonUtil boolMsgWith:r];
}

- (nullable BoolMsg *)stopIsNeedClear:(nonnull BoolPlayerMsg *)isNeedClear error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [CommonUtil boolMsgWith:[self stopPlay]];
}

- (nullable IntMsg *)switchStreamUrl:(nonnull StringPlayerMsg *)url error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self switchStream:url.value];
    return [CommonUtil intMsgWith:@(r)];
}

@end
