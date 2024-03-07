// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXVodPlayer.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXTransformation.h"
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import <Flutter/Flutter.h>
#import <AVKit/AVKit.h>
#import "FTXEvent.h"
#import "FtxMessages.h"
#import "TXCommonUtil.h"

static const int uninitialized = -1;
static const int CODE_ON_RECEIVE_FIRST_FRAME   = 2003;

@interface FTXVodPlayer ()<FlutterStreamHandler, FlutterTexture, TXVodPlayListener, TXVideoCustomProcessDelegate, TXFlutterVodPlayerApi>

@property (nonatomic, strong) UIView *txPipView;
@property (nonatomic, assign) BOOL hasEnteredPipMode;
@property (nonatomic, assign) BOOL restoreUI;
@property (atomic, assign) BOOL isStoped;
@property (atomic) BOOL isTerminate;

@end
/**
 VOD player TXVodPlayer processing class.
 */
@implementation FTXVodPlayer {
    TXVodPlayer *_txVodPlayer;
    TXImageSprite *_txImageSprite;
    FTXPlayerEventSinkQueue *_eventSink;
    FTXPlayerEventSinkQueue *_netStatusSink;
    FlutterEventChannel *_eventChannel;
    FlutterEventChannel *_netStatusChannel;
    // The latest frame.
    CVPixelBufferRef volatile _latestPixelBuffer;
    // The old frame.
    CVPixelBufferRef _lastBuffer;
    int64_t _textureId;
    
    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
    
    float currentPlayTime;
    BOOL volatile isVideoFirstFrameReceived;
    NSNumber *videoWidth;
    NSNumber *videoHeight;
    // Main thread queue, used to ensure that video playback events are executed in order.
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
        _isStoped = NO;
        _isTerminate = NO;
        playerMainqueue = dispatch_get_main_queue();
        self.hasEnteredPipMode = NO;
        self.restoreUI = NO;
        _eventSink = [FTXPlayerEventSinkQueue new];
        _netStatusSink = [FTXPlayerEventSinkQueue new];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txvodplayer/event/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        
        _netStatusChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/txvodplayer/net/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_netStatusChannel setStreamHandler:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationTerminateClick) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void)onApplicationTerminateClick {
    _isTerminate = YES;
    _textureRegistry = nil;
    [self stopPlay];
    if (nil != _txVodPlayer) {
        [_txVodPlayer removeVideoWidget];
        _txVodPlayer = nil;
        _txVodPlayer.videoProcessDelegate = nil;
    }
    _textureId = -1;
}

- (void)notifyAppTerminate:(UIApplication *)application {
    _isTerminate = YES;
    _textureRegistry = nil;
    [self stopPlay];
    if (nil != _txVodPlayer) {
        [_txVodPlayer removeVideoWidget];
        _txVodPlayer = nil;
        _txVodPlayer.videoProcessDelegate = nil;
    }
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
        _isStoped = NO;
        return [_txVodPlayer startVodPlay:url];
    }
    return uninitialized;
}

