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
#import "VodGlobalResource.h"

@interface SuperPlayerPlugin ()<FTXVodPlayerDelegate,TXFlutterSuperPlayerPluginAPI,TXFlutterNativeAPI, FlutterPlugin>

@property (nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) FTXDownloadManager* fTXDownloadManager;
@property (nonatomic, strong) FTXAudioManager* audioManager;
@property (nonatomic, strong) TXPluginFlutterAPI* pluginFlutterApi;
@property (nonatomic, strong) TXPipFlutterAPI* pipFlutterApi;
@property (nonatomic, strong) FTXRenderViewFactory* renderViewFactory;
@property (nonatomic, assign) BOOL isRegistered;

@end

@implementation SuperPlayerPlugin {
    float orginBrightness;
    int mCurrentOrientation;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FTXLOGV(@"called registerWithRegistrar");
    SuperPlayerPlugin* instance = [[SuperPlayerPlugin alloc] initWithRegistrar:registrar];
    SetUpTXFlutterNativeAPI([registrar messenger], instance);
    SetUpTXFlutterSuperPlayerPluginAPI([registrar messenger], instance);
    [registrar addApplicationDelegate:instance];
    // Process-level hooks (TXLiveBase delegate / orientation) are managed by VodGlobalResource
    // via acquire/release in initWithRegistrar:/destroy, so the single-delegate nature of
    // [TXLiveBase sharedInstance].delegate no longer causes cross-engine conflicts.
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FTXLOGV(@"called detachFromEngineForRegistrar");
    if (self.isRegistered) {
        self.isRegistered = NO;
        [self destroy];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
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
        // orientation baseline; actual listener lives in VodGlobalResource and broadcasts to
        // every engine via -dispatchOrientationChanged:.
        mCurrentOrientation = ORIENTATION_PORTRAIT_UP;
        // renderView
        self.renderViewFactory = [[FTXRenderViewFactory alloc] initWithBinaryMessenger:registrar.messenger];
        [registrar registerViewFactory:self.renderViewFactory withId:VIEW_TYPE_FTX_RENDER_VIEW];
        self.isRegistered = YES;
        // Hand process-level hooks to VodGlobalResource (single TXLiveBaseDelegate / shared
        // orientation observer; fan-out to every attached engine).
        [[VodGlobalResource sharedInstance] acquire:self];
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

-(void) destroy
{
    if (_audioManager) {
        [_audioManager destroy:self];
        _audioManager = nil;
    }
    [self releaseAllPlayer];
    if (nil != _fTXDownloadManager) {
        [_fTXDownloadManager destroy];
        _fTXDownloadManager = nil;
    }
    // Unregister from VodGlobalResource so the process-level hooks can be torn down when the
    // last engine detaches.
    [[VodGlobalResource sharedInstance] release:self];
    // Unbind Pigeon API handlers so the binary messenger does not keep a strong reference to
    // this plugin instance after the engine detaches. Paired with the SetUp*API(messenger,self)
    // calls in +registerWithRegistrar:.
    if (_registrar) {
        SetUpTXFlutterNativeAPI([_registrar messenger], nil);
        SetUpTXFlutterSuperPlayerPluginAPI([_registrar messenger], nil);
    }
}

-(void) releaseAllPlayer {
    @synchronized (self) {
        FTXLOGV(@"start releaseAllPlayer");
        NSArray *allKeys = [self.players allKeys];
        for (id key in allKeys) {
            FTXBasePlayer *player = [self.players objectForKey:key];
            if (player && [player respondsToSelector:@selector(destroy)]) {
                [player destroy];
            }
        }
        [self.players removeAllObjects];
    }
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
        [player destroy];
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
    [self destroy];
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

// The orientation event listener has been migrated to VodGlobalResource, which fans out the
// change into every attached SuperPlayerPlugin via -dispatchOrientationChanged:.
- (void)dispatchOrientationChanged:(int)orientation {
    if (orientation == mCurrentOrientation) return;
    mCurrentOrientation = orientation;
    [self.pluginFlutterApi onNativeEventEvent:@{
        @"event" : @(EVENT_ORIENTATION_CHANGED),
        EXTRA_NAME_ORIENTATION : @(orientation)} completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
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

- (void)setDrmProvisionEnvEnv:(NSInteger)env error:(FlutterError * _Nullable __autoreleasing *)error {
    // only for android
}

#pragma mark DataBridge

- (NSMutableDictionary *)getPlayers {
    return self.players;
}

#pragma mark - Global SDK event forwarding

// TXLiveBaseDelegate has been migrated to VodGlobalResource, which fans out the License-loaded
// event into every attached SuperPlayerPlugin via -dispatchLicenceLoaded:reason:.
- (void)dispatchLicenceLoaded:(int)result reason:(NSString *)reason {
    FTXLOGV(@"dispatchLicenceLoaded,result:%d, reason:%@", result, reason);
    NSDictionary *param = @{
        @(EVENT_RESULT) : @(result),
        @(EVENT_REASON) : reason ?: @"",
    };
    [self.pluginFlutterApi onSDKListenerEvent:[TXCommonUtil getParamsWithEvent:EVENT_ON_LICENCE_LOADED withParams:param] completion:^(FlutterError * _Nullable error) {
        if (nil != error) {
            FTXLOGE(@"callback message error:%@", error);
        }
    }];
}

@end
