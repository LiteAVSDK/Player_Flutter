// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// 通用工具类
class CommonUtils {
  /// 通过分辨率获取下载对应的qualityId
  static int getDownloadQualityBySize(int width, int height) {
    if (width == null || height == null) {
      return DownloadQuality.QUALITY_FLU;
    }
    int minValue = min(width, height);
    int cacheQualityIndex;
    if (minValue == 240 || minValue == 180) {
      cacheQualityIndex = DownloadQuality.QUALITY_FLU;
    } else if (minValue == 480 || minValue == 360) {
      cacheQualityIndex = DownloadQuality.QUALITY_SD;
    } else if (minValue == 540) {
      cacheQualityIndex = DownloadQuality.QUALITY_SD;
    } else if (minValue == 720) {
      cacheQualityIndex = DownloadQuality.QUALITY_HD;
    } else if (minValue == 1080) {
      cacheQualityIndex = DownloadQuality.QUALITY_FHD;
    } else if (minValue == 1440) {
      cacheQualityIndex = DownloadQuality.QUALITY_2K;
    } else if (minValue == 2160) {
      cacheQualityIndex = DownloadQuality.QUALITY_4K;
    } else {
      cacheQualityIndex = DownloadQuality.QUALITY_UNK;
    }
    return cacheQualityIndex;
  }
}
