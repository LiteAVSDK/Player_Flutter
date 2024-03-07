// Copyright (c) 2022 Tencent. All rights reserved.
#import "TXPredownloadFileHelperDelegate.h"

@interface TXPredownloadFileHelperDelegate()

@property (nonatomic, assign)long tmpTaskId;
@property (nonatomic, strong)FTXPreDownloadOnStart onStartBlock;
@property (nonatomic, strong)FTXPreDownloadOnCompelete onCompleteBlock;
@property (nonatomic, strong)FTXPreDownloadOnError onErrorBlock;

@end

@implementation TXPredownloadFileHelperDelegate

- (instancetype)initWithBlock:(long)tmpTaskId start:(FTXPreDownloadOnStart)onStart complete:(FTXPreDownloadOnCompelete)onComplete error:(FTXPreDownloadOnError)onError {
        self = [super init];
        if (self) {
            self.tmpTaskId = tmpTaskId;
            self.onStartBlock = onStart;
            self.onCompleteBlock = onComplete;
            self.onErrorBlock = onError;
        }
        return self;
}

- (void)onStart:(int)taskID fileId:(NSString *)fileId url:(NSString *)url param:(NSDictionary *)param {
    if (self.onStartBlock) {
        self.onStartBlock(self.tmpTaskId, taskID, fileId, url, param);
    }
}

- (void)onComplete:(int)taskID url:(NSString *)url {
    if (self.onCompleteBlock) {
        self.onCompleteBlock(taskID, url);
    }
}

- (void)onError:(int)taskID url:(NSString *)url error:(NSError *)error {
    if (self.onErrorBlock) {
        self.onErrorBlock(self.tmpTaskId, taskID, url, error);
    }
}

@end
