// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXVodPlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue?>, TXPlayerController {
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

  /// 播放状态监听，@see TXPlayerState
  Stream<TXPlayerState?> get onPlayerState => _stateStreamController.stream;

  /// 播放事件监听，see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;

  /// 点播播放器网络状态回调，see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _netStatusStreamController.stream;

  TXVodPlayerController()
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = TXPlayerValue.uninitialized();
    _state = _value!.state;
    _create();
  }

  Future<void> _create() async {
    _playerId = await SuperPlayerPlugin.createVodPlayer();
    _channel = MethodChannel("cloud.tencent.com/txvodplayer/$_playerId");
    _eventSubscription = EventChannel("cloud.tencent.com/txvodplayer/event/$_playerId")
        .receiveBroadcastStream("event")
        .listen(_eventHandler, onError: _errorHandler);
    _netSubscription = EventChannel("cloud.tencent.com/txvodplayer/net/$_playerId")
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
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS: //播放进度
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
      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED: //点播加载完成
        break;
      case TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END: //loading 结束
        break;
      case TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT:
        _changeState(TXPlayerState.failed);
        break;
      case TXVodPlayEvent.PLAY_ERR_FILE_NOT_FOUND:
        _changeState(TXPlayerState.failed);
        break;
      case TXVodPlayEvent.PLAY_ERR_HLS_KEY:
        _changeState(TXPlayerState.failed);
        break;
      case TXVodPlayEvent.PLAY_WARNING_RECONNECT:
        break;
      case TXVodPlayEvent.PLAY_WARNING_DNS_FAIL:
        break;
      case TXVodPlayEvent.PLAY_WARNING_SEVER_CONN_FAIL:
        break;
      case TXVodPlayEvent.PLAY_WARNING_SHAKE_FAIL:
        break;

      default:
        break;
    }

    _eventStreamController.add(map);
  }

  _netHandler(event) {
    if (event == null) return;
    final Map<dynamic, dynamic> map = event;
    _netStatusStreamController.add(map);
  }

  _errorHandler(error) {}

  _changeState(TXPlayerState playerState) {
    value = _value!.copyWith(state: playerState);
    _state = value!.state;
    _stateStreamController.add(_state);
  }

  /// 通过url开始播放视频
  /// @param url : 视频播放地址
  /// return 是否播放成功
  @override
  Future<bool> startPlay(String url) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    final result = await _channel.invokeMethod("play", {"url": url});
    return result == 0;
  }

  /// 通过fileld播放视频
  /// @params : 见[TXPlayInfoParams]
  /// return 是否播放成功
  Future<void> startPlayWithParams(TXPlayInfoParams params) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    await _channel.invokeMethod("startPlayWithParams", params.toJson());
  }

  /// 共享纹理id，原生层的纹理准备好之后，会将纹理id传递回来。
  /// 可通过监听该值，来将共享纹理设置在需要的地方
  Future<int> get textureId async {
    return _createTexture.future;
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
    _changeState(TXPlayerState.paused);
  }

  /// 设置是否自动播放
  @override
  Future<void> setAutoPlay({bool? isAutoPlay}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setAutoPlay", {"isAutoPlay": isAutoPlay ?? false});
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
    _changeState(TXPlayerState.paused);
  }

  /// 继续播放，在暂停的时候调用
  @override
  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("resume");
  }

  /// 设置是否静音
  @override
  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMute", {"mute": mute});
  }

  /// 设置是否循环播放
  Future<void> setLoop(bool loop) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLoop", {"loop": loop});
  }

  /// 将视频播放进度定位到指定的进度进行播放
  /// progress 要定位的视频时间，单位 秒
  @override
  Future<void> seek(double progress) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"progress": progress});
  }

  /// 设置播放速率，默认速率 1
  @override
  Future<void> setRate(double rate) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setRate", {"rate": rate});
  }

  /// 获得播放视频解析出来的码率信息
  /// return List<Map>
  /// Bitrate键值：index 码率序号，width 码率对应视频宽度，
  ///             height 码率对应视频高度, bitrate 码率值
  Future<List?> getSupportedBitrates() async {
    if (_isNeedDisposed) return [];
    await _initPlayer.future;
    return _channel.invokeMethod("getSupportedBitrates");
  }

  /// 获得当前设置的码率序号
  Future<int> getBitrateIndex() async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    return await _channel.invokeMethod("getBitrateIndex");
  }

  /// 设置码率序号
  Future<void> setBitrateIndex(int index) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setBitrateIndex", {"index": index});
  }

  /// 设置视频播放开始时间，单位 秒
  Future<void> setStartTime(double startTime) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setStartTime", {"startTime": startTime});
  }

  /// 设置视频声音 0~100
  Future<void> setAudioPlayoutVolume(int volume) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setAudioPlayoutVolume", {"volume": volume});
  }

  /// 请求获得音频焦点
  Future<bool> setRequestAudioFocus(bool focus) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    return await _channel.invokeMethod("setRequestAudioFocus", {"focus": focus});
  }

  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  /// 设置播放器配置
  /// config @see [FTXVodPlayConfig]
  Future<void> setConfig(FTXVodPlayConfig config) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setConfig", {"config": config.toJson()});
  }

  /// 获得当前已经播放的时间，单位 秒
  Future<double> getCurrentPlaybackTime() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getCurrentPlaybackTime");
  }

  /// 获得当前视频已缓存的时间
  Future<double> getBufferDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getBufferDuration");
  }

  /// 获得当前视频的可播放时间
  Future<double> getPlayableDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getPlayableDuration");
  }

  /// 获得当前播放视频的宽度
  Future<int> getWidth() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getWidth");
  }

  /// 获得当前播放视频的高度
  Future<int> getHeight() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getHeight");
  }

  /// 设置播放视频的token
  Future<void> setToken(String? token) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setToken", {"token": token ?? ""});
  }

  /// 当前播放的视频是否循环播放
  Future<bool> isLoop() async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    return await _channel.invokeMethod("isLoop");
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
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，如果赋值的话，将会使用传递的图标，否则
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
      return await _channel.invokeMethod("enterPictureInPictureMode");
    } else {
      return -1;
    }
  }

  /// 获取总时长
  Future<double> getDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    return await _channel.invokeMethod("getDuration");
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
      _netStatusStreamController.close();
    }

    super.dispose();
  }

  @override
  get value => _value;

  set value(TXPlayerValue? val) {
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  double? resizeVideoWidth = 0;
  double? resizeVideoHeight = 0;
  double? videoLeft = 0;
  double? videoTop = 0;
  double? videoRight = 0;
  double? videoBottom = 0;
}
