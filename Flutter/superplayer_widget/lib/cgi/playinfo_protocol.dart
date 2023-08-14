// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// request handler with tencent fileId
class PlayInfoProtocol {
  static const TAG = "PlayInfoProtocol";
  static const _BASE_URLS_V4 = "https://playvideo.qcloud.com/getplayinfo/v4";

  SuperPlayerModel _videoModel;
  PlayInfoParser? _playInfoParser;

  PlayInfoProtocol(this._videoModel);

  /// send fileId reqeust
  Future<void> sendRequest(Function(PlayInfoProtocol,SuperPlayerModel) onSuccess, Function(int errCode, String errorMsg) onError) async {
    if (_videoModel.videoId == null || _videoModel.videoId!.fileId.isEmpty) {
      return;
    }
    String url = _makeUrlString();
    var httpClient = new HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      onError(-1, "http request error.");
      return;
    }
    var json = await response.transform(utf8.decoder).join();
    if(json == null || json.isEmpty) {
      onError(-1, "request return error!");
      return;
    }
    Map<String, dynamic> root = jsonDecode(json);
    int code = root['code'];
    String message = root['message'];
    String warning = root['warning'];
    LogUtils.d(TAG, "_getVodListData,code=($code, ${PlayInfoProtocol.GETPLAYINFOV4_ERROR_CODE_MAP[code]}),message=$message,warning=$warning");
    if (code != 0) {
      onError(code, message);
      return;
    }
    int version = root['version'];
    if(version == 2) {
      _playInfoParser = PlayInfoParserV2(json);
    } else if(version == 4) {
      _playInfoParser = PlayInfoParserV4(json);
    }

    onSuccess(this,_videoModel);
  }

  String _makeUrlString() {
    String urlStr = "$_BASE_URLS_V4/${_videoModel.appId}/${_videoModel.videoId!.fileId}";
    String? psign = makeJWTSignature();
    String query = _videoModel.videoId != null ? makeQueryString(null, psign, null) : "";

    if (query.isNotEmpty) {
      urlStr = "$urlStr?$query";
    }
    LogUtils.d(TAG, "request url: $urlStr");
    return urlStr;
  }

  String? makeJWTSignature() {
    if (_videoModel.videoId != null && _videoModel.videoId!.psign.isNotEmpty) {
      return _videoModel.videoId!.psign;
    }
    return null;
  }

  static String makeQueryString(String? pcfg, String? psign, String? content) {
    String result = "";
    if (null != pcfg) {
      result += "pcfg=$pcfg&";
    }

    if(null != psign && psign.isNotEmpty) {
      result += "psign=$psign&";
    }

    if (null != content && content.isNotEmpty) {
      result += "context=$content&";
    }
    if (result.length > 1) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Get a 32-bit random string
  /// 获取32位随机字符串
  String genRandomHexString() {
    List<String> hexArray = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
    int keyLen = 32;
    String result = "";
    for (int i = 0; i < keyLen; i++) {
      String randomChar = hexArray[Random().nextInt(hexArray.length)];
      result += randomChar;
    }
    return result;
  }

  String? getUrl() {
    return null == _playInfoParser ? null : _playInfoParser?.getUrl();
  }

  String? getName() {
    return null == _playInfoParser ? null : _playInfoParser?.name;
  }

  PlayImageSpriteInfo? getImageSpriteInfo() {
    return null == _playInfoParser ? null : _playInfoParser?.imageSpriteInfo;
  }

  String? getToken() {
    return null == _playInfoParser ? null : _playInfoParser?.token;
  }

  String? getEncyptedUrl(EncryptedURLType type) {
    return null == _playInfoParser ? null : _playInfoParser?.getEncryptedURL(type);
  }

  List<PlayKeyFrameDescInfo>? getKeyFrameDescInfo() {
    return null == _playInfoParser ? null : _playInfoParser?.keyFrameDescInfo;
  }

  List<VideoQuality>? getVideoQualityList() {
    return null == _playInfoParser ? null : _playInfoParser?.videoQualityList;
  }

  VideoQuality? getDefaultVideoQuality() {
    return null == _playInfoParser ? null : _playInfoParser?.defaultVideoQuality;
  }

  List<ResolutionName>? getResolutionNameList() {
    return null == _playInfoParser ? null : _playInfoParser?.resolutionNameList;
  }

  String? getDRMType() {
    return null == _playInfoParser ? null : _playInfoParser?.drmType;
  }

  static String? getV4ErrorCodeDescription(int errorCode) {
    return GETPLAYINFOV4_ERROR_CODE_MAP[errorCode];
  }

  ///getplayinfo/v4 error codes
  /// HTTP status codes: 200, 403
  /// 403: Generally authentication information does not pass or request is invalid.
  /// HTTP body is only available when the status code is 200.
  /// Code error [1000-2000): Request issue.
  /// Code error [2000-3000): Server error, retry can be initiated.
  ///
  /// getplayinfo/v4错误码
  /// http状态码 200 403
  /// 403一般鉴权信息不通过或者请求不合法
  /// 状态码为200的时候才会有http body
  /// code错误码[1000-2000)请求有问题，
  /// code错误码[2000-3000)服务端错误，可发起重试
  static Map<int, String> GETPLAYINFOV4_ERROR_CODE_MAP = {
    0 : 'success',
    1001 : FSPLocal.current.txSpwErrFileNotExist,
    1002 : FSPLocal.current.txSpwErrInvalidTrialDuration,
    1003 : FSPLocal.current.txSpwErrPcfgNotUnique,
    1004 : FSPLocal.current.txSpwErrLicenseExpired,
    1005 : FSPLocal.current.txSpwErrNoAdaptiveStream,
    1006 : FSPLocal.current.txSpwErrInvalidRequestFormat,
    1007 : FSPLocal.current.txSpwErrNoUser,
    1008 : FSPLocal.current.txSpwErrNoAntiLeechInfo,
    1009 : FSPLocal.current.txSpwErrCheckSignFailed,
    1010 : FSPLocal.current.txSpwErrOther,
    2001 : FSPLocal.current.txSpwErrInternal,
  };
}
