//
//  FTXLiteAVSDKHeader.h
//  super_player
//
//  Created by Kongdywang on 2024/2/27.
//

#ifndef FTXLiteAVSDKHeader_h
#define FTXLiteAVSDKHeader_h

#if __has_include(<TXLiteAVSDK_Player/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#elif __has_include(<TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>
#elif __has_include(<TXLiteAVSDK_Professional/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
#else
#import "TXLiteAVSDK.h"
#endif


#endif /* FTXLiteAVSDKHeader_h */
