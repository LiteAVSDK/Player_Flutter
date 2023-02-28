// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXVodPlayer.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXTransformation.h"
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import <Flutter/Flutter.h>
#import <AVKit/AVKit.h>
#import "FTXEvent.h"

static const int uninitialized = -1;
static const int CODE_ON_RECEIVE_FIRST_FRAME   = 2003;

@interface FTXVodPlayer ()<FlutterStreamHandler, FlutterTexture, TXVodPlayListener, TXVideoCustomProcessDelegate>

@property (nonatomic, strong) UIView *txPipView;
@property (nonatomic, assign) BOOL hasEnteredPipMode;
@property (nonatomic, assign) BOOL restoreUI;

@end
/**
 点播TXVodPlayer处理类
 */
@implementation FTXVodPlayer {
    TXVodPlayer *_txVodPlayer;
    TXImageSprite *_txImageSprite;
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
    
    float currentPlayTime;
    BOOL volatile isVideoFirstFrameReceived;
    NSNumber *videoWidth;
    NSNumber *videoHeight;
    // 主线程队列，用于保证视频播放部分事件按顺序进行
    dispatch_queue_t playerMainqueue;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar
{
    if (self = [self init]) {
        _registrar = registrar;
        _lastBuffer = nil;
        _latestPixelBuffer = nil;
        _textureId = -1;
        isVideoFirstFrameReceived = false;
        videoWidth = 0;
        videoHeight = 0;
        playerMainqueue = dispatch_get_main_queue();
        self.hasEnteredPipMode = NO;
        self.restoreUI = NO;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationTerminateClick) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void)onApplicationTerminateClick {
    [_txVodPlayer removeVideoWidget];
    _txVodPlayer = nil;
    _txVodPlayer.videoProcessDelegate = nil;
    _textureId = -1;
}

- (void)destory
{
    [self stopPlay];
    [_txVodPlayer removeVideoWidget];
    _txVodPlayer = nil;
    
    self.txPipView = nil;
    _hasEnteredPipMode = NO;
    _restoreUI = NO;
    
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
    [self releaseImageSprite];
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

- (int)startVodPlay:(NSString *)url
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer startVodPlay:url];
    }
    return uninitialized;
}


