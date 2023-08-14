// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// v2 request data parser
class PlayInfoParserV2 implements PlayInfoParser {
  static const TAG = "PlayInfoParserV2";

  @override
  String name = "";

  @override
  String coverUrl = "";

  @override
  int duration = 0;

  @override
  String _url = "";

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

  String defaultVideoClassification = "";

  Map<String, PlayInfoStream> _transcodePlayList = new Map();
  PlayInfoStream? sourceStream;
  PlayInfoStream? masterPlayList; // Main video stream information.

  List<VideoClassification> videoClassificationList = []; // List of video quality information.

  PlayInfoParserV2(String json) {
    _parseData(json);
  }

  void _parseData(String data) {
    Map<String, dynamic> root = jsonDecode(data);

    int code = root['code'];
    String message = root['message'];
    String warning = root['warning'];
    if (code != 0) {
      return;
    }
    int version = root['version'];
    if (version == 2) {
      coverUrl = root['coverInfo']['coverUrl'] ?? "";

      Map<String, dynamic> videInfoRoot = root['videoInfo'];

      defaultVideoClassification = root['playerInfo']['defaultVideoClassification'] ?? "";
      _parseVideoClassificationList(root['playerInfo']);

      imageSpriteInfo = _parseImageSpriteInfo(root['imageSpriteInfo']);
      keyFrameDescInfo = _parseKeyFrameDescInfo(root['keyFrameDescInfo']);

      duration = videInfoRoot['sourceVideo']['duration'] ?? 0;
      name = videInfoRoot['basicInfo']['name'] ?? "";

      _parseMastPlayInfo(videInfoRoot);
      _parseTranscodeList(videInfoRoot);
      _parseSourceVideo(videInfoRoot);

      _parseVideoInfo();
    }
  }

  List<PlayKeyFrameDescInfo>? _parseKeyFrameDescInfo(dynamic keyFrameDescInfo) {
    if(null != keyFrameDescInfo && keyFrameDescInfo.isNotEmpty) {
      List<dynamic> keyFrameDescList = keyFrameDescInfo['keyFrameDescList'];
      if(keyFrameDescList.isNotEmpty) {
        List<PlayKeyFrameDescInfo> infoList = [];
        for(Map<String,dynamic> keyFrameInfo in keyFrameDescList) {
          PlayKeyFrameDescInfo info = PlayKeyFrameDescInfo();
          info.content = Uri.decodeFull(keyFrameInfo['content']);
          int timeOffset = keyFrameInfo['timeOffset'];
          info.time = (timeOffset / 1000.0); // Convert to seconds.
          infoList.add(info);
        }
        return infoList;
      }
    }
    return null;
  }

  PlayImageSpriteInfo? _parseImageSpriteInfo(dynamic imageSpriteInfo) {
    if(null != imageSpriteInfo && imageSpriteInfo.isNotEmpty) {
      List<dynamic> imageSpriteList = imageSpriteInfo['imageSpriteList'];
      if(imageSpriteList.isNotEmpty) {
       Map<String,dynamic> imageSpriteTemp =  imageSpriteList[imageSpriteList.length - 1]; // Get the last one to parse.
        PlayImageSpriteInfo info = PlayImageSpriteInfo();
       info.webVttUrl = imageSpriteTemp['webVttUrl'];
       // List<dynamic> can not transTo List<String>,so use loop assignment
       List<dynamic> imageUrlsTemp = imageSpriteTemp['imageUrls'];
       info.imageUrls = [];
       for(String imageUrl in imageUrlsTemp) {
         info.imageUrls.add(imageUrl);
       }
       return info;
      }
    }
    return null;
  }

  void _parseVideoClassificationList(Map<String, dynamic> playerInfoRoot) {
    List<VideoClassification> classList = [];
    if(null != playerInfoRoot['videoClassification']) {
      List<dynamic> videoClassificationRoot = playerInfoRoot['videoClassification'];
      for(Map<String, dynamic> object in videoClassificationRoot) {
        VideoClassification classification = new VideoClassification();
        classification.id =object["id"];
        classification.name = object["name"];

        List<int> definitionList = [];
        if(null != object['definitionList']) {
          List<dynamic> array =  object['definitionList'];
          for(int definition in array) {
            definitionList.add(definition);
          }
        }
        classification.definitionList = definitionList;
        classList.add(classification);
      }
    }
    videoClassificationList = classList;
  }


  void _parseMastPlayInfo(Map<String, dynamic> videInfoRoot) {
    if (null != videInfoRoot['masterPlayList']) {
      Map<String, dynamic> masterPlayRoot = videInfoRoot['masterPlayList'];
      masterPlayList = PlayInfoStream();
      masterPlayList?.url = masterPlayRoot['url'];
    }
  }

