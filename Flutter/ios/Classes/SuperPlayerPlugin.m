// Copyright (c) 2022 Tencent. All rights reserved.
#import "SuperPlayerPlugin.h"
#import "FTXLivePlayer.h"
#import "FTXVodPlayer.h"
#import "FTXTransformation.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import <MediaPlayer/MediaPlayer.h>
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import "FTXAudioManager.h"
#import "FTXDownloadManager.h"
#import "FtxMessages.h"
#import "FTXVodPlayerDispatcher.h"
#import "FTXLivePlayerDispatcher.h"

@interface SuperPlayerPlugin ()<FlutterStreamHandler,FTXVodPlayerDelegate,TXFlutterSuperPlayerPluginAPI,TXFlutterNativeAPI, IPlayersBridge, FlutterPlugin>

@property (nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic, strong) NSMutableDictionary *players;

@end

@implementation SuperPlayerPlugin {
    float orginBrightness;
    FlutterEventChannel *_eventChannel;
    FlutterEventChannel *_pipEventChannel;
    FTXPlayerEventSinkQueue *_eventSink;
    FTXPlayerEventSinkQueue *_pipEventSink;
    FTXAudioManager *audioManager;
    FTXDownloadManager *_fTXDownloadManager;
    int mCurrentOrientation;
}

SuperPlayerPlugin* instance;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    instance = [[SuperPlayerPlugin alloc] initWithRegistrar:registrar];
    TXFlutterSuperPlayerPluginAPISetup([registrar messenger], instance);
    TXFlutterNativeAPISetup([registrar messenger], instance);
    TXFlutterVodPlayerApiSetup([registrar messenger], [[FTXVodPlayerDispatcher alloc] initWithBridge:instance]);
    TXFlutterLivePlayerApiSetup([registrar messenger], [[FTXLivePlayerDispatcher alloc] initWithBridge:instance]);
    [registrar addApplicationDelegate:instance];
    
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if(nil != instance) {
        [instance destory];
    }
    if (nil != _fTXDownloadManager) {
        [_fTXDownloadManager destroy];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRegistrar:
(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _players = @{}.mutableCopy;
    }
    // light componet init
    orginBrightness = [UIScreen mainScreen].brightness;
    // volume componet init
    audioManager = [[FTXAudioManager alloc] init];
    // volume event stream
    _eventSink = [FTXPlayerEventSinkQueue new];
    _pipEventSink = [FTXPlayerEventSinkQueue new];
    _eventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/playerPlugin/event" binaryMessenger:[registrar messenger]];
    _pipEventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/playerPlugin/componentEvent" binaryMessenger:[registrar messenger]];
    [_eventChannel setStreamHandler:self];
    [_pipEventChannel setStreamHandler:self];

    // brightness event
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(brightnessDidChange:) name:UIScreenBrightnessDidChangeNotification object:[UIScreen mainScreen]];
    
    [audioManager registerVolumeChangeListener:self];
     _fTXDownloadManager = [[FTXDownloadManager alloc] initWithRegistrar:registrar];
    // orientation
    mCurrentOrientation = ORIENTATION_PORTRAIT_UP;
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onDeviceOrientationChange:)
            name:UIDeviceOrientationDidChangeNotification
          object:nil];

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [_eventSink success:[SuperPlayerPlugin getParamsWithEvent:EVENT_VOLUME_CHANGED withParams:@{}]];
}

+ (NSDictionary *)getParamsWithEvent:(int)EvtID withParams:(NSDictionary *)params
{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtID) forKey:@"event"];
    if (params != nil && params.count != 0) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}

-(void) destory
{
    [audioManager destory:self];
}

-(void) setSysBrightness:(NSNumber*)brightness {
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

/**
 亮度变化
 */
- (void)brightnessDidChange:(NSNotification *)notification
{
    [_eventSink success:[SuperPlayerPlugin getParamsWithEvent:EVENT_BRIGHTNESS_CHANGED withParams:@{}]];
}

#pragma mark - FlutterPlugin

- (void)applicationWillTerminate:(UIApplication *)application {
    for(id key in self.players) {
        id player = self.players[key];
        if([player respondsToSelector:@selector(notifyAppTerminate:)]) {
            [player notifyAppTerminate:application];
        }
    }
}

#pragma mark - FlutterStreamHandler
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:events];
        } else if ([arguments isEqualToString:@"pipEvent"]) {
            [_pipEventSink setDelegate:events];
        }
    }

    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:nil];
        } else if ([arguments isEqualToString:@"pipEvent"]) {
            [_pipEventSink setDelegate:nil];
        }
    }
    return nil;
}

#pragma mark - FTXVodPlayerDelegate

- (void)onPlayerPipRequestStart {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_REQUEST_START)}];
}

- (void)onPlayerPipStateDidStart {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_ALREADY_ENTER)}];
}

- (void)onPlayerPipStateWillStop {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_WILL_EXIT)}];
}

