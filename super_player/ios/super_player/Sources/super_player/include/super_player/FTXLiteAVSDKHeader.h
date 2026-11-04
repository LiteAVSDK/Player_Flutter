//
//  FTXLiteAVSDKHeader.h
//  super_player
//
//  Created by Kongdywang on 2024/2/27.
//

#ifndef FTXLiteAVSDKHeader_h
#define FTXLiteAVSDKHeader_h

#define SDK_IS_PLAYER         0
#define SDK_IS_PREMIUM        0
#define SDK_IS_PRO            0
#define SDK_IS_CUSTOM         0

// 2. 根据包含情况重定义标识为 1 (True)
#if __has_include(<TXLiteAVSDK_Player/TXLiteAVSDK.h>)
    #import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
    #undef  SDK_IS_PLAYER
    #define SDK_IS_PLAYER      1

#elif __has_include(<TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>)
    #import <TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>
    #undef  SDK_IS_PREMIUM
    #define SDK_IS_PREMIUM     1

#elif __has_include(<TXLiteAVSDK_Professional/TXLiteAVSDK.h>)
    #import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
    #undef  SDK_IS_PRO
    #define SDK_IS_PRO         1

#else
    #import "TXLiteAVSDK.h"
    #undef  SDK_IS_CUSTOM
    #define SDK_IS_CUSTOM      1
#endif

#endif /* FTXLiteAVSDKHeader_h */
