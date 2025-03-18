// Copyright (c) 2022 Tencent. All rights reserved.
#import "SuperPlayerPlugin.h"
#import "FTXLivePlayer.h"
#import "FTXVodPlayer.h"
#import "FTXTransformation.h"
#import "FTXEvent.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FTXLiteAVSDKHeader.h"
#import "FTXAudioManager.h"
#import "FTXDownloadManager.h"
#import "FtxMessages.h"
#import "FTXLog.h"
#import "FTXRenderViewFactory.h"
#import "FTXPiPKit/FTXPipConstants.h"

@interface SuperPlayerPlugin ()<FTXVodPlayerDelegate,TXFlutterSuperPlayerPluginAPI,TXFlutterNativeAPI, FlutterPlugin, TXLiveBaseDelegate>

@property (nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) FTXDownloadManager* fTXDownloadManager;
@property (nonatomic, strong) FTXAudioManager* audioManager;
@property (nonatomic, strong) TXPluginFlutterAPI* pluginFlutterApi;
@property (nonatomic, strong) TXPipFlutterAPI* pipFlutterApi;
@property (nonatomic, strong) FTXRenderViewFactory* renderViewFactory;

@end

@implementation SuperPlayerPlugin {
    float orginBrightness;
    int mCurrentOrientation;
}

