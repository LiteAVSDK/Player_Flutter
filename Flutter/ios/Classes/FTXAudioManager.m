// Copyright (c) 2022 Tencent. All rights reserved.
#import "FTXAudioManager.h"
#import <Foundation/Foundation.h>

@implementation FTXAudioManager {
    UISlider *_volumeSlider;
    MPVolumeView *_volumeView;
    AVAudioSession *_audioSession;
}

NSString *const LOW_VERSION_NOTIFCATION_NAME = @"AVSystemController_SystemVolumeDidChangeNotification";
NSString *const NOTIFCATION_NAME = @"SystemVolumeDidChange";

- (instancetype)init
 {
     if(self = [super init]) {
         CGRect frame    = CGRectMake(0, -100, 10, 0);
         _volumeView = [[MPVolumeView alloc] initWithFrame:frame];
         _volumeView.hidden = YES;
         [_volumeView sizeToFit];
         _volumeSlider = nil;
         // Start receiving remote control events.
         [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
         for (UIView *view in [_volumeView subviews]) {
             if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
                 _volumeSlider = (UISlider *)view;
                 break;
             }
         }
         
         _audioSession = [AVAudioSession sharedInstance];
     }
     return self;
 };

- (CGFloat)getVolume
{
    return _volumeSlider.value > 0 ? _volumeSlider.value : [[AVAudioSession sharedInstance]outputVolume];
}


- (void)setVolume:(CGFloat)value
{
    // `showsVolumeSlider` needs to be set to YES.
    _volumeView.showsVolumeSlider = YES;
    [_volumeSlider setValue:value animated:NO];
    [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [_volumeSlider sizeToFit];
}

- (void)setVolumeUIVisible:(BOOL)volumeUIVisible
{
    _volumeView.hidden = !volumeUIVisible;
}

- (void)registerVolumeChangeListener:(id)observer
{
    // register volume observer
    [_audioSession addObserver:observer forKeyPath:@"outputVolume" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld  context:nil];
}

- (void)destory:(id)observer
{
    // destory volume view
    [_volumeView removeFromSuperview];
    _volumeView = nil;
    // destory volume observer
    @try {
        [_audioSession removeObserver:observer forKeyPath:@"outputVolume" context:nil];
    } @catch (NSException *exception) {
        // observer may have already been removed
    }
    _audioSession = nil;
}

@end
