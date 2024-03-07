// Copyright (c) 2022 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import "FTXVodPlayerDispatcher.h"

@implementation FTXVodPlayerDispatcher

- (instancetype)initWithBridge:(id<ITXPlayersBridge>)dataBridge {
    if(self = [self init]) {
        self.bridge = dataBridge;
    }
    return self;;
}


- (nullable BoolMsg *)enableHardwareDecodeEnable:(nonnull BoolPlayerMsg *)enable error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[enable.playerId];
    if(api) {
        return [api enableHardwareDecodeEnable:enable error:error];
    }
    return nil;
}

- (nullable IntMsg *)enterPictureInPictureModePipParamsMsg:(nonnull PipParamsPlayerMsg *)pipParamsMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[pipParamsMsg.playerId];
    if(api) {
        return [api enterPictureInPictureModePipParamsMsg:pipParamsMsg error:error];
    }
    return nil;
}

- (void)exitPictureInPictureModePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api exitPictureInPictureModePlayerMsg:playerMsg error:error];
    }
}

- (nullable IntMsg *)getBitrateIndexPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getBitrateIndexPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable DoubleMsg *)getBufferDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getBufferDurationPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable DoubleMsg *)getCurrentPlaybackTimePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getCurrentPlaybackTimePlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable DoubleMsg *)getDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getDurationPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable IntMsg *)getHeightPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getHeightPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable UInt8ListMsg *)getImageSpriteTime:(nonnull DoublePlayerMsg *)time error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[time.playerId];
    if(api) {
        return [api getImageSpriteTime:time error:error];
    }
    return nil;
}

- (nullable DoubleMsg *)getPlayableDurationPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getPlayableDurationPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable ListMsg *)getSupportedBitratePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getSupportedBitratePlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable IntMsg *)getWidthPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api getWidthPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (void)initImageSpriteSpriteInfo:(nonnull StringListPlayerMsg *)spriteInfo error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[spriteInfo.playerId];
    if(api) {
        [api initImageSpriteSpriteInfo:spriteInfo error:error];
    }
}

- (nullable IntMsg *)initializeOnlyAudio:(nonnull BoolPlayerMsg *)onlyAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[onlyAudio.playerId];
    if(api) {
        return [api initializeOnlyAudio:onlyAudio error:error];
    }
    return nil;
}

- (nullable BoolMsg *)isLoopPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api isLoopPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable BoolMsg *)isPlayingPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api isPlayingPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (void)pausePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api pausePlayerMsg:playerMsg error:error];
    }
}

- (void)resumePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api resumePlayerMsg:playerMsg error:error];
    }
}

- (void)seekProgress:(nonnull DoublePlayerMsg *)progress error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[progress.playerId];
    if(api) {
        [api seekProgress:progress error:error];
    }
}

- (void)setAudioPlayOutVolumeVolume:(nonnull IntPlayerMsg *)volume error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[volume.playerId];
    if(api) {
        [api setAudioPlayOutVolumeVolume:volume error:error];
    }
}

- (void)setAutoPlayIsAutoPlay:(nonnull BoolPlayerMsg *)isAutoPlay error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[isAutoPlay.playerId];
    if(api) {
        [api setAutoPlayIsAutoPlay:isAutoPlay error:error];
    }
}

- (void)setBitrateIndexIndex:(nonnull IntPlayerMsg *)index error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[index.playerId];
    if(api) {
        [api setBitrateIndexIndex:index error:error];
    }
}

- (void)setConfigConfig:(nonnull FTXVodPlayConfigPlayerMsg *)config error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[config.playerId];
    if(api) {
        [api setConfigConfig:config error:error];
    }
}

- (void)setLoopLoop:(nonnull BoolPlayerMsg *)loop error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[loop.playerId];
    if(api) {
        [api setLoopLoop:loop error:error];
    }
}

- (void)setMuteMute:(nonnull BoolPlayerMsg *)mute error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[mute.playerId];
    if(api) {
        [api setMuteMute:mute error:error];
    }
}

- (void)setRateRate:(nonnull DoublePlayerMsg *)rate error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[rate.playerId];
    if(api) {
        [api setRateRate:rate error:error];
    }
}

- (nullable BoolMsg *)setRequestAudioFocusFocus:(nonnull BoolPlayerMsg *)focus error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[focus.playerId];
    if(api) {
        return [api setRequestAudioFocusFocus:focus error:error];
    }
    return nil;
}

- (void)setStartTimeStartTime:(nonnull DoublePlayerMsg *)startTime error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[startTime.playerId];
    if(api) {
        [api setStartTimeStartTime:startTime error:error];
    }
}

- (void)setTokenToken:(nonnull StringPlayerMsg *)token error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[token.playerId];
    if(api) {
        [api setTokenToken:token error:error];
    }
}

- (nullable BoolMsg *)startVodPlayUrl:(nonnull StringPlayerMsg *)url error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[url.playerId];
    if(api) {
        return [api startVodPlayUrl:url error:error];
    }
    return nil;
}

- (void)startVodPlayWithParamsParams:(nonnull TXPlayInfoParamsPlayerMsg *)params error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[params.playerId];
    if(api) {
        [api startVodPlayWithParamsParams:params error:error];
    }
}

- (nullable BoolMsg *)stopIsNeedClear:(nonnull BoolPlayerMsg *)isNeedClear error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterVodPlayerApi> api = self.bridge.getPlayers[isNeedClear.playerId];
    if(api) {
        return [api stopIsNeedClear:isNeedClear error:error];
    }
    return nil;
}

@end


