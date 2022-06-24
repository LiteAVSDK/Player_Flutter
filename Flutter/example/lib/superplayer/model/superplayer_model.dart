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
  String name = ""; // 画质名称
  String type = ""; // 类型 可能的取值有 video 和 audio
  int width = 0;
  int height = 0;
}

class PlayImageSpriteInfo {
  List<String> imageUrls = []; // 图片链接URL
  String webVttUrl = ""; // web vtt描述文件下载URL

  String toString() {
    return "TCPlayImageSpriteInfo{imageUrls=${imageUrls.toString()}, webVttUrl='$webVttUrl'\'}";
  }
}

class PlayKeyFrameDescInfo {
  String content = ""; // 描述信息
  double time = 0; // 关键帧时间(秒)

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

  // feed流视频描述
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
  String fileId = ""; // 腾讯云视频fileId
  String psign = ""; // v4 开启防盗链必填
}
