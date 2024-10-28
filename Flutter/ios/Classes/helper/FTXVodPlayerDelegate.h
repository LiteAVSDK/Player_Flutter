// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXVODPLAYERDELEGATE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXVODPLAYERDELEGATE_H_

@protocol FTXVodPlayerDelegate <NSObject>

- (void)onPlayerPipRequestStart;

- (void)onPlayerPipStateDidStart;

- (void)onPlayerPipStateWillStop;

- (void)onPlayerPipStateDidStop;

- (void)onPlayerPipStateRestoreUI:(double)playTime;;

- (void)onPlayerPipStateError:(NSInteger)errorId;

- (void) releasePlayerInner:(NSNumber*)playerId;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXVODPLAYERDELEGATE_H_
