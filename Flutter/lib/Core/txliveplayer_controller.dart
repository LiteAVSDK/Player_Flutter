// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

final TXFlutterLivePlayerApi _livePlayerApi = TXFlutterLivePlayerApi();

class TXLivePlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue?>, TXPlayerController {
  int? _playerId = -1;
  static String kTag = "TXLivePlayerController";

  final Completer<int> _initPlayer;
  final Completer<int> _createTexture;
  bool _isDisposed = false;
  bool _isNeedDisposed = false;
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

  void printVersionInfo() async {
    LogUtils.d(kTag, "dart SDK version:${Platform.version}");
    LogUtils.d(kTag, "liteAV SDK version:${await SuperPlayerPlugin.platformVersion}");
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  @deprecated
  Future<bool> play(String url, {int? playType}) async {
    return await startLivePlay(url, playType: playType);
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  /// 10.7版本开始，startPlay变更为startLivePlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  Future<bool> startLivePlay(String url, {int? playType}) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);
    printVersionInfo();
    BoolMsg boolMsg = await _livePlayerApi.startLivePlay(StringIntPlayerMsg()
      ..strValue = url
      ..intValue = playType
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  @override
  Future<void> initialize({bool? onlyAudio}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    IntMsg intMsg = await _livePlayerApi.initialize(BoolPlayerMsg()
      ..value = onlyAudio ?? false
      ..playerId = _playerId);
    _createTexture.complete(intMsg.value);
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
    await _livePlayerApi.setAutoPlay(BoolPlayerMsg()
      ..value = isAutoPlay ?? false
      ..playerId = _playerId);
  }

  /// 停止播放
  /// return 是否停止成功
  @override
  Future<bool> stop({bool isNeedClear = false}) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    BoolMsg boolMsg = await _livePlayerApi.stop(BoolPlayerMsg()
      ..value = isNeedClear
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// 视频是否处于正在播放中
  @override
  Future<bool> isPlaying() async {
    await _initPlayer.future;
    BoolMsg boolMsg = await _livePlayerApi.isPlaying(PlayerMsg()..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// 视频暂停，必须在播放器开始播放的时候调用
  @override
  Future<void> pause() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.pause(PlayerMsg()..playerId = _playerId);
    if (_state != TXPlayerState.paused) _changeState(TXPlayerState.paused);
  }

  /// 继续播放，在暂停的时候调用
  @override
  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.resume(PlayerMsg()..playerId = _playerId);
    if (_state != TXPlayerState.playing) _changeState(TXPlayerState.playing);
  }

  /// 设置直播模式，see TXPlayerLiveMode
  Future<void> setLiveMode(TXPlayerLiveMode mode) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setLiveMode(IntPlayerMsg()
      ..value = mode.index
      ..playerId = _playerId);
  }

  /// 设置视频声音 0~100
  Future<void> setVolume(int volume) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setVolume(IntPlayerMsg()
      ..value = volume
      ..playerId = _playerId);
  }

  /// 设置是否静音
  @override
  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setMute(BoolPlayerMsg()
      ..value = mute
      ..playerId = _playerId);
  }

  /// 切换播放流
  Future<int> switchStream(String url) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    IntMsg intMsg = await _livePlayerApi.switchStream(StringPlayerMsg()
      ..value = url
      ..playerId = _playerId);
    return intMsg.value ?? -1;
  }

  /// 将视频播放进度定位到指定的进度进行播放
  /// progress 要定位的视频时间，单位 秒
  @override
  Future<void> seek(double progress) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.seek(DoublePlayerMsg()
      ..value = progress
      ..playerId = _playerId);
  }

  /// 设置appId
  Future<void> setAppID(int appId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setAppID(StringPlayerMsg()
      ..value = appId.toString()
      ..playerId = _playerId);
  }

  /// 时移 暂不支持
  @deprecated
  Future<void> prepareLiveSeek(String domain, int bizId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.prepareLiveSeek(StringIntPlayerMsg()
      ..strValue = domain
      ..intValue = bizId
      ..playerId = _playerId);
  }

  /// 停止时移播放，返回直播
  Future<int> resumeLive() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    IntMsg intMsg = await _livePlayerApi.resumeLive(PlayerMsg()..playerId = _playerId);
    return intMsg.value ?? 0;
  }

  /// 设置播放速率,暂不支持
  @deprecated
  @override
  Future<void> setRate(double rate) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setRate(DoublePlayerMsg()
      ..value = rate
      ..playerId = _playerId);
  }

  /// 设置播放器配置
  /// config @see [FTXLivePlayConfig]
  Future<void> setConfig(FTXLivePlayConfig config) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setConfig(config.toMsg()..playerId = _playerId);
  }

  /// 开启/关闭硬件编码
  @override
  Future<bool> enableHardwareDecode(bool enable) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    BoolMsg boolMsg = await _livePlayerApi.enableHardwareDecode(BoolPlayerMsg()
      ..value = enable
      ..playerId = _playerId);
    return boolMsg.value ?? false;
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
    /// live not support
    // IntMsg intMsg = await _livePlayerApi.enterPictureInPictureMode(PipParamsPlayerMsg()
    //   ..backIconForAndroid = backIconForAndroid
    //   ..playIconForAndroid = playIconForAndroid
    //   ..pauseIconForAndroid = pauseIconForAndroid
    //   ..forwardIconForAndroid = forwardIconForAndroid
    //   ..playerId = _playerId);
    // return intMsg.value ?? -1;
    return -1;
  }

  /// 退出画中画，如果该播放器处于画中画模式
  @override
  Future<void> exitPictureInPictureMode() async {
    /// live not support
    // await _livePlayerApi.exitPictureInPictureMode(PlayerMsg()..playerId = _playerId);
  }

  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
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

  @override
  TXPlayerValue? playerValue() {
    return _value;
  }
}
