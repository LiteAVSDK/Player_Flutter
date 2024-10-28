// Copyright (c) 2024 Tencent. All rights reserved.

#import "FTXBackPlayer.h"
#import "FTXPlayerConstants.h"
#import "FTXLog.h"

/// 微妙转毫秒
#define USEC_TO_MSEC 1000ull

static NSString* kPipTag = @"FTXBackPlayer";

static void *gTVKAVPlayerKVOContextTimeControlStatus = &gTVKAVPlayerKVOContextTimeControlStatus;
static void *gTVKAVPlayerKVOContextAirplay = &gTVKAVPlayerKVOContextAirplay;
static void *gTVKAVPlayerKVOContextError = &gTVKAVPlayerKVOContextError;

static void *gTVKAVPlayerItemKVOContextState = &gTVKAVPlayerItemKVOContextState;

@interface FTXBackPlayer()

@property (nonatomic, strong) AVPlayer* avPlayer;
@property (nonatomic, strong) AVPlayerLayer* playerLayer;
@property (nonatomic, strong) AVPlayerItem* playerItem;
@property (nonatomic, assign) BOOL isLoopBack;
@property (nonatomic, strong) AVAsset* asset;
@property (nonatomic, assign) FTXAVPlayerState playerState;/// 系统播放资源

@end

@implementation FTXBackPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.playerState = FTXAVPlayerStateIdle;
    }
    return self;
}

- (void)prepareVideo:(AVPlayerItem *)item {
    self.asset = item.asset;
    self.playerItem = item;
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    self.avPlayer.volume = 0;
    self.avPlayer.rate = 1;
    self.avPlayer.muted = YES;
    if (self.isLoopBack) {
        [self.avPlayer setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    }
    // 不允许airplay
    self.avPlayer.allowsExternalPlayback = NO;
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.hidden = YES;
    [self.playerLayer setPlayer:self.avPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(playbackFinished:)
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    [self addKVOWithPlayer:self.avPlayer];
    self.playerState = FTXAVPlayerStatePrepared;
}

- (void)replaceCurrentItemWithPlayerItem:(AVPlayerItem *)playerItem {
    FTXLOGI(@"[%@]replaceCurrentItemWithPlayerItem", kPipTag);
    if (nil == self.avPlayer) {
        FTXLOGW(@"[%@]replaceCurrentItemWithPlayerItem met null player", kPipTag);
        return;
    }
    self.asset = playerItem.asset;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    self.playerItem = playerItem;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(playbackFinished:)
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
}

- (void)seekTo:(int64_t)positionMs {
    FTXLOGI(@"[%@]seekto %lld ms", kPipTag, positionMs);
    if (positionMs < 0) {
        return;
    }
    if (nil == self.avPlayer) {
        FTXLOGW(@"[%@]seekto met null player", kPipTag);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.avPlayer seekToTime:CMTimeMake(positionMs * 1000, USEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    });
}

- (void)play {
    FTXLOGI(@"[%@]play", kPipTag);
    if (nil == self.avPlayer) {
        FTXLOGW(@"[%@]play met null player", kPipTag);
        return;
    }
    [self.avPlayer play];
    self.playerState = FTXAVPlayerStatePlaying;
}

- (void)pause {
    FTXLOGI(@"[%@]pause", kPipTag);
    if (nil == self.avPlayer) {
        FTXLOGW(@"[%@]pause met null player", kPipTag);
        return;
    }
    dispatch_async(dispatch_get_main_queue(),^{
        [self.avPlayer pause];
        self.playerState = FTXAVPlayerStatePaused;
    });
}

- (void)stop {
    FTXLOGI(@"[%@]stop", kPipTag);
    if (nil == self.avPlayer) {
        FTXLOGW(@"[%@]stop met null player", kPipTag);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.avPlayer pause];
        self.playerState = FTXAVPlayerStateStopped;
    });
    [self reset];
}

- (void)setContainerView:(UIView*)container {
    FTXLOGI(@"[%@]setContainerView", kPipTag);
    if (nil == self.playerLayer) {
        FTXLOGW(@"[%@]setContainerView met null playerLayer", kPipTag);
        return;
    }
    [container.layer addSublayer:self.playerLayer];
    self.playerLayer.frame = container.bounds;
}

