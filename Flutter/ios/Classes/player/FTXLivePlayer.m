// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXLivePlayer.h"
#import "FTXTransformation.h"
#import "FTXLiteAVSDKHeader.h"
#import <Flutter/Flutter.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import "FtxMessages.h"
#import "TXCommonUtil.h"
#import "FTXLog.h"
#import <stdatomic.h>
#import "FTXV2LiveTools.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <FTXPiPKit/FTXPipController.h>
#import "FTXImgTools.h"
#import "FTXTextureView.h"

static const int uninitialized = -1;

@interface FTXLivePlayer ()<V2TXLivePlayerObserver, TXFlutterLivePlayerApi, FTXLivePipDelegate, FTXPipPlayerDelegate>

@property (nonatomic, strong) V2TXLivePlayer *livePlayer;
@property (nonatomic, assign) int lastPlayEvent;
@property (nonatomic, assign) BOOL isOpenedPip;
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, strong) TXLivePlayerFlutterAPI* liveFlutterApi;
@property (nonatomic, assign) BOOL hasEnteredPipMode;
@property (nonatomic, assign) BOOL isStartEnterPipMode;
@property (nonatomic, assign) BOOL restoreUI;
@property (nonatomic, assign) CGSize liveSize;
@property (nonatomic, assign) BOOL isMute;
@property (nonatomic, strong) FTXRenderViewFactory* renderViewFactory;
@property (nonatomic, strong) FTXRenderView *curRenderView;

@end

@implementation FTXLivePlayer {
    id<FlutterPluginRegistrar> _registrar;
    BOOL _isTerminate;
    BOOL _isStoped;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar renderViewFactory:(FTXRenderViewFactory*)renderViewFactory onlyAudio:(BOOL)onlyAudio
{
    if (self = [self init]) {
        _registrar = registrar;
        _isTerminate = NO;
        _isStoped = NO;
        self.curRenderView = nil;
        self.renderViewFactory = renderViewFactory;
        self.isOpenedPip = NO;
        self.lastPlayEvent = -1;
        self.hasEnteredPipMode = NO;
        self.isStartEnterPipMode = NO;
        self.restoreUI = NO;
        self.liveSize = CGSizeZero;
        self.isMute = NO;
        SetUpTXFlutterLivePlayerApiWithSuffix([registrar messenger], self, [self.playerId stringValue]);
        self.liveFlutterApi = [[TXLivePlayerFlutterAPI alloc] initWithBinaryMessenger:[registrar messenger] messageChannelSuffix:[self.playerId stringValue]];
        [self createPlayer:onlyAudio];
    }
    return self;
}

- (void)destory
{
    FTXLOGV(@"livePlayer start called destory");
    [self stopPlay];
    if (nil != self.livePlayer) {
        [self.livePlayer enableObserveVideoFrame:NO pixelFormat:V2TXLivePixelFormatBGRA32 bufferType:V2TXLiveBufferTypePixelBuffer];
        [self setRenderView:nil];
        [self.livePlayer setObserver:nil];
    }
    self.curRenderView = nil;
}

- (void)notifyAppTerminate:(UIApplication *)application {
    if (!_isTerminate) {
        FTXLOGW(@"livePlayer is called notifyAppTerminate terminate");
        [self notifyPlayerTerminate];
    }
}

- (void)dealloc
{
    if (!_isTerminate) {
        FTXLOGW(@"livePlayer is called delloc terminate");
        [self notifyPlayerTerminate];
    }
}

- (void)notifyPlayerTerminate {
    FTXLOGW(@"livePlayer notifyPlayerTerminate");
    if (nil != self.livePlayer) {
        [self.livePlayer enableObserveVideoFrame:NO pixelFormat:V2TXLivePixelFormatBGRA32 bufferType:V2TXLiveBufferTypePixelBuffer];
        [self setRenderView:nil];
        [self.livePlayer setObserver:nil];
    }
    self.curRenderView = nil;
    _isTerminate = YES;
    [self stopPlay];
    self.livePlayer = nil;
}

- (void)setupPlayerWithBool:(BOOL)onlyAudio
{
    if (!onlyAudio) {
        if (nil != self.livePlayer) {
            // 只有自定义渲染才能让直播画中画在后台输出画面
            [self.livePlayer enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatBGRA32 bufferType:V2TXLiveBufferTypePixelBuffer];
            [self.livePlayer setProperty:@"enableBackgroundDecoding" value:@(YES)];
            if (nil != self.curRenderView) {
                [self.curRenderView setPlayer:self];
            }
        }
    }
}

#pragma mark - private method

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
    // must create new obj when evey called
    return [FTXImgTools CVPixelBufferRefFromUiImage:image];
}