SuperPlayerPlugin* instance;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FTXLOGV(@"called registerWithRegistrar");
    instance = [[SuperPlayerPlugin alloc] initWithRegistrar:registrar];
    SetUpTXFlutterNativeAPI([registrar messenger], instance);
    SetUpTXFlutterSuperPlayerPluginAPI([registrar messenger], instance);
    [registrar addApplicationDelegate:instance];
    [TXLiveBase sharedInstance].delegate = instance;
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FTXLOGV(@"called detachFromEngineForRegistrar");
    if(nil != instance) {
        [instance destory];
    }
    if (nil != _fTXDownloadManager) {
        [_fTXDownloadManager destroy];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        [registrar publish:self];
        _registrar = registrar;
        _players = @{}.mutableCopy;
        self.pluginFlutterApi = [[TXPluginFlutterAPI alloc] initWithBinaryMessenger:[registrar messenger]];
        self.pipFlutterApi = [[TXPipFlutterAPI alloc] initWithBinaryMessenger:[registrar messenger]];
        // light componet init
        orginBrightness = [UIScreen mainScreen].brightness;
        
        // brightness event
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(brightnessDidChange:) name:UIScreenBrightnessDidChangeNotification object:[UIScreen mainScreen]];
        
        [self.audioManager registerVolumeChangeListener:self];
        _fTXDownloadManager = [[FTXDownloadManager alloc] initWithRegistrar:registrar];
        // orientation
        mCurrentOrientation = ORIENTATION_PORTRAIT_UP;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeviceOrientationChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        // renderView
        self.renderViewFactory = [[FTXRenderViewFactory alloc] initWithBinaryMessenger:registrar.messenger];
        [registrar registerViewFactory:self.renderViewFactory withId:VIEW_TYPE_FTX_RENDER_VIEW];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [self.pluginFlutterApi onNativeEventEvent:[TXCommonUtil getParamsWithEvent:EVENT_VOLUME_CHANGED withParams:@{}] completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

-(void) destory
{
    [self.audioManager destory:self];
}

-(void) setSysBrightness:(NSNumber*)brightness {
    FTXLOGV(@"called setSysBrightness,%@", brightness);
    if(brightness.floatValue > 1.0) {
        brightness = [NSNumber numberWithFloat:1.0];
    }
    if(brightness.intValue != -1 && brightness.floatValue < 0) {
        brightness = [NSNumber numberWithFloat:0.01];
    }
    if(brightness.intValue == -1) {
        [[UIScreen mainScreen] setBrightness:orginBrightness];
    } else {
        [[UIScreen mainScreen] setBrightness:brightness.floatValue];
    }
}

-(void) releasePlayerInner:(NSNumber*)playerId {
    FTXLOGV(@"called releasePlayerInner,%@ is start release", playerId);
    FTXBasePlayer *player = [_players objectForKey:playerId];
    if (player != nil) {
        FTXLOGI(@"releasePlayer start destroy player :%@", playerId);
        [player destory];
        [_players removeObjectForKey:playerId];
    }
}

- (FTXAudioManager *)audioManager {
    if (!self->_audioManager) {
        self->_audioManager = [[FTXAudioManager alloc] init];
    }
    return self->_audioManager;
}

/**
 Brightness change.
 */
- (void)brightnessDidChange:(NSNotification *)notification
{
    [self.pluginFlutterApi onNativeEventEvent:[TXCommonUtil getParamsWithEvent:EVENT_BRIGHTNESS_CHANGED withParams:@{}] completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

#pragma mark - FlutterPlugin

- (void)applicationWillTerminate:(UIApplication *)application {
    FTXLOGV(@"called applicationWillTerminate");
    for(id key in self.players) {
        id player = self.players[key];
        if([player respondsToSelector:@selector(notifyAppTerminate:)]) {
            [player notifyAppTerminate:application];
        }
    }
    if (nil != _fTXDownloadManager) {
        [_fTXDownloadManager destroy];
    }
}




#pragma mark - FTXVodPlayerDelegate

- (void)onPlayerPipRequestStart {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(EVENT_PIP_MODE_REQUEST_START)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onPlayerPipStateDidStart {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(EVENT_PIP_MODE_ALREADY_ENTER)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onPlayerPipStateWillStop {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(EVENT_PIP_MODE_WILL_EXIT)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onPlayerPipStateDidStop {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(EVENT_PIP_MODE_ALREADY_EXIT)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onPlayerPipStateError:(NSInteger)errorId {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(errorId)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onPlayerPipStateRestoreUI:(double)playTime {
    [self.pipFlutterApi onPipEventEvent:@{@"event" : @(EVENT_PIP_MODE_RESTORE_UI), EVENT_PIP_PLAY_TIME : @(playTime)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

#pragma mark - orientation

- (void)onDeviceOrientationChange:(NSNotification *)notification {
    // For iOS, there is no need to check whether the auto screen rotation/vertical screen lock switch is turned on.
    // When the lock is turned on in iOS, the callback cannot be received by default.
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    int tempOrientationCode = mCurrentOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            // Battery bar on top.
            tempOrientationCode = ORIENTATION_PORTRAIT_UP;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            // Battery bar on the left.
            tempOrientationCode = ORIENTATION_LANDSCAPE_LEFT;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            // Battery bar on the bottom.
            tempOrientationCode = ORIENTATION_PORTRAIT_DOWN;
            break;
        case UIInterfaceOrientationLandscapeRight:
            // Battery bar on the right.
            tempOrientationCode = ORIENTATION_LANDSCAPE_RIGHT;
            break;
        default:
            break;
    }
    if(tempOrientationCode != mCurrentOrientation) {
        mCurrentOrientation = tempOrientationCode;
        [self.pluginFlutterApi onNativeEventEvent:@{
            @"event" : @(EVENT_ORIENTATION_CHANGED),
            EXTRA_NAME_ORIENTATION : @(tempOrientationCode)} completion:^(FlutterError * _Nullable error) {
            if (nil != error) {
                FTXLOGE(@"callback message error:%@", error);
            }
        }];
    }
}

#pragma mark - superPlayerPluginAPI

- (PlayerMsg *)createVodPlayerOnlyAudio:(BOOL)onlyAudio error:(FlutterError * _Nullable __autoreleasing *)error 
{
    
    FTXVodPlayer* player = [[FTXVodPlayer alloc] initWithRegistrar:self.registrar renderViewFactory:self.renderViewFactory onlyAudio:onlyAudio];
    player.delegate = self;
    NSNumber *playerId = player.playerId;
    _players[playerId] = player;
    FTXLOGI(@"createVodPlayer :%@", playerId);
    return [TXCommonUtil playerMsgWith:playerId];
}


- (PlayerMsg *)createLivePlayerOnlyAudio:(BOOL)onlyAudio error:(FlutterError * _Nullable __autoreleasing *)error {
    FTXLivePlayer* player = [[FTXLivePlayer alloc] initWithRegistrar:self.registrar renderViewFactory:self.renderViewFactory onlyAudio:onlyAudio];
    player.delegate = self;
    NSNumber *playerId = player.playerId;
    _players[playerId] = player;
    FTXLOGI(@"createLivePlayer :%@", playerId);
    return [TXCommonUtil playerMsgWith:playerId];
}

- (nullable StringMsg *)getLiteAVSDKVersionWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [TXCommonUtil stringMsgWith:[TXLiveBase getSDKVersionStr]];
}

- (nullable StringMsg *)getPlatformVersionWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [TXCommonUtil stringMsgWith:[@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]];
}

- (void)releasePlayerPlayerId:(nonnull PlayerMsg *)playerId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *pid = playerId.playerId;
    [self releasePlayerInner:pid];
}

- (void)setConsoleEnabledEnabled:(nonnull BoolMsg *)enabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [TXLiveBase setConsoleEnabled:enabled.value];
}

- (nullable BoolMsg *)setGlobalCacheFolderPathPostfixPath:(nonnull StringMsg *)postfixPath error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSString* postfixPathStr = postfixPath.value;
    if(postfixPathStr != nil && postfixPathStr.length > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
        NSString *preloadDataPath = [documentDirectory stringByAppendingPathComponent:postfixPathStr];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:preloadDataPath withIntermediateDirectories:NO attributes:nil error:&error];
        FTXLOGV(@"setGlobalCacheFolderPathPostfixPath:%@", preloadDataPath);
        [TXPlayerGlobalSetting setCacheFolderPath:preloadDataPath];
        return [TXCommonUtil boolMsgWith:YES];
    } else {
        return [TXCommonUtil boolMsgWith:NO];
    }
}

- (BoolMsg *)setGlobalCacheFolderCustomPathCacheMsg:(CachePathMsg *)cacheMsg error:(FlutterError * _Nullable __autoreleasing *)error {
    NSString* cachePath = cacheMsg.iOSAbsolutePath;
    if (cachePath && cachePath.length > 0) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
        FTXLOGV(@"setGlobalCacheFolderCustomPathCacheMsg:%@", cachePath);
        [TXPlayerGlobalSetting setCacheFolderPath:cachePath];
        return [TXCommonUtil boolMsgWith:YES];
    } else {
        return [TXCommonUtil boolMsgWith:NO];
    }
}

- (nullable IntMsg *)setGlobalEnvEnvConfig:(nonnull StringMsg *)envConfig error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int setResult = [TXLiveBase setGlobalEnv:[envConfig.value UTF8String]];
    return [TXCommonUtil intMsgWith:@(setResult)];
}

- (void)setGlobalLicenseLicenseMsg:(nonnull LicenseMsg *)licenseMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [TXLiveBase setLicenceURL:licenseMsg.licenseUrl key:licenseMsg.licenseKey];
}

- (void)setGlobalMaxCacheSizeSize:(nonnull IntMsg *)size error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if (size.value > 0) {
        [TXPlayerGlobalSetting setMaxCacheSize:size.value.intValue];
    }
}

