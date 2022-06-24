// Copyright (c) 2022 Tencent. All rights reserved.

#import <MediaPlayer/MediaPlayer.h>
#import <AVFAudio/AVAudioSession.h>

@interface FTXAudioManager : NSObject


- (float)getVolume;

- (void)setVolume:(float)value;

- (void)setVolumeUIVisible:(BOOL)volumeUIVisible;

- (void)registerVolumeChangeListener:(_Nonnull id)observer selector:(_Nonnull SEL)aSelector
                                name:(nullable NSNotificationName)aName object:(nullable id)anObject;

- (void)destory:(_Nonnull id)observer name:(nullable NSNotificationName)aName
                                object:(nullable id)anObject;

@end
