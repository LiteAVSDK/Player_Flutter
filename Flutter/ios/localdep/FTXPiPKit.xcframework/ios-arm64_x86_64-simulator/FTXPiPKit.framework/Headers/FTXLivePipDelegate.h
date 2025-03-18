// Copyright (c) 2024 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXLIVEPIPDELEGATE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXLIVEPIPDELEGATE_H_

#import "FTXPipLiteAVSDKHeader.h"
#import "FTXPipConstants.h"

@protocol FTXLivePipDelegate <NSObject>

- (void)pictureInPictureStateDidChange:(TX_VOD_PLAYER_PIP_STATE)status;

- (void)pictureInPictureErrorDidOccur:(FTX_LIVE_PIP_ERROR)errorStatus;

@end

#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_FTXLIVEPIPDELEGATE_H_
