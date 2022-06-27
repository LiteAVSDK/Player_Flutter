// Copyright (c) 2022 Tencent. All rights reserved.
#import "FTXAudioManager.h"
#import <Foundation/Foundation.h>

@implementation FTXAudioManager
    UISlider *_volumeSlider;
    MPVolumeView *volumeView;


- (instancetype)init
 {
     if(self = [super init]) {
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
     }
     return self;
 };

- (float)getVolume
{
    return _volumeSlider.value > 0 ? _volumeSlider.value : [[AVAudioSession sharedInstance]outputVolume];
}


- (void)setVolume:(float)value
{
    // 需要设置 showsVolumeSlider 为 YES
    volumeView.showsVolumeSlider = YES;
    [_volumeSlider setValue:value animated:NO];
    [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [_volumeSlider sizeToFit];
}

- (void)setVolumeUIVisible:(BOOL)volumeUIVisible
{
    volumeView.hidden = !volumeUIVisible;
}

- (void)registerVolumeChangeListener:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:aName object:anObject];
}

- (void)destory:(id)observer name:(NSNotificationName)aName object:(id)anObject
{
    // destory volume view
    [volumeView removeFromSuperview];
    // destory volume observer
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:aName object:anObject];
}

@end