  void _parseTranscodeList(Map<String, dynamic> videInfoRoot) {
    if (null != videInfoRoot['transcodeList']) {
      List<dynamic> transcodeListRoot = videInfoRoot['transcodeList'];
      List<PlayInfoStream> streamList = _parseStreamList(transcodeListRoot);
      for(PlayInfoStream stream in streamList) {
        if(videoClassificationList.isNotEmpty) {
          for(VideoClassification classification in videoClassificationList) {
            List<int> definitionList = classification.definitionList;
            if(definitionList.contains(stream.definition)) {
              stream.id = classification.id;
              stream.name = classification.name;
            }
          }
        }
      }

      // 清晰度去重
      for (PlayInfoStream stream in streamList) {
        if (!_transcodePlayList.containsKey(stream.id)) {
          _transcodePlayList[stream.id] = stream;
        } else {
          PlayInfoStream copy = _transcodePlayList[stream.id] as PlayInfoStream;
          if (copy.url.endsWith("mp4")) {
            continue;
          }
          if (stream.url.endsWith("mp4")) {
            _transcodePlayList[stream.id] = stream;
          }
        }
      }
    }
  }

  List<PlayInfoStream> _parseStreamList(List<dynamic> transcodeListRoot) {
    List<PlayInfoStream> streamList = [];
    for (Map<String, dynamic> videoStreamRoot in transcodeListRoot) {
      PlayInfoStream playInfoStream = new PlayInfoStream();
      playInfoStream.url = videoStreamRoot['url'];
      playInfoStream.duration = videoStreamRoot['duration'];
      playInfoStream.width = videoStreamRoot['width'];
      playInfoStream.height = videoStreamRoot['height'];
      playInfoStream.size = videoStreamRoot['size'];
      playInfoStream.bitrate = videoStreamRoot['bitrate'];
      playInfoStream.definition = videoStreamRoot['definition'];
      streamList.add(playInfoStream);
    }
    return streamList;
  }

  void _parseSourceVideo(Map<String, dynamic> videInfoRoot) {
    Map<String, dynamic> sourceVideoRoot = videInfoRoot['sourceVideo'];
    sourceStream = PlayInfoStream();
    sourceStream?.url = sourceVideoRoot['url'];
    sourceStream?.duration = sourceVideoRoot['duration'];
    sourceStream?.width = sourceVideoRoot['width'];
    sourceStream?.height = sourceVideoRoot['height'];
    sourceStream?.size = sourceVideoRoot['size'];
    sourceStream?.bitrate = sourceVideoRoot['bitrate'];
  }


  void _parseVideoInfo() {
    // If there is main playback video information, parse the URLs that support multi-bitrate playback from it.
    if (null != masterPlayList) {
      _url = masterPlayList!.url;
      if (_transcodePlayList.isNotEmpty) {
        PlayInfoStream? stream = _transcodePlayList[defaultVideoClassification];
        videoQualityList =
            VideoQualityUtils.convertToVideoQualityList(_transcodePlayList);
        if (null != stream) {
          defaultVideoQuality = VideoQualityUtils.convertToVideoQuality(stream);
        }
      }
      return;
    }

    // If there is no main playback information, parse the bitstream information from the transcode video information.
    if (_transcodePlayList.isNotEmpty) {
      PlayInfoStream? stream = _transcodePlayList[defaultVideoClassification];
      String? tempUrl;
      if (stream != null) {
        tempUrl = stream.url;
      } else {
        for (PlayInfoStream stream1 in _transcodePlayList.values) {
          if (stream1 != null && stream1.url.isNotEmpty) {
            stream = stream1;
            tempUrl = stream1.url;
            break;
          }
        }
      }
      if (tempUrl != null) {
        videoQualityList =
            VideoQualityUtils.convertToVideoQualityList(_transcodePlayList);
        if (null != stream) {
          defaultVideoQuality = VideoQualityUtils.convertToVideoQuality(stream);
        }
        _url = tempUrl;
        return;
      }
    }
    // If there is no main playback information or transcoding information,
    // parse the playback information from the source video information
    if (sourceStream != null) {
      if (defaultVideoClassification != null) {
        defaultVideoQuality = VideoQualityUtils.convertToVideoQuality(sourceStream!);
        videoQualityList = [];
        videoQualityList.add(defaultVideoQuality!);
      }
      _url = sourceStream!.url;
    }
  }

  @override
  String? getEncryptedURL(EncryptedURLType type) {
    return null;
  }

  @override
  String getUrl() {
    return _url;
  }

}
