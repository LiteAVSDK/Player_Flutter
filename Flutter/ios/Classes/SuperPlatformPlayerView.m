//
//  SuperPlatformView.m
//  Pods
//
//  Created by Zhirui Ou on 2021/3/10.
//

#import "SuperPlatformPlayerView.h"
#import "SuperPlayer.h"
#import "FTXBasePlayer.h"
#import "FTXPlayerEventSinkQueue.h"

@interface SuperPlatformPlayerView ()<SuperPlayerDelegate, FlutterStreamHandler>
{
    FTXPlayerEventSinkQueue *_eventSink;
}

@property (nonatomic, strong) SuperPlayerView *realPlayerView;
@property (nonatomic, strong) UIView *playerFatherView;
@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;

@end

@implementation SuperPlatformPlayerView

+ (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args registrar:(id<FlutterPluginRegistrar>)registrar
{
    SuperPlatformPlayerView *playerView = [[SuperPlatformPlayerView alloc] initWithRegistrar:registrar viewIdentifier:viewId];
    /*
    SuperPlayerView *realPlayerView = playerView.realPlayerView;
    if ([args isKindOfClass:[NSDictionary class]]) {
        if ([args[@"playerConfig"] isKindOfClass:[NSDictionary class]]) {
            realPlayerView.playerConfig.playShiftDomain = args[@"playerConfig"][@"playShiftDomain"];
            realPlayerView.playerConfig.mirror = [args[@"playerConfig"][@"mirror"] boolValue];
            realPlayerView.playerConfig.hwAcceleration = [args[@"playerConfig"][@"hwAcceleration"] boolValue];
            realPlayerView.playerConfig.playRate = [args[@"playerConfig"][@"playRate"] floatValue];
            realPlayerView.playerConfig.mute = [args[@"playerConfig"][@"mute"] boolValue];
            realPlayerView.playerConfig.renderMode = [args[@"playerConfig"][@"renderMode"] intValue];
            realPlayerView.playerConfig.headers = args[@"playerConfig"][@"headers"];
            realPlayerView.playerConfig.maxCacheItem = [args[@"playerConfig"][@"maxCacheItem"] intValue];
            realPlayerView.playerConfig.enableLog = [args[@"playerConfig"][@"enableLog"] boolValue];
        }
        
        SuperPlayerModel *model = SuperPlayerModel.new;
        if ([args[@"playerModel"] isKindOfClass:[NSDictionary class]]) {
            model.videoURL = args[@"playerModel"][@"videoURL"];
            model.appId = [args[@"playerModel"][@"appId"] unsignedLongLongValue];
            model.defaultPlayIndex = [args[@"playerModel"][@"defaultPlayIndex"] unsignedLongLongValue];
            if ([args[@"playerModel"][@"videoId"] isKindOfClass:[NSDictionary class]]) {
                SuperPlayerVideoId *videoId = [SuperPlayerVideoId new];
                videoId.fileId = args[@"playerModel"][@"videoId"][@"fileId"];
                videoId.psign = args[@"playerModel"][@"videoId"][@"psign"];
                model.videoId = videoId;
            }
            if ([args[@"playerModel"][@"multiVideoURLs"] isKindOfClass:[NSArray class]]) {
                NSMutableArray *multiVideoURLs = @[].mutableCopy;
                for (NSDictionary *urlDic in args[@"playerModel"][@"multiVideoURLs"]) {
                    SuperPlayerUrl *url = [SuperPlayerUrl new];
                    url.title = urlDic[@"title"];
                    url.url = urlDic[@"url"];
                    [multiVideoURLs addObject:url];
                }
                model.multiVideoURLs = multiVideoURLs;
            }
        }
        
        realPlayerView.autoPlay = [args[@"autoPlay"] boolValue];
        realPlayerView.startTime = [args[@"startTime"] doubleValue];
//        realPlayerView.isLockScreen = [args[@"isLockScreen"] boolValue];
        realPlayerView.isLockScreen = true;
        realPlayerView.disableGesture = [args[@"disableGesture"] boolValue];
        realPlayerView.loop = [args[@"loop"] boolValue];
//        [realPlayerView setFullScreen:[args[@"isFullScreen"] boolValue]];
        realPlayerView.isFullScreen = false;
        
        //realPlayerView.controlView = SuperPlayerControlView.new;
        realPlayerView.repeatBackBtn.hidden = true;
        
        
        [realPlayerView playWithModel:model];
    }
    */

    return playerView;
}
 
- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar viewIdentifier:(int64_t)viewId
{
    if (self = [self init]) {
        __weak typeof(self) weakSelf = self;
        _eventSink = [FTXPlayerEventSinkQueue new];
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[@"cloud.tencent.com/superPlayer/" stringByAppendingString:[NSString stringWithFormat:@"%@", @(viewId)]] binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"cloud.tencent.com/superPlayer/event/" stringByAppendingString:[NSString stringWithFormat:@"%@", @(viewId)]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
    }
    
    return self;
}

- (void)dealloc
{
    [self destory];
}

- (void)destory
{
    [_realPlayerView resetPlayer];
    [_eventChannel setStreamHandler:nil];
    _realPlayerView = nil;
    _eventChannel = nil;
    _methodChannel = nil;
    _eventSink = nil;
}

- (void)reloadView:(NSString *)url appId:(long)appId fileId:(NSString *)fileId psign:(NSString *)psign
{
    SuperPlayerModel *playerModel = self.realPlayerView.playerModel;
    if (url.length > 0) {//有url就直接播放
        playerModel.videoURL = url;
        playerModel.videoId = nil;
    }else if (appId > 0 && fileId.length > 0) {
        SuperPlayerVideoId *videoId = [SuperPlayerVideoId new];
        playerModel.appId = appId;
        videoId.fileId = fileId;
        if (psign.length > 0) {
            videoId.psign = psign;
        }
        playerModel.videoId = videoId;
        playerModel.videoURL = nil;
    }

    [self.realPlayerView resetPlayer];
    [self.realPlayerView playWithModel:playerModel];
}

- (void)playWithModel:(NSDictionary *)args
{
    SuperPlayerModel *model = SuperPlayerModel.new;
    if ([args[@"playerModel"] isKindOfClass:[NSDictionary class]]) {
        model.videoURL = args[@"playerModel"][@"videoURL"];
        model.appId = [args[@"playerModel"][@"appId"] longValue];
        model.defaultPlayIndex = [args[@"playerModel"][@"defaultPlayIndex"] unsignedIntValue];
        if ([args[@"playerModel"][@"videoId"] isKindOfClass:[NSDictionary class]]) {
            SuperPlayerVideoId *videoId = [SuperPlayerVideoId new];
            videoId.fileId = args[@"playerModel"][@"videoId"][@"fileId"];
            videoId.psign = args[@"playerModel"][@"videoId"][@"psign"];
            model.videoId = videoId;
            model.videoURL = nil;
        }
        if ([args[@"playerModel"][@"multiVideoURLs"] isKindOfClass:[NSArray class]]) {
            NSMutableArray *multiVideoURLs = @[].mutableCopy;
            for (NSDictionary *urlDic in args[@"playerModel"][@"multiVideoURLs"]) {
                SuperPlayerUrl *url = [SuperPlayerUrl new];
                url.title = urlDic[@"title"];
                url.url = urlDic[@"url"];
                [multiVideoURLs addObject:url];
            }
            model.multiVideoURLs = multiVideoURLs;
        }
    }
    
    [self.realPlayerView resetPlayer];
    [self.realPlayerView playWithModel:model];
}

- (void)setPlayConfig:(NSDictionary *)args
{
    if ([args[@"config"] isKindOfClass:[NSDictionary class]]) {
        self.realPlayerView.playerConfig.playShiftDomain = args[@"config"][@"playShiftDomain"];
        self.realPlayerView.playerConfig.mirror = [args[@"config"][@"mirror"] boolValue];
        self.realPlayerView.playerConfig.hwAcceleration = [args[@"config"][@"hwAcceleration"] boolValue];
        self.realPlayerView.playerConfig.playRate = [args[@"config"][@"playRate"] floatValue];
        self.realPlayerView.playerConfig.mute = [args[@"config"][@"mute"] boolValue];
        self.realPlayerView.playerConfig.renderMode = [args[@"config"][@"renderMode"] intValue];
        self.realPlayerView.playerConfig.headers = args[@"config"][@"headers"];
        self.realPlayerView.playerConfig.maxCacheItem = [args[@"config"][@"maxCacheItem"] intValue];
        self.realPlayerView.playerConfig.enableLog = [args[@"config"][@"enableLog"] boolValue];
    }
}

- (void)setIsAutoPlay:(BOOL)b
{
    self.realPlayerView.autoPlay = b;
}

- (void)setStartTime:(float)startTime
{
    [self.realPlayerView setStartTime:startTime];
}

- (void)disableGesture:(BOOL)b
{
    self.realPlayerView.disableGesture = b;
}

- (void)setLoop:(BOOL)bLoop
{
    self.realPlayerView.loop = bLoop;
}

#pragma mark - FlutterStreamHandler

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events
{
    [_eventSink setDelegate:events];
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    [_eventSink setDelegate:nil];
    return nil;
}

#pragma mark -

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSDictionary *args = call.arguments;
    
    if ([@"reloadView" isEqualToString:call.method]) {
        NSString *url = args[@"url"];
        long appId = [args[@"appId"] longValue];
        NSString *fileId = args[@"fileId"];
        NSString *psign = args[@"psign"];
        [self reloadView:url appId:appId fileId:fileId psign:psign];
        result(nil);
    }else if ([@"play" isEqualToString:call.method]) {
        [self playWithModel:args];
        result(nil);
    }else if ([@"playConfig" isEqualToString:call.method]) {
        [self setPlayConfig:args];
        result(nil);
    }else if ([@"setIsAutoPlay" isEqualToString:call.method]) {
        BOOL isAutoPlay = [args[@"isAutoPlay"] boolValue];
        [self setIsAutoPlay:isAutoPlay];
        result(nil);
    }else if ([@"setStartTime" isEqualToString:call.method]) {
        float startTime = [args[@"startTime"] floatValue];
        [self setStartTime:startTime];
        result(nil);
    }else if ([@"disableGesture" isEqualToString:call.method]) {
        BOOL enable = [args[@"enable"] boolValue];
        [self disableGesture:enable];
        result(nil);
    }else if ([@"setLoop" isEqualToString:call.method]) {
        BOOL loop = [args[@"loop"] boolValue];
        [self setLoop:loop];
        result(nil);
    }else if ([@"resetPlayer" isEqualToString:call.method]) {
        [self destory];
        result(nil);
    }else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - FlutterPlatformView

- (UIView *)view
{
    return self.playerFatherView;
}

#pragma mark - lazy

- (SuperPlayerView *)realPlayerView
{
    if (!_realPlayerView) {
        _realPlayerView = [SuperPlayerView new];
        _realPlayerView.delegate = self;
        _realPlayerView.fatherView = self.playerFatherView;
        [self.playerFatherView addSubview:_realPlayerView];
    }
    
    
    
    return _realPlayerView;
}

- (UIView *)playerFatherView
{
    if (!_playerFatherView) {
        _playerFatherView = UIView.new;
        _playerFatherView.backgroundColor = UIColor.blackColor;
    }
    
    return _playerFatherView;
}

#pragma mark - SuperPlayerDelegate

/// 返回事件
- (void)superPlayerBackAction:(SuperPlayerView *)player
{
    [_eventSink success:[self getParamsWithEvent:@"onSuperPlayerBackAction" withParams:@{}]];
}

/// 全屏改变通知
- (void)superPlayerFullScreenChanged:(SuperPlayerView *)player
{
    if (!player.isFullScreen) {
        [_eventSink success:[self getParamsWithEvent:@"onStopFullScreenPlay" withParams:@{}]];
    }else {
        [_eventSink success:[self getParamsWithEvent:@"onStartFullScreenPlay" withParams:@{}]];
    }
}

/// 播放开始通知
- (void)superPlayerDidStart:(SuperPlayerView *)player;
{
    [_eventSink success:[self getParamsWithEvent:@"onSuperPlayerDidStart" withParams:@{}]];
}

/// 播放结束通知
- (void)superPlayerDidEnd:(SuperPlayerView *)player
{
    [_eventSink success:[self getParamsWithEvent:@"onSuperPlayerDidEnd" withParams:@{}]];
}

/// 播放错误通知
- (void)superPlayerError:(SuperPlayerView *)player errCode:(int)code errMessage:(NSString *)why;
{
    [_eventSink success:[self getParamsWithEvent:@"onSuperPlayerError" withParams:@{
        @"errCode":@(code),
        @"errMessage":why
    }]];
}
// 需要通知到父view的事件在此添加

- (NSDictionary *)getParamsWithEvent:(NSString *)evtName withParams:(NSDictionary *)params
{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:evtName forKey:@"event"];
    if (params != nil && params.count != 0) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}


+ (UINavigationController *)currentNavigationController
{
    UINavigationController *currentNav = [self getNearestNavigation:[self appRootViewController]];
    do {
        UINavigationController *subNav = [self getNearestNavigation:[currentNav.viewControllers lastObject]];
        if (subNav) {
            currentNav = subNav;
        } else {
            break;
        }
    } while (1) ;
    
    return currentNav;
}

+ (UIViewController *)topViewController
{
    return [self topViewController:[self appRootViewController]];
}

+ (UINavigationController *)getNearestNavigation:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)rootViewController;
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootViewController;
        return [self getNearestNavigation:tabController.selectedViewController];
    }
    if (rootViewController.presentedViewController) {
        return [self getNearestNavigation:rootViewController.presentedViewController];
    }
    return nil;
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [self topViewController:[navigationController.viewControllers lastObject]];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootViewController;
        return [self topViewController:tabController.selectedViewController];
    }
    if (rootViewController.presentedViewController) {
        return [self topViewController:rootViewController.presentedViewController];
    }
    return rootViewController;
}


+ (UIViewController *)appRootViewController
{
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (!root) {
        root = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    return root;
}

@end
