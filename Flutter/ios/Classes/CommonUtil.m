// Copyright (c) 2022 Tencent. All rights reserved.

#import "CommonUtil.h"

@implementation CommonUtil

+ (NSNumber*)getDownloadEventByState:(int)downloadState{
    int result;
    switch (downloadState) {
        case TXVodDownloadMediaInfoStateInit:
            result = EVENT_DOWNLOAD_START;
            break;
        case TXVodDownloadMediaInfoStateStart:
            result = EVENT_DOWNLOAD_PROGRESS;
            break;
        case TXVodDownloadMediaInfoStateStop:
            result = EVENT_DOWNLOAD_STOP;
            break;
        case TXVodDownloadMediaInfoStateError:
            result = EVENT_DOWNLOAD_ERROR;
            break;
        case TXVodDownloadMediaInfoStateFinish:
            result = EVENT_DOWNLOAD_FINISH;
            break;
        default:
            result = EVENT_DOWNLOAD_ERROR;
            break;
    }
    return [NSNumber numberWithInt:result];;
}


@end
