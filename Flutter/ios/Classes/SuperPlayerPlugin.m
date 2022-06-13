// Copyright (c) 2022 Tencent. All rights reserved.
#import "SuperPlayerPlugin.h"
#import "FTXLivePlayer.h"
#import "FTXVodPlayer.h"
#import "FTXTransformation.h"
#import "FTXPlayerEventSinkQueue.h"
#import "FTXEvent.h"
#import <MediaPlayer/MediaPlayer.h>
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>

@interface SuperPlayerPlugin ()<FlutterStreamHandler>

@property (nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic, strong) NSMutableDictionary *players;

@end

@implementation SuperPlayerPlugin {
    float orginBrightness;
    MPVolumeView *volumeView;
    FlutterEventChannel *_eventChannel;
    FTXPlayerEventSinkQueue *_eventSink;
}

static UISlider *_volumeSlider;
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
    CGRect frame    = CGRectMake(0, -100, 10, 0);
    volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    volumeView.hidden = YES;
    [volumeView sizeToFit];
    // 单例slider
    _volumeSlider = nil;
    for (UIView *view in [volumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
            _volumeSlider = (UISlider *)view;
            break;
        }
    }
    // volume event stream
    _eventSink = [FTXPlayerEventSinkQueue new];
    _eventChannel = [FlutterEventChannel eventChannelWithName:@"cloud.tencent.com/playerPlugin/event" binaryMessenger:[registrar messenger]];
    [_eventChannel setStreamHandler:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemVolumeDidChangeNoti:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
 
    return self;
}

-(void)systemVolumeDidChangeNoti:(NSNotification* )noti{
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
        int size = [args[@"size"] intValue];
        [FTXTransformation setMaxCacheItemSize:size];
        result(nil);
    }else if([@"setGlobalCacheFolderPath" isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString* path = args[@"path"];
        [FTXTransformation setCacheFolder:path];
        result(nil);
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
        NSNumber *volume = [NSNumber numberWithFloat:[self getVolume]];
        result(volume);
    } else if([@"setSystemVolume" isEqualToString:call.method]) {
        NSNumber *volume = call.arguments[@"volume"];
        if (volume.floatValue < 0) {
            volume = [NSNumber numberWithFloat:0];
        }
        if (volume.floatValue > 1) {
            volume = [NSNumber numberWithFloat:1];
        }
        [self setVolume:volume.floatValue];
        result(nil);
    } else if ([@"abandonAudioFocus" isEqualToString:call.method]) {
        // only for android
        result(nil);
    } else if ([@"requestAudioFocus" isEqualToString:call.method]) {
        // only for android
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(float)getVolume{
    return _volumeSlider.value > 0 ? _volumeSlider.value : [[AVAudioSession sharedInstance]outputVolume];
}

- (void)setVolume:(float)value {
    // 需要设置 showsVolumeSlider 为 YES
    volumeView.showsVolumeSlider = YES;
    [_volumeSlider setValue:value animated:NO];
    [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [_volumeSlider sizeToFit];
}

// 是否显示右边音量的UI
- (void)setVolumeUIVisible:(BOOL)volumeUIVisible {
    volumeView.hidden = !volumeUIVisible;
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
    // destory volume view
    [volumeView removeFromSuperview];
    // destory volume observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

#pragma mark - FlutterStreamHandler
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:events];
        }
    }

    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString:@"event"]) {
            [_eventSink setDelegate:nil];
        }
    }
    return nil;
}


@end
