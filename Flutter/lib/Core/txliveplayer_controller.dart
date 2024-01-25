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

  /// event type
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
          int? videoWidth = event[TXVodPlayEvent.EVT_VIDEO_WIDTH];
          int? videoHeight = event[TXVodPlayEvent.EVT_VIDEO_HEIGHT];
          videoWidth ??= event[TXVodPlayEvent.EVT_PARAM1];
          videoHeight ??= event[TXVodPlayEvent.EVT_PARAM2];
          if ((videoWidth != null && videoWidth > 0) && (videoHeight != null && videoHeight > 0)) {
            resizeVideoWidth = videoWidth.toDouble();
            resizeVideoHeight = videoHeight.toDouble();
            videoLeft = event["videoLeft"] ?? 0;
            videoTop = event["videoTop"] ?? 0;
            videoRight = event["videoRight"] ?? 0;
            videoBottom = event["videoBottom"] ?? 0;
          }
        }
        break;
      // Live broadcast, stream switching succeeded (stream switching can play videos of different sizes):
      case TXVodPlayEvent.PLAY_EVT_STREAM_SWITCH_SUCC:
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

  /// When setting a [LivePlayer] type player, the parameter [playType] is required.
  /// Reference: [PlayType.LIVE_RTMP] ...
  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  @deprecated
  Future<bool> play(String url, {int? playType}) async {
    return await startLivePlay(url, playType: playType);
  }

  /// When setting a [LivePlayer] type player, the parameter [playType] is required.
  /// Reference: [PlayType.LIVE_RTMP] ...
  /// Starting from version 10.7, the method `startPlay` has been changed to `startLivePlay` for playing videos via a URL.
  /// To play videos successfully, it is necessary to set the license by using the method `SuperPlayerPlugin#setGlobalLicense`.
  /// Failure to set the license will result in video playback failure (a black screen).
  /// Live streaming, short video, and video playback licenses can all be used. If you do not have any of the above licenses,
  /// you can apply for a free trial license to play videos normally[Quickly apply for a free trial version Licence]
  /// (https://cloud.tencent.com/act/event/License).Official licenses can be purchased
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).
  /// @param url : 视频播放地址 video playback address
  /// return 是否播放成功 if play successfully
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

  /// Player initialization, creating shared textures and initializing the player.
  /// @param onlyAudio Whether it is pure audio mode.
  ///
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

  /// Stop playing.
  /// return Whether to stop successfully.
  ///
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

  /// Whether the video is currently playing.
  ///
  /// 视频是否处于正在播放中
  @override
  Future<bool> isPlaying() async {
    await _initPlayer.future;
    BoolMsg boolMsg = await _livePlayerApi.isPlaying(PlayerMsg()..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// The video is paused and must be called when the player starts playing.
  ///
  /// 视频暂停，必须在播放器开始播放的时候调用
  @override
  Future<void> pause() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.pause(PlayerMsg()..playerId = _playerId);
    if (_state != TXPlayerState.paused) _changeState(TXPlayerState.paused);
  }

  /// Resume playback, called when paused.
  ///
  /// 继续播放，在暂停的时候调用
  @override
  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.resume(PlayerMsg()..playerId = _playerId);
    if (_state != TXPlayerState.playing) _changeState(TXPlayerState.playing);
  }

  /// Set live mode, see `TXPlayerLiveMode`.
  ///
  /// 设置直播模式，see TXPlayerLiveMode
  Future<void> setLiveMode(TXPlayerLiveMode mode) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setLiveMode(IntPlayerMsg()
      ..value = mode.index
      ..playerId = _playerId);
  }

  /// Set video volume 0~100.
  ///
  /// 设置视频声音 0~100
  Future<void> setVolume(int volume) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setVolume(IntPlayerMsg()
      ..value = volume
      ..playerId = _playerId);
  }

  /// Set whether to mute.
  ///
  /// 设置是否静音
  @override
  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setMute(BoolPlayerMsg()
      ..value = mute
      ..playerId = _playerId);
  }

  /// Switch playback stream.
  ///
  /// 切换播放流
  Future<int> switchStream(String url) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    IntMsg intMsg = await _livePlayerApi.switchStream(StringPlayerMsg()
      ..value = url
      ..playerId = _playerId);
    return intMsg.value ?? -1;
  }

  /// Set appId
  /// 设置appId
  Future<void> setAppID(int appId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setAppID(StringPlayerMsg()
      ..value = appId.toString()
      ..playerId = _playerId);
  }

  /// Set player configuration.
  ///
  /// 设置播放器配置
  /// config @see [FTXLivePlayConfig]
  Future<void> setConfig(FTXLivePlayConfig config) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setConfig(config.toMsg()..playerId = _playerId);
  }

  /// Enable/disable hardware encoding.
  ///
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

  /// Enter picture-in-picture mode. To enter picture-in-picture mode, you need to adapt the interface for picture-in-picture mode.
  /// Android only supports models above 7.0.
  /// <h1>
  /// Due to Android system restrictions, the size of the passed icon cannot exceed 1M, otherwise it will not be displayed.
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon are icons for playback rewind, playback, pause, and fast-forward,
  /// only applicable to Android. If assigned, the passed icons will be used; otherwise,the system default icons will be used.
  /// Only supports Flutter local resource images. When passing, use the same image resource as Flutter,
  /// for example: images/back_icon.png.
  ///
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
    return -1;
  }

  /// Exit picture-in-picture mode if the player is in picture-in-picture mode.
  ///
  /// 退出画中画，如果该播放器处于画中画模式
  @override
  Future<void> exitPictureInPictureMode() async {
    /// live not support
    // await _livePlayerApi.exitPictureInPictureMode(PlayerMsg()..playerId = _playerId);
  }

  /// Release player resource occupation.
  ///
  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  /// Release `controller`.
  ///
  /// 释放controller
  @override
  Future<void> dispose() async {
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
  get value => _value;

  set value(TXPlayerValue? val) {
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  @override
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
