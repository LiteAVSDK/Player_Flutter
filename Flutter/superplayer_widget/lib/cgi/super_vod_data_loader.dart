// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// request data handler
class SuperVodDataLoader {
  static const TAG = "SuperVodDataLoader";
  static const M3U8_SUFFIX = ".m3u8";
  static const _BASE_URL = "https://playvideo.qcloud.com/getplayinfo/v4";

  /// request data by fileId.this method will callback model that with http result
  Future<void> getVideoData(SuperPlayerModel model,
      Function(SuperPlayerModel resultModel) callback) async {
    int appId = model.appId;
    String field = model.videoId != null
        ? (model.videoId as SuperPlayerVideoId).fileId
        : "";
    String psign = model.videoId != null
        ? (model.videoId as SuperPlayerVideoId).psign
        : "";
    var url = _BASE_URL + "/$appId/$field";
    var query = PlayInfoProtocol.makeQueryString(null, psign, null);
    if (query.isNotEmpty) {
      url = url + "?" + query;
    }
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      callback(model);
      return;
    }
    var json = await response.transform(utf8.decoder).join();
    Map<String, dynamic> root = jsonDecode(json);
    int code = root['code'];
    String message = root['message'];
    String warning = root['warning'];
    LogUtils.d(TAG, "_getVodListData,code=($code, ${PlayInfoProtocol.getV4ErrorCodeDescription(code)}),message=$message,warning=$warning");
    if (code != 0) {
      callback(model);
      return;
    }
    int version = root['version'];
    if (version == 2) {
      PlayInfoParserV2 parserV2 = PlayInfoParserV2(json);
      model.coverUrl = parserV2.coverUrl;
      model.duration = parserV2.duration;

      _updateTitle(model, parserV2.name);
      String url = parserV2.getUrl();
      if(null != url && (url.contains(M3U8_SUFFIX) || parserV2.videoQualityList.isEmpty)) {
        model.videoURL = url;
        if(model.multiVideoURLs.isNotEmpty) {
          model.multiVideoURLs.clear();
        }
      } else {
        model.multiVideoURLs.clear();
        List<VideoQuality> tempList = parserV2.videoQualityList;
        tempList.sort((a,b) => b.bitrate.compareTo(a.bitrate)); // Sort the bitrates from high to low.
        for(VideoQuality videoQuality in tempList) {
          SuperPlayerUrl superPlayerUrl = SuperPlayerUrl();
          superPlayerUrl.qualityName = videoQuality.title;
          superPlayerUrl.url = videoQuality.url;
          model.multiVideoURLs.add(superPlayerUrl);
        }
      }
    } else if (version == 4) {
      PlayInfoParserV4 parserV4 = PlayInfoParserV4(json);

      String title = parserV4.description;
      if(title == null || title.length == 0) {
        title = parserV4.name;
      }
      _updateTitle(model, title);
      model.coverUrl = parserV4.coverUrl;
      model.duration = parserV4.duration;
      if(null == parserV4.drmType || parserV4.drmType.isEmpty) {
        model.videoURL = parserV4.getUrl();
      }
    }
    callback(model);
  }

  /// remain user custom's title
  void _updateTitle(SuperPlayerModel model, String newTitle) {
    if(model.title == null || model.title.isEmpty) {
      model.title = newTitle;
    }
  }
}
