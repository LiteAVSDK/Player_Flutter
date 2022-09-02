// Copyright (c) 2022 Tencent. All rights reserved.
#import "SuperPlayerPlugin.h"
#import "FTXLivePlayer.h"
#import "FTXVodPlayer.h"
#import "FTXTransformation.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import <MediaPlayer/MediaPlayer.h>
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
#import "FTXAudioManager.h"
#import "FTXDownloadManager.h"

@interface SuperPlayerPlugin ()<FlutterStreamHandler,FTXVodPlayerDelegate>

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
    FTXDownloadManager *_FTXDownloadManager;
    int mCurrentOrientation;
}

SuperPlayerPlugin* instance;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_super_player"
                                     binaryMessenger:[registrar messenger]];
    instance = [[SuperPlayerPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if(nil != instance) {
        [instance destory];
    }
    if (nil != _FTXDownloadManager) {
        [_FTXDownloadManager destroy];
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
    _pipEventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/playerPlugin/pipEvent" binaryMessenger:[registrar messenger]];
    [_eventChannel setStreamHandler:self];
    [_pipEventChannel setStreamHandler:self];

    [audioManager registerVolumeChangeListener:self];
     _FTXDownloadManager = [[FTXDownloadManager alloc] initWithRegistrar:registrar];
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

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if([@"createLivePlayer" isEqualToString:call.method]){
        FTXLivePlayer* player = [[FTXLivePlayer alloc] initWithRegistrar:self.registrar];
        NSNumber *playerId = player.playerId;
        _players[playerId] = player;
        result(playerId);
    }else if([@"createVodPlayer" isEqualToString:call.method]){
        FTXVodPlayer* player = [[FTXVodPlayer alloc] initWithRegistrar:self.registrar];
        player.delegate = self;
        NSNumber *playerId = player.playerId;
        _players[playerId] = player;
        result(playerId);
    }else if([@"releasePlayer" isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSNumber *pid = args[@"playerId"];
        FTXBasePlayer *player = [_players objectForKey:pid];
        [player destory];
        if (player != nil) {
            [_players removeObjectForKey:pid];
        }
        result(nil);
    }else if([@"setConsoleEnabled" isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        BOOL enabled = [args[@"enabled"] boolValue];
        [TXLiveBase setConsoleEnabled:enabled];
        result(nil);
    }else if([@"setGlobalMaxCacheSize" isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSInteger maxCacheItemSize = [args[@"size"] integerValue];
        if (maxCacheItemSize > 0) {
            [TXPlayerGlobalSetting setMaxCacheSize:maxCacheItemSize];
        }
        result(nil);
    }else if([@"setGlobalCacheFolderPath" isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString* postfixPath = args[@"postfixPath"];
        if(postfixPath != nil && postfixPath.length > 0) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
            NSString *preloadDataPath = [documentDirectory stringByAppendingPathComponent:postfixPath];
            if (![[NSFileManager defaultManager] fileExistsAtPath:preloadDataPath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] createDirectoryAtPath:preloadDataPath withIntermediateDirectories:NO attributes:nil error:&error];
                [TXPlayerGlobalSetting setCacheFolderPath:preloadDataPath];
            }
            result([NSNumber numberWithBool:true]);
        } else {
            result([NSNumber numberWithBool:false]);
        }
        
    }else if([@"setGlobalLicense" isEqualToString:call.method]) {
        NSDictionary *args = call.arguments;
        NSString *licenceUrl = args[@"licenceUrl"];
        NSString *licenceKey = args[@"licenceKey"];
        [TXLiveBase setLicenceURL:licenceUrl key:licenceKey];
        result(nil);
    } else if([@"setBrightness" isEqualToString:call.method]) {
        NSNumber *brightness = call.arguments[@"brightness"];
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
        result(nil);
    } else if([@"getBrightness" isEqualToString:call.method]) {
        NSNumber *brightness = [NSNumber numberWithFloat:[UIScreen mainScreen].brightness];
        result(brightness);
    } else if([@"getSystemVolume" isEqualToString:call.method]) {
        NSNumber *volume = [NSNumber numberWithFloat:[audioManager getVolume]];
        result(volume);
    } else if([@"setSystemVolume" isEqualToString:call.method]) {
        NSNumber *volume = call.arguments[@"volume"];
        if (volume.floatValue < 0) {
            volume = [NSNumber numberWithFloat:0];
        }
        if (volume.floatValue > 1) {
            volume = [NSNumber numberWithFloat:1];
        }
        [audioManager setVolume:volume.floatValue];
        result(nil);
    } else if ([@"abandonAudioFocus" isEqualToString:call.method]) {
        // only for android
        result(nil);
    } else if ([@"requestAudioFocus" isEqualToString:call.method]) {
        // only for android
        result(nil);
    } else if([@"setLogLevel" isEqualToString:call.method]) {
        NSDictionary *args = call.arguments;
        int logLevel = [args[@"logLevel"] intValue];
        [TXLiveBase setLogLevel:logLevel];
        result(nil);
    } else if([@"getLiteAVSDKVersion" isEqualToString:call.method]) {
        result([TXLiveBase getSDKVersionStr]);
    } else if ([@"isDeviceSupportPip" isEqualToString:call.method]) {
        BOOL isSupport = [TXVodPlayer isSupportPictureInPicture];
        result([NSNumber numberWithBool:isSupport]);
    } else if([@"setGlobalEnv" isEqualToString:call.method]) {
        NSString *envConfig = call.arguments[@"envConfig"];
        int setResult = [TXLiveBase setGlobalEnv:[envConfig UTF8String]];
        result(@(setResult));
    } else {
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

-(void) destory
{
    [audioManager destory:self];
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

- (void)onPlayerPipStateRestoreUI {
    [_pipEventSink success:@{@"event" : @(EVENT_PIP_MODE_RESTORE_UI)}];
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

@end
