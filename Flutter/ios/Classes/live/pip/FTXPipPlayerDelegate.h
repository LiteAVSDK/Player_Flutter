// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPPLAYERDELEGATE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPPLAYERDELEGATE_H_

#import "FTXPlayerConstants.h"

@protocol FTXPipPlayerDelegate <NSObject>

-(void)playerStateDidChange:(FTXAVPlayerState)playerState;

@end


#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_LIVE_PIP_FTXPIPPLAYERDELEGATE_H_