- (int)startVodPlayWithParams:(NSDictionary *)params
{
    if (_txVodPlayer != nil) {
        TXPlayerAuthParams *p = [TXPlayerAuthParams new];
        p.appId = [params[@"appId"] unsignedIntValue];
        p.fileId = params[@"fileId"];
        NSString *psign = params[@"psign"];
        if (psign.length > 0) {
            p.sign = params[@"psign"];
        }
        return [_txVodPlayer startVodPlayWithParams:p];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (_txVodPlayer != nil) {
        return [_txVodPlayer stopPlay];
    }
    [self releaseImageSprite];
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
        NSArray *itemList = [_txVodPlayer supportedBitrates];
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

- (void)releaseImageSprite
{
    if(_txImageSprite) {
        _txImageSprite = nil;
    }
}

- (void)setImageSprite:(NSString*)urlStr withImgArray:(NSArray*)imgStrArray result:(FlutterResult)result {
    [self releaseImageSprite];
    _txImageSprite = [[TXImageSprite alloc] init];
    NSMutableArray *imageUrls = @[].mutableCopy;
    NSURL *vvtUrl = nil;
    if(imgStrArray && [NSNull null] != (NSNull *)imgStrArray) {
        for(NSString *url in imgStrArray) {
            NSURL *nsurl = [NSURL URLWithString:url];
            if (nsurl) {
                [imageUrls addObject:nsurl];
            }
        }
    }
    if(urlStr && [NSNull null] != (NSNull *)urlStr) {
        vvtUrl =  [NSURL URLWithString:urlStr];
    }
    [_txImageSprite setVTTUrl:vvtUrl imageUrls:imageUrls];
    result(nil);
}

- (void)getImageSprite:(NSNumber*)time result:(FlutterResult)result {
    if(_txImageSprite && [NSNull null] != (NSNull*)time) {
        UIImage *imageSprite = [_txImageSprite getThumbnail:time.floatValue];
        if(nil != imageSprite) {
            NSData *data = UIImagePNGRepresentation(imageSprite);
            result(data);
        } else {
            result(nil);
        }
    } else {
        NSLog(@"getImageSprite failed, time is null or initImageSprite not invoke");
        result(nil);
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
    }else if([@"setAutoPlay" isEqualToString:call.method]) {
        BOOL isAutoPlay = [args[@"isAutoPlay"] boolValue];
        [self setIsAutoPlay:isAutoPlay];
        result(nil);
    }else if([@"startVodPlay" isEqualToString:call.method]){
        NSString *url = args[@"url"];
        int r = [self startVodPlay:url];
        result(@(r));
    }else if([@"startVodPlayWithParams" isEqualToString:call.method]) {
        int r = [self startVodPlayWithParams:args];
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
        float startTime = [args[@"startTime"] floatValue];
        [self setStartTime:startTime];
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
        float time = [self getPlayableDuration];
        result(@(time));
    }
    else if([@"getDuration" isEqualToString:call.method]){
        float time = [self getDuration];
        result(@(time));
    }
    else if ([@"enterPictureInPictureMode" isEqualToString:call.method]) {
        int ret = [self enterPictureInPictureMode];
        result(@(ret));
    }
    else if ([@"initImageSprite" isEqualToString:call.method]) {
        NSDictionary *args = call.arguments;
        NSString *vvtStr = args[@"vvtUrl"];
        NSArray *imageStrs = args[@"imageUrls"];
        [self setImageSprite:vvtStr withImgArray:imageStrs result:result];
    }
    else if ([@"getImageSprite" isEqualToString:call.method]) {
        NSDictionary *args = call.arguments;
        NSNumber *time = args[@"time"];
        [self getImageSprite:time result:result];
    }
    else if ([@"exitPictureInPictureMode" isEqualToString:call.method]) {
        if(_txVodPlayer != nil) {
            [_txVodPlayer exitPictureInPicture];
        }
        result(nil);
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
    if (self.hasEnteredPipMode) {
        return [self getPipImagePixelBuffer];
    }

    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil,
                                             (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    dispatch_async(playerMainqueue, ^{
        if(!self->isVideoFirstFrameReceived && nil != pixelBuffer) {
            [self->_eventSink success:[FTXVodPlayer getParamsWithEvent:CODE_ON_RECEIVE_FIRST_FRAME withParams:@{@"EVT_WIDTH":@(self->videoWidth.intValue), @"EVT_HEIGHT":@(self->videoHeight.intValue),@"EVT_PARAM1":@(self->videoWidth.intValue), @"EVT_PARAM2":@(self->videoHeight.intValue)}]];
            self->isVideoFirstFrameReceived = true;
        }
    });
    return pixelBuffer;
}

#pragma mark - TXVodPlayListener

- (void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param
{
    // 交给flutter共享纹理处理首帧事件返回时机
    if (EvtID == CODE_ON_RECEIVE_FIRST_FRAME) {
        currentPlayTime = 0;
        dispatch_async(playerMainqueue, ^{
            self->videoWidth = param[@"EVT_WIDTH"];
            self->videoHeight = param[@"EVT_HEIGHT"];
        });
        return;
    } else if(EvtID == PLAY_EVT_CHANGE_RESOLUTION) {
        dispatch_async(playerMainqueue, ^{
            self->videoWidth = param[@"EVT_WIDTH"];
            self->videoHeight = param[@"EVT_HEIGHT"];
        });
    } else if(EvtID == PLAY_EVT_PLAY_PROGRESS) {
        currentPlayTime = [param[EVT_PLAY_PROGRESS] floatValue];
    } else if(EvtID == PLAY_EVT_PLAY_BEGIN) {
        currentPlayTime = 0;
    } else if(EvtID == PLAY_EVT_START_VIDEO_DECODER) {
        dispatch_async(playerMainqueue, ^{
            self->isVideoFirstFrameReceived = false;
        });
    }
    
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

#pragma mark - Private Method

/**
 判断当前语言是否是简体中文
 */
- (BOOL)isCurrentLanguageHans
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    if ([currentLanguage isEqualToString:@"zh-Hans-CN"])
    {
        return YES;
    }
    
    return NO;
}

- (CVPixelBufferRef)getPipImagePixelBuffer
{
    NSString *imagePath;
    if ([self isCurrentLanguageHans]) {
        imagePath = [[NSBundle mainBundle] pathForResource:@"pictureInpicture_zh" ofType:@"jpg"];
    } else {
        imagePath = [[NSBundle mainBundle] pathForResource:@"pictureInpicture_en" ofType:@"jpg"];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return [self CVPixelBufferRefFromUiImage:image];
}

- (void)setPlayConfig:(NSDictionary *)args
{
    if (_txVodPlayer != nil && [args[@"config"] isKindOfClass:[NSDictionary class]]) {
        _txVodPlayer.config = [FTXTransformation transformToVodConfig:args];
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

- (int)enterPictureInPictureMode {
    if (_hasEnteredPipMode) {
        return ERROR_IOS_PIP_IS_RUNNING;
    }
    
    if (![TXVodPlayer isSupportPictureInPicture]) {
        return ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
    }
        
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipRequestStart)]) {
        [self.delegate onPlayerPipRequestStart];
    }
    
    UIViewController* flutterVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [flutterVC.view addSubview:self.txPipView];
    [_txVodPlayer setupVideoWidget:self.txPipView insertIndex:0];
    [_txVodPlayer enterPictureInPicture];
    
    return NO_ERROR;
}

- (UIView *)txPipView {
    if (!_txPipView) {
        // 给定1像素的大小，使得画中画正常显示
        _txPipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _txPipView.hidden = YES;
    }
    return _txPipView;
}

#pragma mark - 画中画代理
- (void)onPlayer:(TXVodPlayer *)player pictureInPictureStateDidChange:(TX_VOD_PLAYER_PIP_STATE)pipState withParam:(NSDictionary *)param {
    if (pipState == TX_VOD_PLAYER_PIP_STATE_DID_START) {
        self.hasEnteredPipMode = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateDidStart)]) {
            [self.delegate onPlayerPipStateDidStart];
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_WILL_STOP) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateWillStop)]) {
            [self.delegate onPlayerPipStateWillStop];
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_DID_STOP) {
        self.hasEnteredPipMode = NO;
        if (self.restoreUI) {
            self.restoreUI = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    [player exitPictureInPicture];
                }
                [self->_txPipView removeFromSuperview];
                self->_txPipView = nil;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateDidStop)]) {
                    [self.delegate onPlayerPipStateDidStop];
                }
            });
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_RESTORE_UI) {
        self.restoreUI = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [player exitPictureInPicture];
            [self->_txVodPlayer resume];
        });
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateRestoreUI:)]) {
            [self.delegate onPlayerPipStateRestoreUI:currentPlayTime];
        }
    }
}

