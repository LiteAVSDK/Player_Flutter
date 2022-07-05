// Copyright (c) 2022 Tencent. All rights reserved.

#import "CommonUtil.h"

@implementation CommonUtil

+ (int)getCacheVideoQuality:(int)width height:(int)pHeight{
    int minValue = MIN(width, pHeight);
    int cacheQualityIndex;
   if (minValue == 240 || minValue == 180) {
       cacheQualityIndex = TXVodQualityFLU;
   } else if (minValue == 480 || minValue == 360) {
       cacheQualityIndex = TXVodQualitySD;
   } else if (minValue == 540) {
       cacheQualityIndex = TXVodQualitySD;
   } else if (minValue == 720) {
       cacheQualityIndex = TXVodQualityHD;
   } else if (minValue == 1080) {
       cacheQualityIndex = TXVodQualityFHD;
   } else if (minValue == 1440) {
       cacheQualityIndex = TXVodQuality2K;
   } else if (minValue == 2160) {
       cacheQualityIndex = TXVodQuality4K;
   } else {
       cacheQualityIndex = TXVodQualityFLU;
   }
   return cacheQualityIndex;
}

+ (int)getDownloadEventByState:(int)downloadState{
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
    return result;
}


@end
