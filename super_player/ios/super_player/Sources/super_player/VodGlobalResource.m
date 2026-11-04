// Copyright (c) 2026 Tencent. All rights reserved.

#import "VodGlobalResource.h"
#import "SuperPlayerPlugin.h"
#import "FTXLiteAVSDKHeader.h"
#import "FTXLog.h"
#import "FTXEvent.h"
#import <UIKit/UIKit.h>

@interface VodGlobalResource () <TXLiveBaseDelegate>
@end

@implementation VodGlobalResource {
    NSHashTable<SuperPlayerPlugin *> *_attachedPlugins;   // weak
    NSLock *_lock;
    int _currentOrientation;
}

+ (instancetype)sharedInstance {
    static VodGlobalResource *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [[VodGlobalResource alloc] init];
    });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        _attachedPlugins = [NSHashTable weakObjectsHashTable];
        _lock = [[NSLock alloc] init];
        _currentOrientation = ORIENTATION_PORTRAIT_UP;
    }
    return self;
}

- (void)acquire:(SuperPlayerPlugin *)plugin {
    if (!plugin) return;
    [_lock lock];
    BOOL wasEmpty = (_attachedPlugins.count == 0);
    [_attachedPlugins addObject:plugin];
    FTXLOGV(@"VodGlobalResource acquire plugin=%p, size=%ld, firstAttach=%d",
            plugin, (long)_attachedPlugins.count, wasEmpty);
    if (wasEmpty) {
        [TXLiveBase sharedInstance].delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeviceOrientationChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    [_lock unlock];
}

- (void)release:(SuperPlayerPlugin *)plugin {
    if (!plugin) return;
    [_lock lock];
    [_attachedPlugins removeObject:plugin];
    BOOL nowEmpty = (_attachedPlugins.count == 0);
    FTXLOGV(@"VodGlobalResource release plugin=%p, size=%ld, lastDetach=%d",
            plugin, (long)_attachedPlugins.count, nowEmpty);
    if (nowEmpty) {
        if ([TXLiveBase sharedInstance].delegate == self) {
            [TXLiveBase sharedInstance].delegate = nil;
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceOrientationDidChangeNotification
                                                      object:nil];
    }
    [_lock unlock];
}

#pragma mark - TXLiveBaseDelegate (fan-out)

- (void)onLicenceLoaded:(int)result Reason:(NSString *)reason {
    FTXLOGV(@"VodGlobalResource onLicenceLoaded,result:%d, reason:%@", result, reason);
    NSArray<SuperPlayerPlugin *> *snapshot;
    [_lock lock];
    snapshot = _attachedPlugins.allObjects;
    [_lock unlock];
    for (SuperPlayerPlugin *p in snapshot) {
        [p dispatchLicenceLoaded:result reason:reason ?: @""];
    }
}

// Default no-op for other TXLiveBaseDelegate methods so SuperPlayer behavior stays identical
// (original plugin also discarded these).
- (void)onLog:(NSString *)log LogLevel:(int)level WhichModule:(NSString *)module { }
- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg { }
- (void)onCustomHttpDNS:(NSString *)hostName ipList:(NSMutableArray<NSString *> *)list { }

#pragma mark - Orientation

- (void)onDeviceOrientationChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    int temp = _currentOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            temp = ORIENTATION_PORTRAIT_UP; break;
        case UIInterfaceOrientationLandscapeLeft:
            temp = ORIENTATION_LANDSCAPE_LEFT; break;
        case UIInterfaceOrientationPortraitUpsideDown:
            temp = ORIENTATION_PORTRAIT_DOWN; break;
        case UIInterfaceOrientationLandscapeRight:
            temp = ORIENTATION_LANDSCAPE_RIGHT; break;
        default: break;
    }
    if (temp == _currentOrientation) return;
    _currentOrientation = temp;

    NSArray<SuperPlayerPlugin *> *snapshot;
    [_lock lock];
    snapshot = _attachedPlugins.allObjects;
    [_lock unlock];
    for (SuperPlayerPlugin *p in snapshot) {
        [p dispatchOrientationChanged:temp];
    }
}

@end