- (void)onPlayer:(TXVodPlayer *)player pictureInPictureErrorDidOccur:(TX_VOD_PLAYER_PIP_ERROR_TYPE)errorType withParam:(NSDictionary *)param {
    NSInteger type = errorType;
    switch (errorType) {
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_NONE:
            type = NO_ERROR;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_DEVICE_NOT_SUPPORT:
            type = ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_SUPPORT:
            type = ERROR_IOS_PIP_PLAYER_NOT_SUPPORT;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_VIDEO_NOT_SUPPORT:
            type = ERROR_IOS_PIP_VIDEO_NOT_SUPPORT;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_NOT_POSSIBLE:
            type = ERROR_IOS_PIP_IS_NOT_POSSIBLE;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_ERROR_FROM_SYSTEM:
            type = ERROR_IOS_PIP_FROM_SYSTEM;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_EXIST:
            type = ERROR_IOS_PIP_PLAYER_NOT_EXIST;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_RUNNING:
            type = ERROR_IOS_PIP_IS_RUNNING;
            break;
        case TX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_NOT_RUNNING:
            type = ERROR_IOS_PIP_NOT_RUNNING;
            break;
    }
    self.hasEnteredPipMode = NO;
    NSLog(@"[onPlayer], pictureInPictureErrorDidOccur errorType= %ld", type);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateError:)]) {
        [self.delegate onPlayerPipStateError:type];
    }
}

#pragma mark - UIImage转CVPixelBufferRef

- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    CGSize size = img.size;
    CGImageRef image = [img CGImage];
    
    BOOL hasAlpha = CGImageRefContainsAlpha(image);
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             empty, kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, inputPixelFormat(), (__bridge CFDictionaryRef) options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(inputPixelFormat(), (bool)hasAlpha);
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, bitmapInfo);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    return pxbuffer;
}

static OSType inputPixelFormat(){
    return kCVPixelFormatType_32BGRA;
}

static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha){
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        if (!hasAlpha) {
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        }
        return bitmapInfo;
    }else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
        return bitmapInfo;
    }else{
        return 0;
    }
}

// alpha的判断
BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

@end
