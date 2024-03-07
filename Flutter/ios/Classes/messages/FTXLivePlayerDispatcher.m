// Copyright (c) 2022 Tencent. All rights reserved.
#import <Foundation/Foundation.h>
#import "FTXLivePlayerDispatcher.h"

@implementation FTXLivePlayerDispatcher

- (instancetype)initWithBridge:(id<ITXPlayersBridge>)dataBridge {
    if(self = [self init]) {
        self.bridge = dataBridge;
    }
    return self;;
}

- (nullable BoolMsg *)enableHardwareDecodeEnable:(nonnull BoolPlayerMsg *)enable error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[enable.playerId];
    if(api) {
        return [api enableHardwareDecodeEnable:enable error:error];
    }
    return nil;
}

- (nullable IntMsg *)enterPictureInPictureModePipParamsMsg:(nonnull PipParamsPlayerMsg *)pipParamsMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[pipParamsMsg.playerId];
    if(api) {
        return [api enterPictureInPictureModePipParamsMsg:pipParamsMsg error:error];
    }
    return nil;
}

- (void)exitPictureInPictureModePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api exitPictureInPictureModePlayerMsg:playerMsg error:error];
    }
}

- (nullable IntMsg *)initializeOnlyAudio:(nonnull BoolPlayerMsg *)onlyAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[onlyAudio.playerId];
    if(api) {
        return [api initializeOnlyAudio:onlyAudio error:error];
    }
    return nil;
}

- (nullable BoolMsg *)isPlayingPlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api isPlayingPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (void)pausePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api pausePlayerMsg:playerMsg error:error];
    }
}

- (void)resumePlayerMsg:(nonnull PlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        [api resumePlayerMsg:playerMsg error:error];
    }
}

- (void)setAppIDAppId:(nonnull StringPlayerMsg *)appId error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[appId.playerId];
    if(api) {
        [api setAppIDAppId:appId error:error];
    }
}

- (void)setConfigConfig:(nonnull FTXLivePlayConfigPlayerMsg *)config error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[config.playerId];
    if(api) {
        [api setConfigConfig:config error:error];
    }
}

- (void)setLiveModeMode:(nonnull IntPlayerMsg *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[mode.playerId];
    if(api) {
        [api setLiveModeMode:mode error:error];
    }
}

- (void)setMuteMute:(nonnull BoolPlayerMsg *)mute error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[mute.playerId];
    if(api) {
        [api setMuteMute:mute error:error];
    }
}

- (void)setVolumeVolume:(nonnull IntPlayerMsg *)volume error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[volume.playerId];
    if(api) {
        [api setVolumeVolume:volume error:error];
    }
}

- (nullable BoolMsg *)startLivePlayPlayerMsg:(nonnull StringIntPlayerMsg *)playerMsg error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[playerMsg.playerId];
    if(api) {
        return [api startLivePlayPlayerMsg:playerMsg error:error];
    }
    return nil;
}

- (nullable BoolMsg *)stopIsNeedClear:(nonnull BoolPlayerMsg *)isNeedClear error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[isNeedClear.playerId];
    if(api) {
        return [api stopIsNeedClear:isNeedClear error:error];
    }
    return nil;
}

- (nullable IntMsg *)switchStreamUrl:(nonnull StringPlayerMsg *)url error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error { 
    id<TXFlutterLivePlayerApi> api = self.bridge.getPlayers[url.playerId];
    if(api) {
        return [api switchStreamUrl:url error:error];
    }
    return nil;
}

@end
