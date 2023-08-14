// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class PlayInfoStream {
  int height = 0;
  int width = 0;
  int size = 0;
  int duration = 0;
  int bitrate = 0;
  int definition = 0;
  String id = "";
  String name = "";
  String url = "";
}

class VideoQuality {
  int index = 0;
  int bitrate = 0;
  int width = 0;
  int height = 0;
  String name = "";
  String title = "";
  String url = "";

  VideoQuality({int? index, String? title, String? url}) {
    this.index = index ?? this.index;
    this.title = title ?? this.title;
    this.url = url ?? this.url;
  }
}

class VideoClassification {
  String id = "";
  String name = "";
  List<int> definitionList = [];
}

class FTXBitrateItem {
  int index = 0;
  int width = 0;
  int height = 0;
  int bitrate = 0;

  FTXBitrateItem(this.index, this.width, this.height, this.bitrate);
}

class ResolutionName {
  String name = ""; // Video resolution name.
  String type = ""; // Type. Possible values are `video` and `audio`.
  int width = 0;
  int height = 0;
}

class PlayImageSpriteInfo {
  List<String> imageUrls = []; // Image link URL.
  String webVttUrl = ""; // WebVTT description file download URL.

  String toString() {
    return "TCPlayImageSpriteInfo{imageUrls=${imageUrls.toString()}, webVttUrl='$webVttUrl'\'}";
  }
}

class PlayKeyFrameDescInfo {
  String content = ""; // Description information.
  double time = 0; // Keyframe time (in seconds).

  String toString() {
    return "TCPlayKeyFrameDescInfo{content='$content\', time=$time}";
  }
}

/// superplayer play model
class SuperPlayerModel {
  static const PLAY_ACTION_AUTO_PLAY = 0;
  static const PLAY_ACTION_MANUAL_PLAY = 1;
  static const PLAY_ACTION_PRELOAD = 2;

  int appId = 0;
  String videoURL = "";
  List<SuperPlayerUrl> multiVideoURLs = [];
  int defaultPlayIndex = 0;
  SuperPlayerVideoId? videoId;
  String title = "";
  String coverUrl = ""; // coverUrl from net
  String customeCoverUrl = ""; // custome video cover image
  int duration = 0; // video duration
  // Whether to enable download capability. It is disabled by default.
  bool isEnableDownload = false;

  // Feed stream video description
  String videoDescription = "";
  String videoMoreDescription = "";

  int playAction = PLAY_ACTION_AUTO_PLAY;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    List<Map> videoURLs = [];
    for (var url in multiVideoURLs) {
      videoURLs.add({
        "title": url.qualityName,
        "url": url.url,
      });
    }
    json["multiVideoURLs"] = videoURLs;
    json["appId"] = appId;
    json["title"] = title;
    json["videoURL"] = videoURL;
    json["defaultPlayIndex"] = defaultPlayIndex;
    json["videoDescription"] = videoDescription;
    json["videoMoreDescription"] = videoMoreDescription;
    json["coverUrl"] = coverUrl;
    json["playAction"] = playAction;
    if (videoId != null && videoId!.fileId.isNotEmpty) {
      json["videoId"] = {"fileId": videoId!.fileId, "psign": videoId!.psign};
    }
    return json;
  }
}

class EncryptedStreamingInfo {
  String drmType = "";
  String url = "";

  String toString() {
    return "TCEncryptedStreamingInfo{" +
        ", drmType='" +
        drmType +
        '\'' +
        ", url='" +
        url +
        '\'' +
        '}';
  }
}

class SuperPlayerUrl {
  String qualityName = "";
  String url = "";
}

class SuperPlayerVideoId {
  String fileId = ""; // Tencent Cloud Video fileId
  String psign = ""; // Enabling anti-leech is required for `v4`.
}

/// Progress bar tick information.
/// 进度条打点信息
class SliderPoint {
  Color pointColor = Colors.white;
  double progress = 0;
}
