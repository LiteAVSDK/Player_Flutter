// Copyright (c) 2022 Tencent. All rights reserved.

#import <MediaPlayer/MediaPlayer.h>
#import <AVFAudio/AVAudioSession.h>

@interface FTXAudioManager : NSObject


- (float)getVolume;

- (void)setVolume:(float)value;

- (void)setVolumeUIVisible:(BOOL)volumeUIVisible;

- (void)registerVolumeChangeListener:(_Nonnull id)observer;

- (void)destory:(_Nonnull id)observer;

@end
