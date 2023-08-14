// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// video quality utils
class VideoQualityUtils {
  static const TAG = "VideoQualityUtils";
  static Map<int, String> downloadQualityMap = {
    DownloadQuality.QUALITY_FLU: FSPLocal.current.txSpwFlu,
    DownloadQuality.QUALITY_SD: FSPLocal.current.txSpwSd,
    DownloadQuality.QUALITY_HD: FSPLocal.current.txSpwHd,
    DownloadQuality.QUALITY_FHD: FSPLocal.current.txSpwFhd,
    DownloadQuality.QUALITY_OD: FSPLocal.current.txSpwOd,
    DownloadQuality.QUALITY_240P: FSPLocal.current.txSpw240p,
    DownloadQuality.QUALITY_360P: FSPLocal.current.txSpw360p,
    DownloadQuality.QUALITY_480P: FSPLocal.current.txSpw480p,
    DownloadQuality.QUALITY_540P: FSPLocal.current.txSpw540p,
    DownloadQuality.QUALITY_720P: FSPLocal.current.txSpw720p,
    DownloadQuality.QUALITY_1080P: FSPLocal.current.txSpw1080p,
    DownloadQuality.QUALITY_2K: FSPLocal.current.txSpw2k,
    DownloadQuality.QUALITY_4K: FSPLocal.current.txSpw4k,
    DownloadQuality.QUALITY_UNK: "",
  };

  /// convert to quality by transcodePlayList
  static List<VideoQuality> convertToVideoQualityList(Map<String, PlayInfoStream> transcodePlayList) {
    List<VideoQuality> videoQualityList = [];
    for (String classification in transcodePlayList.keys) {
      VideoQuality videoQuality = convertToVideoQuality(transcodePlayList[classification]!);
      videoQualityList.add(videoQuality);
    }

    return videoQualityList;
  }

  /// convert to quality by PlayInfoStream
  static VideoQuality convertToVideoQuality(PlayInfoStream stream) {
    VideoQuality quality = VideoQuality();
    quality.bitrate = stream.bitrate;
    quality.name = stream.id;
    quality.title = stream.name;
    quality.url = stream.url;
    quality.index = -1;
    return quality;
  }

  /// convert to quality by FTXBitrateItem
  static VideoQuality convertToVideoQualityByBitrate(BuildContext context, FTXBitrateItem bitrateItem) {
    VideoQuality quality = VideoQuality();
    quality.bitrate = bitrateItem.bitrate;
    quality.index = bitrateItem.index;
    quality.height = bitrateItem.height;
    quality.width = bitrateItem.width;
    quality.title = formatVideoQuality(quality.width, quality.height);
    return quality;
  }

  /// format quality title by size
  static String formatVideoQuality(int width, int height) {
    int minValue = min(width, height);
    String title = " (${minValue}dp)";
    if (minValue == 240 || minValue == 180) {
      title = FSPLocal.current.txSpw240p;
    } else if (minValue == 360) {
      title = FSPLocal.current.txSpw360p;
    } else if (minValue == 480) {
      title = FSPLocal.current.txSpw480p;
    } else if (minValue == 540) {
      title = FSPLocal.current.txSpw540p;
    } else if (minValue == 720) {
      title = FSPLocal.current.txSpw720p;
    } else if (minValue == 1080) {
      title = FSPLocal.current.txSpw1080p;
    } else if (minValue == 1440) {
      title = FSPLocal.current.txSpw2k;
    } else if (minValue == 2160) {
      title = FSPLocal.current.txSpw4k;
    }
    return title;
  }

  /// convert to quality by FTXBitrateItem and resolutionNames
  static VideoQuality convertToVideoQualityByResolution(
      FTXBitrateItem bitrateItem, List<ResolutionName> resolutionNames) {
    VideoQuality quality = VideoQuality();
    quality.bitrate = bitrateItem.bitrate;
    quality.index = bitrateItem.index;
    bool getName = false;
    for (ResolutionName resolutionName in resolutionNames) {
      if (((resolutionName.width == bitrateItem.width && resolutionName.height == bitrateItem.height) ||
              (resolutionName.width == bitrateItem.height && resolutionName.height == bitrateItem.width)) &&
          "video" == resolutionName.type) {
        quality.title = resolutionName.name;
        getName = true;
        break;
      }
    }
    if (!getName) {
      LogUtils.d(TAG, "error: could not get quality name!");
    }
    return quality;
  }

  /// transform quality name
  static String transformToQualityName(String title) {
    String qualityName = title;
    if (title.contains("(")) {
      if (title[0] == ' ' && title.contains(")")) {
        qualityName = title.substring(title.indexOf('(') + 1, title.indexOf(')'));
      } else {
        qualityName = title.substring(0, title.indexOf('('));
      }
    }
    return qualityName;
  }

  /// Convert `videoQuality` to the video quality ID required for video download.
  /// 根据videoQuality，转化为视频下载需要用到的画质id
  /// @param width 宽度
  /// @param height 高度
  /// @return [DownloadQuality];
  static int getCacheVideoQualityIndex(int width, int height) {
    return CommonUtils.getDownloadQualityBySize(width, height);
  }

  static String getNameByCacheQualityId(int cacheQualityId) {
    return downloadQualityMap[cacheQualityId] ?? "";
  }
}