- (NSNumber*)createPlayer:(BOOL)onlyAudio
{
    if (nil == self.livePlayer) {
        self.livePlayer = [V2TXLivePlayer new];
        [self.livePlayer setObserver:self];
        [self.livePlayer setRenderFillMode:V2TXLiveFillModeScaleFill];
        [self setupPlayerWithBool:onlyAudio];
    }
    return NO_ERROR;
}

- (UIViewController *)getFlutterViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *w in windowScene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
                if (window != nil) {
                    break;
                }
            }
        }
    } else {
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) {
                window = w;
                break;
            }
        }
    }
    return window.rootViewController;
}


- (void)setRenderRotation:(int)rotation
{
    if (self.livePlayer != nil) {
        [self.livePlayer setRenderRotation:[FTXV2LiveTools transRotationFromDegree:rotation]];
    }
}

- (int)switchStream:(NSString *)url
{
    if (self.livePlayer != nil) {
        return (int)[self.livePlayer switchStream:url];
    }
    return -1;
}

- (int)startLivePlay:(NSString *)url
{
    if (self.livePlayer != nil) {
        _isStoped = NO;
        [self.livePlayer resumeVideo];
        if (!self.isMute) {
            [self.livePlayer resumeAudio];
        }
        self.lastPlayEvent = -1;
        self.isPaused = NO;
        self.liveSize = CGSizeZero;
        return (int)[self.livePlayer startLivePlay:url];
    }
    return uninitialized;
}

- (BOOL)stopPlay
{
    if (self.livePlayer != nil) {
        _isStoped = YES;
        self.lastPlayEvent = -1;
        self.isPaused = NO;
        self.liveSize = CGSizeZero;
        if (self.hasEnteredPipMode) {
            [[FTXPipController shareInstance] exitPip];
        }
        return [self.livePlayer stopPlay];
    }
    return NO;
}

- (BOOL)isPlaying
{
    if (self.livePlayer != nil) {
        return self.isPaused;
    }
    return NO;
}

- (void)pause
{
    if (self.hasEnteredPipMode) {
        [[FTXPipController shareInstance] pausePipVideo];
    } else {
        [self pauseImpl];
    }
}

- (void)pauseImpl {
    if (self.livePlayer != nil) {
        [self.livePlayer pauseVideo];
        [self.livePlayer pauseAudio];
        self.isPaused = YES;
    }
}

- (void)resume
{
    if (self.hasEnteredPipMode) {
        [[FTXPipController shareInstance] resumePipVideo];
    } else {
        [self resumeImpl];
    }
}

- (void)resumeImpl {
    if (self.livePlayer != nil) {
        [self.livePlayer resumeVideo];
        if (!self.isMute) {
            [self.livePlayer resumeAudio];
        }
        self.isPaused = NO;
        int evtID = PLAY_EVT_PLAY_BEGIN;
        __block NSMutableDictionary *param = @{}.mutableCopy;
        [self notifyPlayerEvent:evtID withParams:param];
        FTXLOGI(@"onLivePlayEvent:%i,%@", evtID, param[EVT_PLAY_DESCRIPTION])
    }
}

- (void)setMute:(BOOL)bEnable
{
    if (self.livePlayer != nil) {
        self.isMute = bEnable;
        if (bEnable) {
            [self.livePlayer pauseAudio];
        } else if (!self.isPaused) {
            [self.livePlayer resumeAudio];
        }
    }
}

- (void)setVolume:(int)volume
{
    if (self.livePlayer != nil) {
        [self.livePlayer setPlayoutVolume:volume];
    }
}

- (void)setLiveMode:(int)type
{
    if (type == 0) {
        // Auto mode.
        [self.livePlayer setCacheParams:1 maxTime:5];
    }else if(type == 1){
        // Ultra-fast mode.
        [self.livePlayer setCacheParams:1 maxTime:1];
    }else{
        // Smooth mode.
        [self.livePlayer setCacheParams:5 maxTime:5];
    }
}