- (int)startVodPlayWithParams:(int)appId fileId:(NSString *)fileId sign:(NSString *)sign
{
    if (_txVodPlayer != nil) {
        TXPlayerAuthParams *p = [TXPlayerAuthParams new];
        p.appId = appId;
        p.fileId = fileId;
        if (sign.length > 0) {
            p.sign = sign;
        }
        _isStoped = NO;
        return [_txVodPlayer startVodPlayWithParams:p];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (_txVodPlayer != nil) {
        _isStoped = YES;
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

- (void)setStartTime:(float)startTime
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

- (void)setPlayerImageSprite:(NSString*)urlStr withImgArray:(NSArray*)imgStrArray {
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
    if(urlStr && urlStr.length > 0) {
        vvtUrl =  [NSURL URLWithString:urlStr];
    }
    if (vvtUrl && imageUrls.count > 0) {
        [_txImageSprite setVTTUrl:vvtUrl imageUrls:imageUrls];
    }
}

- (NSData*)getPlayerImageSprite:(NSNumber*)time {
    if(_txImageSprite && [NSNull null] != (NSNull*)time) {
        UIImage *imageSprite = [_txImageSprite getThumbnail:time.floatValue];
        if(nil != imageSprite) {
            NSData *data = UIImagePNGRepresentation(imageSprite);
            return data;
        }
    } else {
        NSLog(@"getImageSprite failed, time is null or initImageSprite not invoke");
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
    return pixelBuffer;
}

#pragma mark - TXVodPlayListener

- (void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param
{
    // Hand over the first frame event timing to Flutter for shared texture processing.
    if (EvtID == CODE_ON_RECEIVE_FIRST_FRAME) {
        currentPlayTime = 0;
        NSMutableDictionary *mutableDic = param.mutableCopy;
        self->videoWidth = param[@"EVT_WIDTH"];
        self->videoHeight = param[@"EVT_HEIGHT"];
        mutableDic[@"EVT_PARAM1"] = self->videoWidth;
        mutableDic[@"EVT_PARAM2"] = self->videoHeight;
        param = mutableDic;
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
    if (EvtID != PLAY_EVT_PLAY_PROGRESS) {
        NSLog(@"onPlayEvent:%i,%@", EvtID, param[EVT_PLAY_DESCRIPTION]);
    }
    [_eventSink success:[FTXVodPlayer getParamsWithEvent:EvtID withParams:param]];
}

/**
 * Network status notification.
 *
 * @param player  VOD object.
 * @param param  See TXLiveSDKTypeDef.h.
 * @see TXVodPlayer
 */
- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary*)param
{
    [_netStatusSink success:param];
}

#pragma mark - TXVideoCustomProcessDelegate

/**
 * Video rendering object callback.
 * @param pixelBuffer   Render image.
 *                    渲染图像
 * @return Return YES to prevent the SDK from displaying; return NO to continue rendering in the SDK rendering module.
 *         返回YES则SDK不再显示；返回NO则SDK渲染模块继续渲染
 * Note: The data type of the rendered image is renderPixelFormatType set in the config.
 * 说明：渲染图像的数据类型为config中设置的renderPixelFormatType
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
            if (_isTerminate) {
                break;
            }
            old = _latestPixelBuffer;
        }

        if (old && old != pixelBuffer) {
            CFRelease(old);
        }
        if (!_isTerminate && !_isStoped && _textureRegistry && _textureId >= 0) {
            [_textureRegistry textureFrameAvailable:_textureId];
        }
    }
    
    return NO;
}

#pragma mark - Private Method

/**
 Check if the current language is Simplified Chinese.
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

- (void)setPlayerConfig:(FTXVodPlayConfigPlayerMsg *)args
{
    if (_txVodPlayer != nil && args != nil) {
        _txVodPlayer.config = [FTXTransformation transformMsgToVodConfig:args];
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
        // Set the size to 1 pixel to ensure proper display in PIP.
        _txPipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        _txPipView.hidden = YES;
    }
    return _txPipView;
}

#pragma mark - PIP delegate
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

- (void)onPlayer:(TXVodPlayer *)player airPlayErrorDidOccur:(TX_VOD_PLAYER_AIRPLAY_ERROR_TYPE)errorType withParam:(NSDictionary *)param {
}


- (void)onPlayer:(TXVodPlayer *)player airPlayStateDidChange:(TX_VOD_PLAYER_AIRPLAY_STATE)airPlayState withParam:(NSDictionary *)param {
}



#pragma mark - Convert UIImage to CVPixelBufferRef

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

// Check alpha value
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

#pragma mark - TXFlutterVodPlayerApi

- (nullable BoolMsg *)enableHardwareDecodeEnable:(nonnull BoolPlayerMsg *)enable error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    bool res = [self enableHardwareDecode:enable.value];
    return [TXCommonUtil boolMsgWith:res];
}

- (nullable IntMsg *)enterPictureInPictureModePipParamsMsg:(nonnull PipParamsPlayerMsg *)pipParamsMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int res = [self enterPictureInPictureMode];
    return [TXCommonUtil intMsgWith:@(res)];
}

- (void)exitPictureInPictureModePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if(_txVodPlayer != nil) {
        [_txVodPlayer exitPictureInPicture];
    }
}

- (nullable IntMsg *)getBitrateIndexPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    long index = [self getBitrateIndex];
    return [TXCommonUtil intMsgWith:@(index)];
}

- (nullable DoubleMsg *)getBufferDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // FlutterMethodNotImplemented
    return nil;
}

- (nullable DoubleMsg *)getCurrentPlaybackTimePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    float time = [self getCurrentPlaybackTime];
    return [TXCommonUtil doubleMsgWith:time];
}

- (nullable DoubleMsg *)getDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    float time = [self getDuration];
    return [TXCommonUtil doubleMsgWith:time];
}

- (nullable IntMsg *)getHeightPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int height = [self getHeight];
    return [TXCommonUtil intMsgWith:@(height)];
}

- (nullable UInt8ListMsg *)getImageSpriteTime:(nonnull DoublePlayerMsg *)time error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSData *data = [self getPlayerImageSprite:time.value];
    return [TXCommonUtil uInt8MsgWith:data];
}

- (nullable DoubleMsg *)getPlayableDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    float time = [self getPlayableDuration];
    return [TXCommonUtil doubleMsgWith:time];
}

- (nullable ListMsg *)getSupportedBitratePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSArray *supportedBitrates = [self supportedBitrates];
    ListMsg *msg = [[ListMsg alloc] init];
    msg.value = supportedBitrates;
    return msg;
}

- (nullable IntMsg *)getWidthPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int width = [self getWidth];
    return [TXCommonUtil intMsgWith:@(width)];
}

- (void)initImageSpriteSpriteInfo:(nonnull StringListPlayerMsg *)spriteInfo error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setPlayerImageSprite:spriteInfo.vvtUrl withImgArray:spriteInfo.imageUrls];
}

- (nullable IntMsg *)initializeOnlyAudio:(nonnull BoolPlayerMsg *)onlyAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber* textureId = [self createPlayer:onlyAudio.value.boolValue];
    return [TXCommonUtil intMsgWith:textureId];
}

- (nullable BoolMsg *)isLoopPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [TXCommonUtil boolMsgWith:[self isLoop]];
}

- (nullable BoolMsg *)isPlayingPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [TXCommonUtil boolMsgWith:[self isPlaying]];
}

- (void)pausePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self pause];
}

- (void)resumePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self resume];
}

- (void)seekProgress:(nonnull DoublePlayerMsg *)progress error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self seek:progress.value.floatValue];
}

- (void)setAudioPlayOutVolumeVolume:(nonnull IntPlayerMsg *)volume error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setAudioPlayoutVolume:volume.value.intValue];
}

- (void)setAutoPlayIsAutoPlay:(nonnull BoolPlayerMsg *)isAutoPlay error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setIsAutoPlay:isAutoPlay.value.boolValue];
}

- (void)setBitrateIndexIndex:(nonnull IntPlayerMsg *)index error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setBitrateIndex:index.value.intValue];
}

- (void)setConfigConfig:(nonnull FTXVodPlayConfigPlayerMsg *)config error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setPlayerConfig:config];
}

- (void)setLoopLoop:(nonnull BoolPlayerMsg *)loop error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setLoop:loop.value.boolValue];
}

- (void)setMuteMute:(nonnull BoolPlayerMsg *)mute error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setMute:mute.value.boolValue];
}

- (void)setRateRate:(nonnull DoublePlayerMsg *)rate error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setRate:rate.value.doubleValue];
}

- (nullable BoolMsg *)setRequestAudioFocusFocus:(nonnull BoolPlayerMsg *)focus error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // FlutterMethodNotImplemented
    return [TXCommonUtil boolMsgWith:YES];
}

- (void)setStartTimeStartTime:(nonnull DoublePlayerMsg *)startTime error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setStartTime:startTime.value.floatValue];
}

- (void)setTokenToken:(nonnull StringPlayerMsg *)token error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setToken:token.value];
}

- (nullable BoolMsg *)startVodPlayUrl:(nonnull StringPlayerMsg *)url error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self startVodPlay:url.value];
    return [TXCommonUtil boolMsgWith:r];
}

- (void)startVodPlayWithParamsParams:(nonnull TXPlayInfoParamsPlayerMsg *)params error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self startVodPlayWithParams:params.appId.unsignedIntValue fileId:params.fileId sign:params.psign];
}

- (nullable BoolMsg *)stopIsNeedClear:(nonnull BoolPlayerMsg *)isNeedClear error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    BOOL r = [self stopPlay];
    return [TXCommonUtil boolMsgWith:r];
}

@end
