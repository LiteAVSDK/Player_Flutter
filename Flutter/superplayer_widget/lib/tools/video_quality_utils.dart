// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// video quality utils
class VideoQualityUtils {
  static const TAG = "VideoQualityUtils";

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
    VideoQuality quality = new VideoQuality();
    quality.bitrate = stream.bitrate;
    quality.name = stream.id;
    quality.title = stream.name;
    quality.url = stream.url;
    quality.index = -1;
    return quality;
  }

  /// convert to quality by FTXBitrateItem
  static VideoQuality convertToVideoQualityByBitrate(BuildContext context, FTXBitrateItem bitrateItem) {
    VideoQuality quality = new VideoQuality();
    quality.bitrate = bitrateItem.bitrate;
    quality.index = bitrateItem.index;
    quality.height = bitrateItem.height;
    quality.width = bitrateItem.width;
    formatVideoQuality(quality);
    return quality;
  }

  /// format quality title by size
  static void formatVideoQuality(VideoQuality quality) {
    int minValue = min(quality.width, quality.height);
    if (minValue == 240 || minValue == 180) {
      quality.title = "${StringResource.QUALITY_FLU} (${minValue}dp)";
    } else if (minValue == 480 || minValue == 360) {
      quality.title = "${StringResource.QUALITY_SD} (${minValue}dp)";
    } else if (minValue == 540) {
      quality.title = "${StringResource.QUALITY_FSD} (${minValue}dp)";
    } else if (minValue == 720) {
      quality.title = "${StringResource.QUALITY_HD} (${minValue}dp)";
    } else if (minValue == 1080) {
      quality.title = "${StringResource.QUALITY_FHD2} (${minValue}dp)";
    } else if (minValue == 1440) {
      quality.title = "${StringResource.QUALITY_2K} (${minValue}dp)";
    } else if (minValue == 2160) {
      quality.title = "${StringResource.QUALITY_4K} (${minValue}dp)";
    } else {
      quality.title = " (${minValue}dp)";
    }
  }

  /// convert to quality by FTXBitrateItem and resolutionNames
  static VideoQuality convertToVideoQualityByResolution(
      FTXBitrateItem bitrateItem, List<ResolutionName> resolutionNames) {
    VideoQuality quality = new VideoQuality();
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
}