- (void)setLogLevelLogLevel:(nonnull IntMsg *)logLevel error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [TXLiveBase setLogLevel:logLevel.value.intValue];
    [FTXLog setLogLevel:logLevel.value.intValue];
}

- (nullable BoolMsg *)startVideoOrientationServiceWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // only for android
    return [TXCommonUtil boolMsgWith:YES];
}

- (void)setUserIdMsg:(StringMsg *)msg error:(FlutterError * _Nullable __autoreleasing *)error {
    [TXLiveBase setUserId:msg.value];
}

- (void)setLicenseFlexibleValidMsg:(BoolMsg *)msg error:(FlutterError * _Nullable __autoreleasing *)error {
    [TXPlayerGlobalSetting setLicenseFlexibleValid:msg.value];
}

#pragma mark nativeAPI

- (void)abandonAudioFocusWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // only for android
}

- (nullable DoubleMsg *)getBrightnessWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *brightness = [NSNumber numberWithFloat:[UIScreen mainScreen].brightness];
    return [TXCommonUtil doubleMsgWith:brightness.doubleValue];
}

- (DoubleMsg *)getSysBrightnessWithError:(FlutterError * _Nullable __autoreleasing *)error {
    NSNumber *brightness = [NSNumber numberWithFloat:[UIScreen mainScreen].brightness];
    return [TXCommonUtil doubleMsgWith:brightness.doubleValue];
}

