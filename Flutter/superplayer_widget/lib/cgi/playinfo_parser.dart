// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// play info parser interface
abstract class PlayInfoParser {
  // video duration
  int duration = 0;
  // cover url
  String coverUrl = "";
  // video url
  String _url = "";
  // video name
  String name = "";
  // v2 quality list
  List<VideoQuality> videoQualityList = [];
  // v4 resolutionName list
  List<ResolutionName> resolutionNameList = [];
  // video image sprite info
  PlayImageSpriteInfo? imageSpriteInfo;
  // key frame desc
  List<PlayKeyFrameDescInfo>? keyFrameDescInfo;
  // default quality,only support v2
  VideoQuality? defaultVideoQuality;
  // v4 drmType
  String drmType = "";
  // v4 token
  String token = "";
  // v4 encrypted url info
  List<EncryptedStreamingInfo> encryptedStreamingInfoList = [];
  // v4 encrypted url
  String? getEncryptedURL(EncryptedURLType type);
  // getUrl
  String getUrl();
}