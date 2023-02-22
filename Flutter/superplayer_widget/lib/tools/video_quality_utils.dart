// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// video quality utils
class VideoQualityUtils {
  static const TAG = "VideoQualityUtils";
  static const Map<int, String> downloadQualityMap = {
    DownloadQuality.QUALITY_FLU: StringResource.QUALITY_FLU,
    DownloadQuality.QUALITY_SD: StringResource.QUALITY_SD,
    DownloadQuality.QUALITY_HD: StringResource.QUALITY_HD,
    DownloadQuality.QUALITY_FHD: StringResource.QUALITY_FHD,
    DownloadQuality.QUALITY_OD: StringResource.QUALITY_OD,
    DownloadQuality.QUALITY_240P: StringResource.QUALITY_240P,
    DownloadQuality.QUALITY_360P: StringResource.QUALITY_360P,
    DownloadQuality.QUALITY_480P: StringResource.QUALITY_480P,
    DownloadQuality.QUALITY_540P: StringResource.QUALITY_540P,
    DownloadQuality.QUALITY_720P: StringResource.QUALITY_720P,
    DownloadQuality.QUALITY_1080P: StringResource.QUALITY_1080P,
    DownloadQuality.QUALITY_2K: StringResource.QUALITY_2K,
    DownloadQuality.QUALITY_4K: StringResource.QUALITY_4K,
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
      title = StringResource.QUALITY_240P;
    } else if (minValue == 360) {
      title = StringResource.QUALITY_360P;
    } else if (minValue == 480) {
      title = StringResource.QUALITY_480P;
    } else if (minValue == 540) {
      title = StringResource.QUALITY_540P;
    } else if (minValue == 720) {
      title = StringResource.QUALITY_720P;
    } else if (minValue == 1080) {
      title = StringResource.QUALITY_1080P;
    } else if (minValue == 1440) {
      title = StringResource.QUALITY_2K;
    } else if (minValue == 2160) {
      title = StringResource.QUALITY_4K;
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
