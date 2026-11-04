// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPREDOWNLOADFILEHELPERDELEGATE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPREDOWNLOADFILEHELPERDELEGATE_H_

#import <Foundation/Foundation.h>
#if __has_include(<TXLiteAVSDK_Player/TXVodPreloadManager.h>)
#import <TXLiteAVSDK_Player/TXVodPreloadManager.h>
#import <TXLiteAVSDK_Player/TXVodDownloadManager.h>
#elif __has_include(<TXLiteAVSDK_Player_Premium/TXVodPreloadManager.h>)
#import <TXLiteAVSDK_Player_Premium/TXVodPreloadManager.h>
#import <TXLiteAVSDK_Player_Premium/TXVodDownloadManager.h>
#elif __has_include(<TXLiteAVSDK_Professional/TXVodPreloadManager.h>)
#import <TXLiteAVSDK_Professional/TXVodPreloadManager.h>
#import <TXLiteAVSDK_Professional/TXVodDownloadManager.h>
#else
#import <TXVodPreloadManager.h>
#import <TXVodDownloadManager.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^FTXPreDownloadOnStart)(long tmpTaskId, int taskID, NSString* fileId, NSString* url, NSDictionary* param);
typedef void (^FTXPreDownloadOnCompelete)(int taskID, NSString* url);
typedef void (^FTXPreDownloadOnError)(long tmpTaskId, int taskID, NSString* url, NSError* error);

@interface TXPredownloadFileHelperDelegate : NSObject<TXVodPreloadManagerDelegate>

- (instancetype)initWithBlock:(long)tmpTaskId start:(FTXPreDownloadOnStart)onStart
                     complete:(FTXPreDownloadOnCompelete)onComplete
                        error:(FTXPreDownloadOnError)onError;

@end

NS_ASSUME_NONNULL_END
#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPREDOWNLOADFILEHELPERDELEGATE_H_