- (void)onPlayerPipStateDidStop {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_ALREADY_EXIT)}];
}

- (void)onPlayerPipStateError:(NSInteger)errorId {
    [_pipEventSink success:@{@"event" : @(errorId)}];
}

- (void)onPlayerPipStateRestoreUI:(double)playTime {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_RESTORE_UI), EVENT_PIP_PLAY_TIME : @(playTime)}];
}

#pragma mark - orientation

- (void)onDeviceOrientationChange:(NSNotification *)notification {
    // IOS 此处不需要判断是否打开自动屏幕旋转/竖排锁定开关，当IOS打开锁定之后，这里默认是收不到回调的
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    int tempOrientationCode = mCurrentOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            // 电池栏在上
            tempOrientationCode = ORIENTATION_PORTRAIT_UP;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            // 电池栏在左
            tempOrientationCode = ORIENTATION_LANDSCAPE_LEFT;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            // 电池栏在下
            tempOrientationCode = ORIENTATION_PORTRAIT_DOWN;
            break;
        case UIInterfaceOrientationLandscapeRight:
            // 电池栏在右
            tempOrientationCode = ORIENTATION_LANDSCAPE_RIGHT;
            break;
        default:
            break;
    }
    if(tempOrientationCode != mCurrentOrientation) {
        mCurrentOrientation = tempOrientationCode;
        [_eventSink success:@{
            @"event" : @(EVENT_ORIENTATION_CHANGED),
            EXTRA_NAME_ORIENTATION : @(tempOrientationCode)}];
    }
}

#pragma mark - superPlayerPluginAPI

- (nullable PlayerMsg *)createLivePlayerWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    FTXLivePlayer* player = [[FTXLivePlayer alloc] initWithRegistrar:self.registrar];
    NSNumber *playerId = player.playerId;
    _players[playerId] = player;
    return [CommonUtil playerMsgWith:playerId];
}

- (nullable PlayerMsg *)createVodPlayerWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    FTXVodPlayer* player = [[FTXVodPlayer alloc] initWithRegistrar:self.registrar];
    player.delegate = self;
    NSNumber *playerId = player.playerId;
    _players[playerId] = player;
    return [CommonUtil playerMsgWith:playerId];
}

- (nullable StringMsg *)getLiteAVSDKVersionWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [CommonUtil stringMsgWith:[TXLiveBase getSDKVersionStr]];
}

- (nullable StringMsg *)getPlatformVersionWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [CommonUtil stringMsgWith:[@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]];
}

- (void)releasePlayerPlayerId:(nonnull PlayerMsg *)playerId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *pid = playerId.playerId;
    FTXBasePlayer *player = [_players objectForKey:pid];
    [player destory];
    if (player != nil) {
        [_players removeObjectForKey:pid];
    }
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
        if (![[NSFileManager defaultManager] fileExistsAtPath:preloadDataPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:preloadDataPath withIntermediateDirectories:NO attributes:nil error:&error];
            [TXPlayerGlobalSetting setCacheFolderPath:preloadDataPath];
        }
        return [CommonUtil boolMsgWith:YES];
    } else {
        return [CommonUtil boolMsgWith:NO];
    }
    
}

- (nullable IntMsg *)setGlobalEnvEnvConfig:(nonnull StringMsg *)envConfig error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    int setResult = [TXLiveBase setGlobalEnv:[envConfig.value UTF8String]];
    return [CommonUtil intMsgWith:@(setResult)];
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
}

- (nullable BoolMsg *)startVideoOrientationServiceWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // only for android
    return [CommonUtil boolMsgWith:YES];
}

#pragma mark nativeAPI

- (void)abandonAudioFocusWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // only for android
}

- (nullable DoubleMsg *)getBrightnessWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *brightness = [NSNumber numberWithFloat:[UIScreen mainScreen].brightness];
    return [CommonUtil doubleMsgWith:brightness.doubleValue];
}

- (DoubleMsg *)getSysBrightnessWithError:(FlutterError * _Nullable __autoreleasing *)error {
    NSNumber *brightness = [NSNumber numberWithFloat:[UIScreen mainScreen].brightness];
    return [CommonUtil doubleMsgWith:brightness.doubleValue];
}

- (nullable DoubleMsg *)getSystemVolumeWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSNumber *volume = [NSNumber numberWithFloat:[audioManager getVolume]];
    return [CommonUtil doubleMsgWith:volume.doubleValue];
}

- (nullable IntMsg *)isDeviceSupportPipWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    BOOL isSupport = [TXVodPlayer isSupportPictureInPicture];
    int pipSupportResult = isSupport ? 0 : ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
    return [CommonUtil intMsgWith:@(pipSupportResult)];
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
    [audioManager setVolume:volumeNum.floatValue];
}

#pragma mark DataBridge

- (NSMutableDictionary *)getPlayers {
    return self.players;
}

@end
