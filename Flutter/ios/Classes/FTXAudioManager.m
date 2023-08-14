// Copyright (c) 2022 Tencent. All rights reserved.
#import "FTXAudioManager.h"
#import <Foundation/Foundation.h>

@implementation FTXAudioManager
    UISlider *_volumeSlider;
    MPVolumeView *volumeView;
    AVAudioSession *audioSession;

NSString *const LOW_VERSION_NOTIFCATION_NAME = @"AVSystemController_SystemVolumeDidChangeNotification";
NSString *const NOTIFCATION_NAME = @"SystemVolumeDidChange";

- (instancetype)init
 {
     if(self = [super init]) {
         CGRect frame    = CGRectMake(0, -100, 10, 0);
         volumeView = [[MPVolumeView alloc] initWithFrame:frame];
         volumeView.hidden = YES;
         [volumeView sizeToFit];
         _volumeSlider = nil;
         // Start receiving remote control events.
         [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
         for (UIView *view in [volumeView subviews]) {
             if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
                 _volumeSlider = (UISlider *)view;
                 break;
             }
         }
         
         audioSession = [AVAudioSession sharedInstance];
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
    volumeView.showsVolumeSlider = YES;
    // Get audio focus.
    [audioSession setActive:true error:nil];
    [_volumeSlider setValue:value animated:NO];
    [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [_volumeSlider sizeToFit];
}

- (void)setVolumeUIVisible:(BOOL)volumeUIVisible
{
    // Get audio focus.
    [audioSession setActive:true error:nil];
    volumeView.hidden = !volumeUIVisible;
}

- (void)registerVolumeChangeListener:(id)observer
{
    // destory volume observer
    [audioSession addObserver:observer forKeyPath:@"outputVolume" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld  context:nil];
}

- (void)destory:(id)observer
{
    // destory volume view
    [volumeView removeFromSuperview];
    // destory volume observer
    [audioSession removeObserver:observer forKeyPath:@"outputVolume" context:nil];
}

@end
