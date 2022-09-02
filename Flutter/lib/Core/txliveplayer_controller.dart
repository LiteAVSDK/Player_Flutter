// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXLivePlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue?>, TXPlayerController {
  int? _playerId = -1;

  final Completer<int> _initPlayer;
  final Completer<int> _createTexture;
  bool _isDisposed = false;
  bool _isNeedDisposed = false;
  late MethodChannel _channel;
  TXPlayerValue? _value;
  TXPlayerState? _state;

  TXPlayerState? get playState => _state;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _netSubscription;

  final StreamController<TXPlayerState?> _stateStreamController = StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic>> _eventStreamController = StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic>> _netStatusStreamController = StreamController.broadcast();

  Stream<TXPlayerState?> get onPlayerState => _stateStreamController.stream;

  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;

  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _netStatusStreamController.stream;

  TXLivePlayerController()
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = TXPlayerValue.uninitialized();
    _state = _value!.state;
    _create();
  }

  Future<void> _create() async {
    _playerId = await SuperPlayerPlugin.createLivePlayer();
    _channel = MethodChannel("cloud.tencent.com/txliveplayer/$_playerId");
    _eventSubscription = EventChannel("cloud.tencent.com/txliveplayer/event/$_playerId")
        .receiveBroadcastStream("event")
        .listen(_eventHandler, onError: _errorHandler);
    _netSubscription = EventChannel("cloud.tencent.com/txliveplayer/net/$_playerId")
        .receiveBroadcastStream("net")
        .listen(_netHandler, onError: _errorHandler);
    _initPlayer.complete(_playerId);
  }

  ///
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  _eventHandler(event) {
    if (event == null) return;
    final Map<dynamic, dynamic> map = event;
    //debugPrint("= event = ${map.toString()}");
    switch (map["event"]) {
      case TXVodPlayEvent.PLAY_EVT_RTMP_STREAM_BEGIN:
        break;
      case TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME:
        if (_isNeedDisposed) return;
        if (_state == TXPlayerState.buffering) _changeState(TXPlayerState.playing);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
        if (_isNeedDisposed) return;
        if (_state == TXPlayerState.buffering) _changeState(TXPlayerState.playing);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS: //EVT_PLAY_PROGRESS
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
        _changeState(TXPlayerState.stopped);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
        _changeState(TXPlayerState.buffering);
        break;
      case TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION: //下行视频分辨率改变
        if (defaultTargetPlatform == TargetPlatform.android) {
          double? videoWidth = (event["videoWidth"]);
          double? videoHeight = (event["videoHeight"]);
          if ((videoWidth != null && videoWidth > 0) && (videoHeight != null && videoHeight > 0)) {
            resizeVideoWidth = videoWidth;
            resizeVideoHeight = videoHeight;
            videoLeft = event["videoLeft"];
            videoTop = event["videoTop"];
            videoRight = event["videoRight"];
            videoBottom = event["videoBottom"];
          }
        }
        break;
      case TXVodPlayEvent.PLAY_EVT_STREAM_SWITCH_SUCC: //直播，切流成功（切流可以播放不同画面大小的视频）
        break;
      case TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT: //disconnect
        _changeState(TXPlayerState.failed);
        break;
      case TXVodPlayEvent.PLAY_WARNING_RECONNECT: //reconnect
        break;
      case TXVodPlayEvent.PLAY_WARNING_DNS_FAIL: //dnsFail
        break;
      case TXVodPlayEvent.PLAY_WARNING_SEVER_CONN_FAIL: //severConnFail
        break;
      case TXVodPlayEvent.PLAY_WARNING_SHAKE_FAIL: //shakeFail
        break;
      case TXVodPlayEvent.PLAY_ERR_STREAM_SWITCH_FAIL: //failed
        _changeState(TXPlayerState.failed);
        break;
      default:
        break;
    }
    _eventStreamController.add(map);
  }

  _errorHandler(error) {
    //debugPrint("= error = ${error.toString()}");
  }

  _netHandler(event) {
    if (event == null) return;
    final Map<dynamic, dynamic> map = event;
    _netStatusStreamController.add(map);
  }

  _changeState(TXPlayerState playerState) {
    value = _value!.copyWith(state: playerState);
    _state = value!.state;
    _stateStreamController.add(_state);
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  @deprecated
  Future<bool> play(String url, {int? playType}) async {
    return await startPlay(url, playType: playType);
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  @override
  Future<bool> startPlay(String url, {int? playType}) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    final result = await _channel.invokeMethod("play", {"url": url, "playType": playType});
    return result == 0;
  }

  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  @override
  Future<void> initialize({bool? onlyAudio}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    final textureId = await _channel.invokeMethod("init", {
      "onlyAudio": onlyAudio ?? false,
    });
    _createTexture.complete(textureId);
    _state = TXPlayerState.paused;
  }

  /// 设置是否自动播放
  @deprecated
  Future<void> setIsAutoPlay({bool? isAutoPlay}) async {
    await setAutoPlay(isAutoPlay: isAutoPlay);
  }

  /// 设置是否自动播放
  @override
  Future<void> setAutoPlay({bool? isAutoPlay}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setIsAutoPlay", {"isAutoPlay": isAutoPlay ?? false});
  }

  /// 停止播放
  /// return 是否停止成功
  @override
  Future<bool> stop({bool isNeedClear = false}) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    final result = await _channel.invokeMethod("stop", {"isNeedClear": isNeedClear});
    _changeState(TXPlayerState.stopped);
    return result == 0;
  }

  /// 视频是否处于正在播放中
  @override
  Future<bool> isPlaying() async {
    await _initPlayer.future;
    return await _channel.invokeMethod("isPlaying");
  }

  /// 视频暂停，必须在播放器开始播放的时候调用
  @override
  Future<void> pause() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("pause");
    if (_state != TXPlayerState.paused) _changeState(TXPlayerState.paused);
  }

  /// 继续播放，在暂停的时候调用
  @override
  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("resume");
    if (_state != TXPlayerState.playing) _changeState(TXPlayerState.playing);
  }

  /// 设置直播模式，see TXPlayerLiveMode
  Future<void> setLiveMode(TXPlayerLiveMode mode) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLiveMode", {"type": mode.index});
  }

  /// 设置视频声音 0~100
  Future<void> setVolume(int volume) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setVolume", {"volume": volume});
  }

  /// 设置是否静音
  @override
  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMute", {"mute": mute});
  }

  /// 切换播放流
  Future<int> switchStream(String url) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    return await _channel.invokeMethod("switchStream", {"url": url});
  }

  /// 将视频播放进度定位到指定的进度进行播放
  /// progress 要定位的视频时间，单位 秒
  @override
  Future<void> seek(double progress) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"progress": progress});
  }

  /// 设置appId
  Future<void> setAppID(int appId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"appId": appId});
  }

  /// 时移 暂不支持
  @deprecated
  Future<void> prepareLiveSeek(String domain, int bizId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("prepareLiveSeek", {"domain": domain, "bizId": bizId});
  }

  /// 停止时移播放，返回直播
  Future<int> resumeLive() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("resumeLive");
  }

  /// 设置播放速率,暂不支持
  @deprecated
  @override
  Future<void> setRate(double rate) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setRate", {"rate": rate});
  }

  /// 设置播放器配置
  /// config @see [FTXLivePlayConfig]
  Future<void> setConfig(FTXLivePlayConfig config) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setConfig", {"config": config.toJson()});
  }

  /// 开启/关闭硬件编码
  @override
  Future<bool> enableHardwareDecode(bool enable) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    return await _channel.invokeMethod("enableHardwareDecode", {"enable": enable});
  }

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，仅适用于android，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  @override
  Future<int> enterPictureInPictureMode(
      {String? backIconForAndroid,
      String? playIconForAndroid,
      String? pauseIconForAndroid,
      String? forwardIconForAndroid}) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("enterPictureInPictureMode", {
        "backIcon": backIconForAndroid,
        "playIcon": playIconForAndroid,
        "pauseIcon": pauseIconForAndroid,
        "forwardIcon": forwardIconForAndroid
      });
    } else if (Platform.isIOS) {
      return -1;
    } else {
      return -1;
    }
  }

  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
    // await _channel.invokeMethod("destory");
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  /// 释放controller
  @override
  void dispose() async {
    _isNeedDisposed = true;
    if (!_isDisposed) {
      await _eventSubscription!.cancel();
      _eventSubscription = null;
      await _netSubscription!.cancel();
      _netSubscription = null;

      await _release();
      _changeState(TXPlayerState.disposed);
      _isDisposed = true;
      _stateStreamController.close();
      _eventStreamController.close();
    }

    super.dispose();
  }

  @override
  // TODO: implement value

  get value => _value;

  set value(TXPlayerValue? val) {
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  @override
  // TODO: implement textureId
  Future<int> get textureId async {
    return _createTexture.future;
  }

  double? resizeVideoWidth = 0;
  double? resizeVideoHeight = 0;
  double? videoLeft = 0;
  double? videoTop = 0;
  double? videoRight = 0;
  double? videoBottom = 0;
}