- (nullable DoubleMsg *)getSystemVolumeWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *volume = [NSNumber numberWithFloat:[self.audioManager getVolume]];
    return [TXCommonUtil doubleMsgWith:volume.doubleValue];
}

- (nullable IntMsg *)isDeviceSupportPipWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    BOOL isSupport = [TXVodPlayer isSupportPictureInPicture];
    int pipSupportResult = isSupport ? 0 : ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
    return [TXCommonUtil intMsgWith:@(pipSupportResult)];
}

- (void)requestAudioFocusWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // only for android
}

- (void)restorePageBrightnessWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setSysBrightness:@(-1)];
}

- (void)setBrightnessBrightness:(nonnull DoubleMsg *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [self setSysBrightness:brightness.value];
}

- (void)setSystemVolumeVolume:(nonnull DoubleMsg *)volume error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *volumeNum = volume.value;
    if (volumeNum.floatValue < 0) {
        volumeNum = [NSNumber numberWithFloat:0];
    }
    if (volumeNum.floatValue > 1) {
        volumeNum = [NSNumber numberWithFloat:1];
    }
    [self.audioManager setVolume:volumeNum.floatValue];
}

- (void)registerSysBrightnessIsRegister:(BoolMsg *)isRegister error:(FlutterError * _Nullable __autoreleasing *)error {
    // only for android
}

#pragma mark DataBridge

- (NSMutableDictionary *)getPlayers {
    return self.players;
}

#pragma mark TXLiveBaseDelegate

- (void)onLog:(NSString *)log LogLevel:(int)level WhichModule:(NSString *)module {
//    [_eventSink success:[SuperPlayerPlugin getParamsWithEvent:EVENT_ON_LOG withParams:@{
//        @(EVENT_LOG_LEVEL) : @(level),
//        @(EVENT_LOG_MODULE) : module,
//        @(EVENT_LOG_MSG) : log
//    }]];
    // this may be too busy, so currently do not throw on the Flutter side
}

- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg {
//    [_eventSink success:[SuperPlayerPlugin getParamsWithEvent:EVENT_ON_UPDATE_NETWORK_TIME withParams:@{
//        @(EVENT_ERR_CODE) : @(errCode),
//        @(EVENT_ERR_MSG) : errMsg,
//    }]];
    // This will be opened in a subsequent version
}

- (void)onLicenceLoaded:(int)result Reason:(NSString *)reason {
    FTXLOGV(@"onLicenceLoaded,result:%d, reason:%@", result, reason);
    __block int blockResult = result;
    __block NSString* blockReason = reason;
    __block NSDictionary *param = @{
        @(EVENT_RESULT) : @(blockResult),
        @(EVENT_REASON) : blockReason,
    };
    [self.pluginFlutterApi onSDKListenerEvent:[TXCommonUtil getParamsWithEvent:EVENT_ON_LICENCE_LOADED withParams:param] completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

- (void)onCustomHttpDNS:(NSString *)hostName ipList:(NSMutableArray<NSString *> *)list {
//    [_eventSink success:[SuperPlayerPlugin getParamsWithEvent:EVENT_ON_LICENCE_LOADED withParams:@{
//        @(EVENT_HOST_NAME) : hostName,
//        @(EVENT_IPS) : list,
//    }]];
    // This will be opened in a subsequent version
}

@end