- (void)setAppID:(NSString *)appId
{
    [TXLiveBase setAppID:appId];
}

- (void)setRenderMode:(int)renderMode {
    if (self.livePlayer != nil) {
        [self.livePlayer setRenderFillMode:renderMode];
    }
}

- (BOOL)enableHardwareDecode:(BOOL)enable {
    // live auto handle this in v2 live player
    return false;
}

- (void)setPlayerConfig:(FTXLivePlayConfigPlayerMsg *)msg
{
    if (self.livePlayer != nil) {
        if (msg) {
            if (msg.minAutoAdjustCacheTime != nil && msg.maxAutoAdjustCacheTime != nil) {
                [self.livePlayer setCacheParams:[msg.minAutoAdjustCacheTime floatValue]
                                        maxTime:[msg.maxAutoAdjustCacheTime floatValue]];
            }
            if (msg.connectRetryCount) {
                [self.livePlayer setProperty:kV2MaxNumberOfReconnection value:msg.connectRetryCount];
            }
            if (msg.connectRetryInterval) {
                [self.livePlayer setProperty:kV2SecondsBetweenReconnection value:msg.connectRetryInterval];
            }
        }
    }
}

- (NSDictionary *)getLiveParamsWithEvent:(int)evtID withParams:(NSDictionary *)params {
    NSMutableDictionary<NSString*,NSObject*> *dict = [TXCommonUtil getParamsWithEvent:evtID withParams:params];
    long long timestamp = [self currentMillisecondTime];
    [dict setObject:@(timestamp) forKey:EVT_TIME];
    return dict;
}

- (long long)currentMillisecondTime {
    NSDate *now = [NSDate date]; // 获取当前日期时间
    NSTimeInterval timeInterval = [now timeIntervalSince1970]; // 获取距离1970年的秒数
    long long millisecondTime = (long long)(timeInterval * 1000); // 将秒数转换为毫秒数
    return millisecondTime;
}

- (void)notifyPlayerEvent:(int)evtID withParams:(NSDictionary *)params {
    self.lastPlayEvent = evtID;
    [self.liveFlutterApi onPlayerEventEvent:[self getLiveParamsWithEvent:evtID withParams:params] completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
    FTXLOGI(@"onLivePlayEvent:%i,%@", evtID, params[EVT_MSG])
}

- (NSNumber*)enablePictureInPicture:(BOOL)isEnabled {
    if (self.livePlayer) {
        if (isEnabled != self.isOpenedPip) {
            self.isOpenedPip = isEnabled;
            int result = (int)[self.livePlayer enablePictureInPicture:isEnabled];
            return @(result);
        }
    }
    return @(uninitialized);
}

#pragma mark - TXFlutterLivePlayerApi

- (nullable BoolMsg *)enableHardwareDecodeEnable:(nonnull BoolPlayerMsg *)enable error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self enableHardwareDecode:enable.value];
    return [TXCommonUtil boolMsgWith:r];
}

- (nullable IntMsg *)enterPictureInPictureModePipParamsMsg:(nonnull PipParamsPlayerMsg *)pipParamsMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if (self.liveSize.width <= 0 || self.liveSize.height <= 0) {
        FTXLOGE(@"live pip opened failed, size is invalid");
        return [TXCommonUtil intMsgWith:@(ERROR_IOS_PIP_PLAYER_NOT_EXIST)];
    }
    UIView* renderView = nil;
    if (nil != self.curRenderView) {
        renderView = [self.curRenderView view];
    }
    int retCode = [[FTXPipController shareInstance] startOpenPip:self.livePlayer withView:renderView withSize:self.liveSize];
    if (retCode == NO_ERROR) {
        [FTXPipController shareInstance].pipDelegate = self;
        [FTXPipController shareInstance].playerDelegate = self;
        self.isStartEnterPipMode = YES;
    }
    return [TXCommonUtil intMsgWith:@(retCode)];
}

- (void)exitPictureInPictureModePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if (self.hasEnteredPipMode) {
        [[FTXPipController shareInstance] exitPip];
    }
}

- (nullable IntMsg *)initializeOnlyAudio:(nonnull BoolPlayerMsg *)onlyAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber* textureId = [self createPlayer:onlyAudio.value.boolValue];
    return [TXCommonUtil intMsgWith:textureId];
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

