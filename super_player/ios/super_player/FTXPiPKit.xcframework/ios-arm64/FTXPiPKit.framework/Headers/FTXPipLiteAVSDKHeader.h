//
//  FTXPipLiteAVSDKHeader.h
//  FTXPiPKit
//
//  Created by kongdywang on 14.3.25.
//

#ifndef FTXPipLiteAVSDKHeader_h
#define FTXPipLiteAVSDKHeader_h

#if __has_include(<TXLiteAVSDK_Player/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#elif __has_include(<TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Player_Premium/TXLiteAVSDK.h>
#elif __has_include(<TXLiteAVSDK_Professional/TXLiteAVSDK.h>)
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>
#else
#import "TXLiteAVSDK.h"
#endif

#endif /* FTXPipLiteAVSDKHeader_h */


