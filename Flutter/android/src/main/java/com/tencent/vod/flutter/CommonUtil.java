// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.os.Bundle;

import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * 通用工具类
 */
public class CommonUtil {

    static final Map<Integer, Integer> DOWNLOAD_STATE_MAP = new HashMap<Integer, Integer>() {{
        put(TXVodDownloadMediaInfo.STATE_INIT, FTXEvent.EVENT_DOWNLOAD_START);
        put(TXVodDownloadMediaInfo.STATE_START, FTXEvent.EVENT_DOWNLOAD_PROGRESS);
        put(TXVodDownloadMediaInfo.STATE_FINISH, FTXEvent.EVENT_DOWNLOAD_FINISH);
        put(TXVodDownloadMediaInfo.STATE_STOP, FTXEvent.EVENT_DOWNLOAD_STOP);
        put(TXVodDownloadMediaInfo.STATE_ERROR, FTXEvent.EVENT_DOWNLOAD_ERROR);
    }};

    public static Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap<>();
        if (event != 0) {
            param.put("event", event);
        }

        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }

        return param;
    }

    public static int getCacheVideoQuality(Integer width, Integer height) {
        if (width == null || height == null) {
            return TXVodDownloadDataSource.QUALITY_FLU;
        }
        int minValue = Math.min(width, height);
        int cacheQualityIndex;
        if (minValue == 240 || minValue == 180) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_FLU;
        } else if (minValue == 480 || minValue == 360) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_SD;
        } else if (minValue == 540) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_SD;
        } else if (minValue == 720) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_HD;
        } else if (minValue == 1080) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_FHD;
        } else if (minValue == 1440) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_2K;
        } else if (minValue == 2160) {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_4K;
        } else {
            cacheQualityIndex = TXVodDownloadDataSource.QUALITY_UNK;
        }
        return cacheQualityIndex;
    }

    public static int getDownloadEventByState(int mediaInfoDownloadState) {
        Integer event = DOWNLOAD_STATE_MAP.get(mediaInfoDownloadState);
        return null != event ? event : FTXEvent.EVENT_DOWNLOAD_ERROR;
    }
}