- (nullable BoolMsg *)stopIsNeedClear:(nonnull BoolPlayerMsg *)isNeedClear error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if (self.livePlayer) {
        [self.livePlayer setProperty:kV2ClearLastImage value:@(isNeedClear.value.boolValue)];
    }
    BOOL r = [self stopPlay];
    return [TXCommonUtil boolMsgWith:r];
}

- (nullable IntMsg *)switchStreamUrl:(nonnull StringPlayerMsg *)url error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int r = [self switchStream:url.value];
    return [TXCommonUtil intMsgWith:@(r)];
}

- (nullable NSNumber *)enablePictureInPictureMsg:(nonnull BoolPlayerMsg *)msg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [self enablePictureInPicture:[msg.value boolValue]];
}

- (NSNumber *)enableReceiveSeiMessagePlayerMsg:(PlayerMsg *)playerMsg isEnabled:(BOOL)isEnabled payloadType:(NSInteger)payloadType error:(FlutterError * _Nullable __autoreleasing *)error {
    
    if (self.livePlayer) {
        int result = (int)[self.livePlayer enableReceiveSeiMessage:isEnabled payloadType:(int)payloadType];
        return @(result);
    }
    return @(uninitialized);
}


- (nullable ListMsg *)getSupportedBitratePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    if (self.livePlayer) {
        NSArray *result = [self.livePlayer getStreamList];
        return [TXCommonUtil listMsgWith:result];
    }
    return [TXCommonUtil listMsgWith:@[]];
}


- (NSNumber *)setCacheParamsPlayerMsg:(PlayerMsg *)playerMsg minTime:(double)minTime maxTime:(double)maxTime error:(FlutterError * _Nullable __autoreleasing *)error {
    if (self.livePlayer) {
        int result = (int)[self.livePlayer setCacheParams:minTime maxTime:maxTime];
        return @(result);
    }
    return @(uninitialized);
}


- (nullable NSNumber *)setPropertyPlayerMsg:(nonnull PlayerMsg *)playerMsg key:(nonnull NSString *)key value:(nonnull id)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    if (self.livePlayer) {
        int result = (int)[self.livePlayer setProperty:key value:value];
        return @(result);
    }
    return @(uninitialized);
}


- (void)showDebugViewPlayerMsg:(PlayerMsg *)playerMsg isShow:(BOOL)isShow error:(FlutterError * _Nullable __autoreleasing *)error {
    if (self.livePlayer) {
        [self.livePlayer showDebugView:isShow];
    }
}

- (nullable BoolMsg *)startLivePlayPlayerMsg:(nonnull StringPlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    int r = [self startLivePlay:playerMsg.value];
    return [TXCommonUtil boolMsgWith:r];
}

- (void)setPlayerViewRenderViewId:(NSInteger)renderViewId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    FTXRenderView *renderView = [self.renderViewFactory findViewById:renderViewId];
    if (nil != renderView) {
        self.curRenderView = renderView;
        [renderView setPlayer:self];
    } else {
        self.curRenderView = nil;
        [self setRenderView:nil];
        FTXLOGE(@"setPlayerView can not find renderView by id: %ld, release player's renderView", renderViewId);
    }
}

- (void)setRenderView:(FTXTextureView *)renderView {
    if (nil != self.livePlayer) {
        if (nil != renderView) {
            [self.livePlayer setRenderView:renderView];
        } else {
            self.renderControl = nil;
        }
    }
}


#pragma mark - V2TXLivePlayerObserver

- (void)onError:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    int evtID = (int)code;
    __block NSMutableDictionary *param = @{
        EVT_MSG : msg,
    }.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 直播播放器警告通知
 *
 * @param player    回调该通知的播放器对象。
 * @param code      警告码 {@link V2TXLiveCode}。
 * @param msg       警告信息。
 * @param extraInfo 扩展信息。
 */
- (void)onWarning:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    int evtID = (int)code;
    __block NSMutableDictionary *param = @{
        EVT_MSG : msg,
    }.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 直播播放器分辨率变化通知
 *
 * @param player    回调该通知的播放器对象。
 * @param width     视频宽。
 * @param height    视频高。
 */
