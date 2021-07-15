part of SuperPlayer;

class TXPlayerValue{
  final TXPlayerState state;
  TXPlayerValue.uninitialized():this(state:TXPlayerState.stopped);

  TXPlayerValue({@required this.state});

  TXPlayerValue copyWith({TXPlayerState state}){
    return TXPlayerValue(
        state:state ?? this.state
    );
  }
}

///
/// 直播类型
///
abstract class TXPlayType{

  ///
  /// see: https://cloud.tencent.com/document/product/454/7886
  ///
  static const LIVE_RTMP = 0;
  static const LIVE_FLV = 1;
  static const LIVE_RTMP_ACC = 5;
  static const VOD_HLS = 3;
}

enum TXPlayerLiveMode{
  Automatic, // 自动模式
  Speed,     // 极速模式
  Smooth     // 流畅模式
}

enum TXPlayerState{
  paused,    // 暂停播放
  failed,    // 播放失败
  buffering, // 缓冲中
  playing,   // 播放中
  stopped,   // 停止播放
  disposed  // 控件释放了
}

enum TXPlayerEvent{
  reconnect, // 网络中断，自动重连中
  disconnect, // 网络中断，重连失败
  dnsFail, // RTMP-DNS 解析失败
  severConnFail, // RTMP 服务器连接失败
  shakeFail, // RTMP 服务器握手失败
  progress  // 进度
}

abstract class SuperPlayerViewEvent{
  static const onStartFullScreenPlay = "onStartFullScreenPlay";
  static const onStopFullScreenPlay = "onStopFullScreenPlay";
}

class SuperPlayerUrl {
  String title = "";
  String url = "";
}

class SuperPlayerVideoId {
  String fileId = "";
  String psign = "";
}

class TXPlayerAuthParams{
  int appId = 0;
  String fileId = "";
  String timeout = "";
  int exper = 0;
  String us = "";
  String sign = "";
  bool https = false;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["appId"] = appId;
    json["fileId"] = fileId;
    json["timeout"] = timeout;
    json["exper"] = exper;
    json["us"] = us;
    json["sign"] = sign;
    json["https"] = https;

    return json;
  }
}