- (void)setPlayerState:(FTXAVPlayerState)playerState {
    FTXLOGI(@"[%@]setPlayerState,playerState:%ld", kPipTag, (long)playerState);
    if (self.playerDelegate != nil) {
        [self.playerDelegate playerStateDidChange:playerState];
    }
    self->_playerState = playerState;
}

- (void)setLoopback:(BOOL)isLoop {
    FTXLOGI(@"[%@]setLoopback,isLoop:%i", kPipTag, isLoop);
    self.isLoopBack = isLoop;
}

- (AVPlayerLayer *)getPlayerLayer {
    return self.playerLayer;
}

- (void)reset {
    [self.playerLayer removeFromSuperlayer];
    [self.playerLayer setPlayer:nil];
    [self removeKVOWithPlayer:self.avPlayer];
    self.isLoopBack = NO;
    self.playerState = FTXAVPlayerStateIdle;
    self.avPlayer = nil;
    self.playerLayer = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.avPlayer) {
        if (context == gTVKAVPlayerKVOContextTimeControlStatus) {
            // 画中画播放时，才管系统播放器的播放暂停状态。 非画中画情况下，都是主播放器影响系统播放器，不需要系统播放器反过来影响主播放器
            [self handleAVPlayerTimeControlStatusChanged];
        }
    }
}

- (int64_t)currentPositionMs {
    return CMTimeGetSeconds(self.avPlayer.currentTime) * USEC_TO_MSEC;
}

- (int64_t)durationMs {
    return (int64_t)(CMTimeGetSeconds(self.asset.duration) * 1000);
}

- (void)playbackFinished:(NSNotification *)notification {
    if (self.isLoopBack) {
        [self.avPlayer seekToTime:CMTimeMake(0, USEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self.avPlayer play];
    }
}

- (void)addKVOWithPlayer:(AVPlayer *)player {
    if (player != nil) {
        [player addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:gTVKAVPlayerKVOContextError];
        // kvo监听系统播放器的暂停播放状态（之前监听播放速度rate来判断状态，可能不准，监听timeControlStatus是最准的）
        if (@available(iOS 10.0, macOS 10.12, *)) {
            [player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:gTVKAVPlayerKVOContextTimeControlStatus];
        } else {
            [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:gTVKAVPlayerKVOContextTimeControlStatus];
        }
        
        [player addObserver:self forKeyPath:@"airPlayVideoActive" options:NSKeyValueObservingOptionNew context:gTVKAVPlayerKVOContextAirplay];
        [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:gTVKAVPlayerItemKVOContextState];
    }
}

- (void)removeKVOWithPlayer:(AVPlayer *)player {
    if (player != nil) {
        [player removeObserver:self forKeyPath:@"error"];
        
        // kvo监听系统播放器的暂停播放状态（之前监听播放速度rate来判断状态，可能不准，监听timeControlStatus是最准的）
        if (@available(iOS 10.0, macOS 10.12, *)) {
            [player removeObserver:self forKeyPath:@"timeControlStatus"];
        } else {
            [player removeObserver:self forKeyPath:@"rate"];
        }
        
        [player removeObserver:self forKeyPath:@"airPlayVideoActive"];
        [player removeObserver:self forKeyPath:@"status"];
    }
}

- (void)handleAVPlayerTimeControlStatusChanged {
    BOOL isPlayingState = NO;
    if (@available(iOS 10.0, macOS 10.12, *)) {
        isPlayingState = self.avPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying
                         || self.avPlayer.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate;
    } else {
        isPlayingState = (self.avPlayer.rate != 0);
    }
    if (isPlayingState && self.playerState != FTXAVPlayerStatePlaying) {
        FTXLOGI(@"[%@]playerStateDidChange:playing", kPipTag);
        self.playerState = FTXAVPlayerStatePlaying;
    } else if (!isPlayingState && self.playerState == FTXAVPlayerStatePlaying) {
        FTXLOGI(@"[%@]playerStateDidChange:paused", kPipTag);
        // 换源之后，播放完成前一刻，监听系统播放器TimeControlStatus属性变为暂停状态，这不是用户调用的暂停，不需要回抛暂停
        if (self.currentPositionMs == self.durationMs) {
            FTXLOGI(@"[%@]playerStateDidChange:complete, duration:%lld == currentPosition:%lld",
                    kPipTag, self.durationMs, self.currentPositionMs);
            return;
        }
        self.playerState = FTXAVPlayerStatePaused;
    }
}

@end