- (void)onVideoResolutionChanged:(id<V2TXLivePlayer>)player width:(NSInteger)width height:(NSInteger)height {
    int evtID = PLAY_EVT_CHANGE_RESOLUTION;
    __block NSDictionary *param = @{
        EVT_KEY_PLAYER_WIDTH : @(width),
        EVT_KEY_PLAYER_HEIGHT : @(height),
        EVT_PARAM1 : @(width),
        EVT_PARAM2 : @(height),
        EVT_MSG : [NSString stringWithFormat:@"Resolution changed. resolution:%ldx%ld", (long)width, (long)height]
    };
    self.liveSize = CGSizeMake(width, height);
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 已经成功连接到服务器
 *
 * @param player    回调该通知的播放器对象。
 * @param extraInfo 扩展信息。
 */
- (void)onConnected:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    int evtID = PLAY_EVT_CONNECT_SUCC;
    __block NSMutableDictionary *param = @{}.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 视频播放事件
 *
 * @param player    回调该通知的播放器对象。
 * @param firstPlay 第一次播放标志。
 * @param extraInfo 扩展信息。
 */
- (void)onVideoPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    // loading
    if (self.lastPlayEvent == PLAY_EVT_PLAY_LOADING) {
        int evtID = PLAY_EVT_VOD_LOADING_END;
        __block NSMutableDictionary *param = @{}.mutableCopy;
        [param addEntriesFromDictionary:extraInfo];
        [self notifyPlayerEvent:evtID withParams:param];
    }
    // begin
    {
        int evtID = PLAY_EVT_PLAY_BEGIN;
        __block NSMutableDictionary *param = @{}.mutableCopy;
        [param addEntriesFromDictionary:extraInfo];
        [self notifyPlayerEvent:evtID withParams:param];
    }
    // first frame
    if (firstPlay) {
        int evtID = VOD_PLAY_EVT_RCV_FIRST_I_FRAME;
        __block NSMutableDictionary *param = @{}.mutableCopy;
        [param addEntriesFromDictionary:extraInfo];
        [self notifyPlayerEvent:evtID withParams:param];
    }
}

/**
 * 音频播放事件
 *
 * @param player    回调该通知的播放器对象。
 * @param firstPlay 第一次播放标志。
 * @param extraInfo 扩展信息。
 */
- (void)onAudioPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    int evtID = PLAY_EVT_RCV_FIRST_AUDIO_FRAME;
    __block NSMutableDictionary *param = @{}.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 视频加载事件
 *
 * @param player    回调该通知的播放器对象。
 * @param extraInfo 扩展信息。
 */
- (void)onVideoLoading:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    int evtID = PLAY_EVT_PLAY_LOADING;
    __block NSMutableDictionary *param = @{}.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 音频加载事件
 *
 * @param player    回调该通知的播放器对象。
 * @param extraInfo 扩展信息。
 */
- (void)onAudioLoading:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    int evtID = PLAY_EVT_PLAY_LOADING;
    __block NSMutableDictionary *param = @{}.mutableCopy;
    [param addEntriesFromDictionary:extraInfo];
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 播放器音量大小回调
 *
 * @param player 回调该通知的播放器对象。
 * @param volume 音量大小。
 * @note  调用 {@link enableVolumeEvaluation} 开启播放音量大小提示之后，会收到这个回调通知。
 */
- (void)onPlayoutVolumeUpdate:(id<V2TXLivePlayer>)player volume:(NSInteger)volume {
    
}

/**
 * 直播播放器统计数据回调
 *
 * @param player     回调该通知的播放器对象。
 * @param statistics 播放器统计数据 {@link V2TXLivePlayerStatistics}。
 */
