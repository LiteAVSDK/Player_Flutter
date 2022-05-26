part of SuperPlayer;

/// v4 request data parser
class PlayInfoParserV4 implements PlayInfoParser {
  @override
  String name = "";

  @override
  String coverUrl = "";

  @override
  String _url = "";

  @override
  int duration = 0;

  @override
  List<ResolutionName> resolutionNameList = [];

  @override
  List<VideoQuality> videoQualityList = [];

  @override
  PlayImageSpriteInfo? imageSpriteInfo;

  @override
  List<PlayKeyFrameDescInfo>? keyFrameDescInfo;

  @override
  VideoQuality? defaultVideoQuality;

  @override
  String drmType = "";

  @override
  String token = "";

  @override
  List<EncryptedStreamingInfo> encryptedStreamingInfoList = [];

  String description = "";
  String? mRequestContext; //透传字段

  PlayInfoParserV4(String json) {
    _parseData(json);
  }

  _parseData(String data) {
    Map<String, dynamic> root = jsonDecode(data);
    Map<String, dynamic> media = root['media'];
    mRequestContext = root['context'];
    if (media.isNotEmpty) {
      Map<String, dynamic> basicInfo = media['basicInfo'];
      if (null != basicInfo) {
        name = basicInfo['name'];
        description = basicInfo['description'];
        coverUrl = basicInfo['coverUrl'];
        duration = basicInfo['duration'];
      }
      String audioVideoType = media['audioVideoType'];
      if (audioVideoType == 'AdaptiveDynamicStream') {
        Map<String, dynamic> streamingInfo = media['streamingInfo'];
        if (null != streamingInfo) {
          Map<String, dynamic> plainOutputRoot = streamingInfo['plainOutput'];
          if (null != plainOutputRoot) {
            _url = plainOutputRoot['url'];
            _parseSubStreams(plainOutputRoot['subStreams']);
          }
          List<dynamic> drmoutInfo = streamingInfo['drmOutput'];
          if (null != drmoutInfo) {
            encryptedStreamingInfoList = [];
            for (Map<String, dynamic> drmout in drmoutInfo) {
              EncryptedStreamingInfo info = new EncryptedStreamingInfo();
              drmType = drmout['type'];
              info.drmType = drmType;
              info.url = drmout['url'];
              encryptedStreamingInfoList.add(info);
              _parseSubStreams(drmout['subStreams']);
            }
          }
          token = streamingInfo["drmToken"];
        }
      } else if (audioVideoType == 'Transcode') {
        Map<String, dynamic> transcodeInfo = media['transcodeInfo'];
        if (transcodeInfo.isNotEmpty) {
          _url = transcodeInfo['url'];
        }
      } else if (audioVideoType == 'Original') {
        Map<String, dynamic> originalInfo = media['originalInfo'];
        if (originalInfo.isNotEmpty) {
          _url = originalInfo['url'];
        }
      }

      Map<String, dynamic> imageSpriteInfoJson = media['imageSpriteInfo'];
      if (null != imageSpriteInfoJson) {
        imageSpriteInfo = PlayImageSpriteInfo();
        imageSpriteInfo?.webVttUrl = imageSpriteInfoJson['webVttUrl'];
        List<String> imageUrls = imageSpriteInfoJson['imageUrls'];
        imageSpriteInfo?.imageUrls = imageUrls;
      }

      _parseKeyFrameDescList(media);
    }
  }

  _parseSubStreams(List<dynamic> substreams) {
    if (null != substreams) {
      resolutionNameList = [];
      for (Map<String, dynamic> substream in substreams) {
        ResolutionName resolutionName = ResolutionName();
        resolutionName.width = substream['width'];
        resolutionName.height = substream['height'];
        resolutionName.name = substream['resolutionName'];
        resolutionName.type = substream['type'];
        resolutionNameList.add(resolutionName);
      }
    }
  }

  _parseKeyFrameDescList(Map<String, dynamic> media) {
    Map<String, dynamic> keyFrameDescInfoJson = media['keyFrameDescInfo'];
    if (null != keyFrameDescInfoJson) {
      keyFrameDescInfo = [];
      List<Map<String, dynamic>> keyFrameDescList = keyFrameDescInfoJson['keyFrameDescList'];
      for (Map<String, dynamic> keyFrameDesc in keyFrameDescList) {
        PlayKeyFrameDescInfo info = PlayKeyFrameDescInfo();
        info.time = keyFrameDesc['timeOffset'];
        info.content = keyFrameDesc['content'];
        keyFrameDescInfo?.add(info);
      }
    }
  }

  @override
  String? getEncryptedURL(EncryptedURLType type) {
    for (EncryptedStreamingInfo info in encryptedStreamingInfoList) {
      if (info.drmType.toLowerCase() == type.value.toLowerCase()) {
        return info.url;
      }
    }
    return null;
  }

  @override
  String getUrl() {
    if (null != token && token.isNotEmpty) {
      return getEncryptedURL(EncryptedURLType.SIMPLEAES)!;
    }
    return _url;
  }
}
