// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPREDOWNLOADFILEHELPERDELEGATE_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_HELPER_TXPREDOWNLOADFILEHELPERDELEGATE_H_

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TXVodPreloadManager.h>

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