- (void)onStatisticsUpdate:(id<V2TXLivePlayer>)player statistics:(V2TXLivePlayerStatistics *)statistics {
    NSDictionary *param = [FTXV2LiveTools buildNetBundle:statistics];
    [self.liveFlutterApi onNetEventEvent:param completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

/**
 * 截图回调
 *
 * @note  调用 {@link snapshot} 截图之后，会收到这个回调通知。
 * @param player 回调该通知的播放器对象。
 * @param image  已截取的视频画面。
 */
- (void)onSnapshotComplete:(id<V2TXLivePlayer>)player image:(nullable TXImage *)image {
    
}

/**
 *  Note: The data type of the rendered image is the `renderPixelFormatType` set in the configuration.
 *  说明：渲染图像的数据类型为config中设置的renderPixelFormatType
 *
 * 自定义视频渲染回调
 *
 * @param player     回调该通知的播放器对象。
 * @param videoFrame 视频帧数据 {@link V2TXLiveVideoFrame}。
 * @note  需要您调用 {@link enableObserveVideoFrame} 开启回调开关。
 */
- (void)onRenderVideoFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveVideoFrame *)videoFrame {
    if (self.isStartEnterPipMode) {
        [[FTXPipController shareInstance] displayPixelBuffer:videoFrame.pixelBuffer];
    }
}

/**
 * 音频数据回调
 *
 * @param player     回调该通知的播放器对象。
 * @param audioFrame 音频帧数据 {@link V2TXLiveAudioFrame}。
 * @note  需要您调用 {@link enableObserveAudioFrame} 开启回调开关。请在当前回调中使用 audioFrame 的 data。
 */
- (void)onPlayoutAudioFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveAudioFrame *)audioFrame {
    
}

/**
 * 收到 SEI 消息的回调，发送端通过 {@link V2TXLivePusher} 中的 `sendSeiMessage` 来发送 SEI 消息
 *
 * @note  调用 {@link V2TXLivePlayer} 中的 `enableReceiveSeiMessage` 开启接收 SEI 消息之后，会收到这个回调通知。
 * @param player         回调该通知的播放器对象。
 * @param payloadType    回调数据的SEI payloadType。
 * @param data           数据。
 */
- (void)onReceiveSeiMessage:(id<V2TXLivePlayer>)player payloadType:(int)payloadType data:(NSData *)data {
    int evtID = VOD_PLAY_EVT_GET_MESSAGE;
    __block NSDictionary *param = @{
        EVT_GET_MSG : data,
        EVT_GET_MSG_TYPE : @(payloadType)
    };
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 分辨率无缝切换回调
 *
 * @note  调用 {@link V2TXLivePlayer} 中的 `switchStream` 切换分辨率，会收到这个回调通知。
 * @param player 回调该通知的播放器对象。
 * @param url    切换的播放地址。
 * @param code   状态码，0：成功，-1：切换超时，-2：切换失败，服务端错误，-3：切换失败，客户端错误。
 */
- (void)onStreamSwitched:(id<V2TXLivePlayer>)player url:(NSString *)url code:(NSInteger)code {
    int evtID = PLAY_EVT_STREAM_SWITCH_SUCC;
    NSString *msg = @"Switch stream success.";
    if (code != 0) {
        evtID = PLAY_ERR_STREAM_SWITCH_FAIL;
        msg = @"Switch stream failed.";
    }
    __block NSDictionary *param = @{
        EVT_MSG : msg
    };
    [self notifyPlayerEvent:evtID withParams:param];
}

/**
 * 画中画状态变更回调
 *
 * @note  调用 {@link V2TXLivePlayer} 中的 `enablePictureInPicture` 开启画中画之后，会收到这个回调通知。
 * @param player    回调该通知的播放器对象。
 * @param state     画中画的状态。
 * @param extraInfo 扩展信息。
 */
- (void)onPictureInPictureStateUpdate:(id<V2TXLivePlayer>)player state:(V2TXLivePictureInPictureState)state 
                              message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    
}

/**
 * 录制任务开始的事件回调
 * 开始录制任务时，SDK 会抛出该事件回调，用于通知您录制任务是否已经顺利启动。对应于 {@link startLocalRecording} 接口。
 *
 * @param player 回调该通知的播放器对象。
 * @param code 状态码。
 *               - 0：录制任务启动成功。
 *               - -1：内部错误导致录制任务启动失败。
 *               - -2：文件后缀名有误（比如不支持的录制格式）。
 *               - -6：录制已经启动，需要先停止录制。
 *               - -7：录制文件已存在，需要先删除文件。
 *               - -8：录制目录无写入权限，请检查目录权限问题。
 * @param storagePath 录制的文件地址。
 */
- (void)onLocalRecordBegin:(id<V2TXLivePlayer>)player errCode:(NSInteger)errCode storagePath:(NSString *)storagePath {
    
}

