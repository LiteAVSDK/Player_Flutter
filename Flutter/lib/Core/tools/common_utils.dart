// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// Common utility class
/// 通用工具类
class CommonUtils {
  /// Get the corresponding qualityId for download based on the resolution
  /// 通过分辨率获取下载对应的qualityId
  static int getDownloadQualityBySize(int width, int height) {
    int minValue = min(width, height);
    int cacheQualityIndex;
    if (minValue > 0 && minValue <= 240) {
      cacheQualityIndex = DownloadQuality.QUALITY_240P;
    } else if (minValue > 240 && minValue <= 480) {
      cacheQualityIndex = DownloadQuality.QUALITY_480P;
    } else if (minValue > 480 && minValue <= 540) {
      cacheQualityIndex = DownloadQuality.QUALITY_540P;
    } else if (minValue > 540 && minValue <= 720) {
      cacheQualityIndex = DownloadQuality.QUALITY_720P;
    } else if (minValue > 720 && minValue <= 1080) {
      cacheQualityIndex = DownloadQuality.QUALITY_1080P;
    } else if (minValue > 1080 && minValue <= 1440) {
      cacheQualityIndex = DownloadQuality.QUALITY_2K;
    } else if (minValue > 1440 && minValue <= 2160) {
      cacheQualityIndex = DownloadQuality.QUALITY_4K;
    } else {
      cacheQualityIndex = DownloadQuality.QUALITY_UNK;
    }
    return cacheQualityIndex;
  }
}