/**
 * 录制任务正在进行中的进展事件回调
 * 当您调用 {@link startLocalRecording} 成功启动本地媒体录制任务后，SDK 变会按一定间隔抛出本事件回调，【默认】：不抛出本事件回调。
 * 您可以在 {@link startLocalRecording} 时，设定本事件回调的抛出间隔参数。
 *
 * @param player       回调该通知的播放器对象。
 * @param durationMs   录制时长。
 * @param storagePath  录制的文件地址。
 */
- (void)onLocalRecording:(id<V2TXLivePlayer>)player durationMs:(NSInteger)durationMs storagePath:(NSString *)storagePath {
    
}

/**
 * 录制任务已经结束的事件回调
 * 停止录制任务时，SDK 会抛出该事件回调，用于通知您录制任务的最终结果。对应于 {@link stopLocalRecording} 接口。
 *
 * @param player 回调该通知的播放器对象。
 * @param code 状态码。
 *               -  0：结束录制任务成功。
 *               - -1：录制失败。
 *               - -2：切换分辨率或横竖屏导致录制结束。
 *               - -3：录制时间太短，或未采集到任何视频或音频数据，请检查录制时长，或是否已开启音、视频采集。
 * @param storagePath 录制的文件地址。
 */
- (void)onLocalRecordComplete:(id<V2TXLivePlayer>)player errCode:(NSInteger)errCode storagePath:(NSString *)storagePath {
}

#pragma mark - FTXLivePipDelegate

- (void)pictureInPictureErrorDidOccur:(FTX_LIVE_PIP_ERROR)errorStatus { 
    NSInteger type = errorStatus;
    switch (errorStatus) {
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_NONE:
            type = NO_ERROR;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_DEVICE_NOT_SUPPORT:
            type = ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_SUPPORT:
            type = ERROR_IOS_PIP_PLAYER_NOT_SUPPORT;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_VIDEO_NOT_SUPPORT:
            type = ERROR_IOS_PIP_VIDEO_NOT_SUPPORT;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_NOT_POSSIBLE:
            type = ERROR_IOS_PIP_IS_NOT_POSSIBLE;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_ERROR_FROM_SYSTEM:
            type = ERROR_IOS_PIP_FROM_SYSTEM;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PLAYER_NOT_EXIST:
            type = ERROR_IOS_PIP_PLAYER_NOT_EXIST;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_RUNNING:
            type = ERROR_IOS_PIP_IS_RUNNING;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_NOT_RUNNING:
            type = ERROR_IOS_PIP_NOT_RUNNING;
            break;
        case FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_START_TIMEOUT:
            type = ERROR_IOS_PIP_START_TIME_OUT;
            break;
        default:
            type = errorStatus;
            break;
    }
    self.hasEnteredPipMode = NO;
    self.isStartEnterPipMode = NO;
    FTXLOGE(@"[onPlayer], pictureInPictureErrorDidOccur errorType= %ld", type);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateError:)]) {
        [self.delegate onPlayerPipStateError:type];
    }
}

- (void)pictureInPictureStateDidChange:(TX_VOD_PLAYER_PIP_STATE)pipState {
    if (pipState == TX_VOD_PLAYER_PIP_STATE_DID_START) {
        self.hasEnteredPipMode = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateDidStart)]) {
            [self.delegate onPlayerPipStateDidStart];
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_WILL_STOP) {
        self.isStartEnterPipMode = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateWillStop)]) {
            [self.delegate onPlayerPipStateWillStop];
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_DID_STOP) {
        self.hasEnteredPipMode = NO;
        [[FTXPipController shareInstance] exitPip];
        if (self.restoreUI) {
            self.restoreUI = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateDidStop)]) {
                    [self.delegate onPlayerPipStateDidStop];
                }
            });
        }
    }
    
    if (pipState == TX_VOD_PLAYER_PIP_STATE_RESTORE_UI) {
        self.restoreUI = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resume];
            if (self.curRenderView) {
                [self setRenderView:[self.curRenderView getRenderView]];
            }
        });
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerPipStateRestoreUI:)]) {
            [self.delegate onPlayerPipStateRestoreUI:0];
        }
    }
    self.isStartEnterPipMode = self.hasEnteredPipMode;
}

- (void)playerStateDidChange:(FTXAVPlayerState)playerState {
    if (playerState == FTXAVPlayerStatePlaying) {
        [self resumeImpl];
    }
}

@end
