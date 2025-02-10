// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXLivePlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue?>,
    TXPlayerController, TXLivePlayerFlutterAPI {
  int? _playerId = -1;
  static String kTag = "TXLivePlayerController";

  late TXFlutterLivePlayerApi _livePlayerApi;
  final Completer<int> _initPlayer;
  bool _isDisposed = false;
  bool _isNeedDisposed = false;
  TXPlayerValue? _value;
  TXPlayerState? _state;

  TXPlayerState? get playState => _state;

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

  final StreamController<TXPlayerState?> _stateStreamController = StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic>> _eventStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _netStatusStreamController = StreamController.broadcast();

  Stream<TXPlayerState?> get onPlayerState => _stateStreamController.stream;
  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;

  @Deprecated("playerNetEvent will no longer return any events.")
  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _netStatusStreamController.stream;

  TXLivePlayerController({bool? onlyAudio})
      : _initPlayer = Completer() {
    _value = TXPlayerValue.uninitialized();
    _state = _value!.state;
    _create(onlyAudio: onlyAudio);
  }

  Future<void> _create({bool? onlyAudio}) async {
    _playerId = await SuperPlayerPlugin.createLivePlayer(onlyAudio: onlyAudio);
    _livePlayerApi = TXFlutterLivePlayerApi(messageChannelSuffix: _playerId.toString());
    TXLivePlayerFlutterAPI.setUp(this, messageChannelSuffix: _playerId.toString());
    _initPlayer.complete(_playerId);
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
    if (_isNeedDisposed) return false;
    return await startLivePlay(url, playType: playType);
  }

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
  /// <h1>
  ///   @deprecated: playType is invalid now, it will removed in future version
  /// </h1>
  ///
  /// 10.7版本开始，startPlay变更为startLivePlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  ///
  ///
  Future<bool> startLivePlay(String url, {@deprecated int? playType}) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    _changeState(TXPlayerState.buffering);
    printVersionInfo();
    BoolMsg boolMsg = await _livePlayerApi.startLivePlay(StringPlayerMsg()
      ..value = url
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// Player initialization, creating shared textures and initializing the player.
  /// @param onlyAudio Whether it is pure audio mode.
  ///
  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  @override
  @Deprecated("this method call will no longer be effective")
  Future<void> initialize({bool? onlyAudio}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    // IntMsg intMsg = await _livePlayerApi.initialize(BoolPlayerMsg()
    //   ..value = onlyAudio ?? false
    //   ..playerId = _playerId);
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
    if (_isNeedDisposed) return false;
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
      {String? backIconForAndroid, String? playIconForAndroid, String? pauseIconForAndroid, String? forwardIconForAndroid}) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    IntMsg intMsg = await _livePlayerApi.enterPictureInPictureMode(PipParamsPlayerMsg()
      ..backIconForAndroid = backIconForAndroid
      ..playIconForAndroid = playIconForAndroid
      ..pauseIconForAndroid = pauseIconForAndroid
      ..forwardIconForAndroid = forwardIconForAndroid
      ..playerId = _playerId);
    return intMsg.value ?? -1;
  }

  /// Exit picture-in-picture mode if the player is in picture-in-picture mode.
  ///
  /// 退出画中画，如果该播放器处于画中画模式
  @override
  Future<void> exitPictureInPictureMode() async {
    if (_isNeedDisposed) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _livePlayerApi.exitPictureInPictureMode(PlayerMsg()
        ..playerId = _playerId);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _livePlayerApi.enablePictureInPicture(BoolPlayerMsg()
        ..value = false
        ..playerId = _playerId);
    }
  }

  ///
  /// Enable reception of SEI messages
  ///
  /// 开启接收 SEI 消息
  ///
  /// @param enable      YES: Enable reception of SEI messages; NO: Disable reception of SEI messages. [Default]: NO.
  ///                     YES: 开启接收 SEI 消息; NO: 关闭接收 SEI 消息。【默认值】: NO。
  /// @param payloadType Specify the payloadType for receiving SEI messages, supporting 5, 242, 243.
  ///                   Please keep it consistent with the sender's payloadType.
  ///                   指定接收 SEI 消息的 payloadType，支持 5、242、243，请与发送端的 payloadType 保持一致。
  ///
  Future<int> enableReceiveSeiMessage(bool isEnabled, int payloadType) async {
    if (_isNeedDisposed) return -1;
    return await _livePlayerApi.enableReceiveSeiMessage(PlayerMsg(playerId: _playerId),
        isEnabled, payloadType);
  }

  ///
  /// Whether to display the debugging overlay of player status information
  ///
  /// 是否显示播放器状态信息的调试浮层
  ///
  /// @param isShow 是否显示。default：NO。
  ///
  Future<void> showDebugView(bool isShow) async {
    if (_isNeedDisposed) return;
    await _livePlayerApi.showDebugView(PlayerMsg(playerId: _playerId), isShow);
  }

  ///
  /// Call the advanced API interface of V2TXLivePlayer
  ///
  /// @note This interface is used to call some advanced features.
  /// @param key The corresponding key for the advanced API, please refer to the definition of {@link V2TXLiveProperty} for details.
  /// @param value The parameters required when calling the advanced API corresponding to the key.
  /// @return The return value {@link V2TXLiveCode}.
  ///         - 0: Success.
  ///         - -2: Operation failed, key is not allowed to be nil.
  ///
  /// 调用 V2TXLivePlayer 的高级 API 接口
  ///
  /// @note  该接口用于调用一些高级功能。
  /// @param key   高级 API 对应的 key, 详情请参考 {@link V2TXLiveProperty} 定义。
  /// @param value 调用 key 所对应的高级 API 时，需要的参数。
  /// @return 返回值 {@link V2TXLiveCode}。
  ///         - 0: 成功。
  ///         - -2: 操作失败，key 不允许为 nil。
  ///
  Future<int> setProperty(String key, Object value) async {
    if (_isNeedDisposed) return -1;
    return await _livePlayerApi.setProperty(PlayerMsg(playerId: _playerId), key, value);
  }

  ///
  /// get live steam info
  ///
  /// 获取码流信息
  ///
  Future<List<FSteamInfo>> getSupportedBitrate() async {
    if (_isNeedDisposed) return [];
    ListMsg listMsg = await _livePlayerApi.getSupportedBitrate(PlayerMsg(playerId: _playerId));
    List<FSteamInfo> steamList = [];
    if (null != listMsg.value) {
      for (Object? obj in listMsg.value!) {
        if (null != obj) {
          steamList.add(FSteamInfo.createFromMsg(obj));
        }
      }
    }
    return steamList;
  }

  ///
  /// Set the minimum and maximum time for automatic adjustment of player cache (unit: seconds)
  ///
  /// @param minTime The minimum time for automatic cache adjustment, which must be greater than 0. [Default]: 1.
  /// @param maxTime The maximum time for automatic cache adjustment, which must be greater than 0. [Default]: 5.
  /// @return The return value {@link V2TXLiveCode}.
  ///         - 0: Success.
  ///         - -2: Operation failed, minTime and maxTime need to be greater than 0.
  ///         - -3: The player is in playback state and does not support modifying cache policy.
  ///
  /// 设置播放器缓存自动调整的最小和最大时间 ( 单位：秒 )
  ///
  /// @param minTime 缓存自动调整的最小时间，取值需要大于0。【默认值】：1。
  /// @param maxTime 缓存自动调整的最大时间，取值需要大于0。【默认值】：5。
  /// @return 返回值 {@link V2TXLiveCode}。
  ///         - 0: 成功。
  ///         - -2: 操作失败，minTime 和 maxTime 需要大于0。
  ///         - -3: 播放器处于播放状态，不支持修改缓存策略。
  ///
  Future<int> setCacheParams(double minTime, double maxTime) async {
    if (_isNeedDisposed) return -1;
    return await _livePlayerApi.setCacheParams(PlayerMsg(playerId: _playerId), minTime, maxTime);
  }

  /// Release player resource occupation.
  ///
  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  @override
  Future<void> setPlayerView(int renderViewId) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _livePlayerApi.setPlayerView(renderViewId);
  }

  /// Release `controller`.
  ///
  /// 释放controller
  @override
  Future<void> dispose() async {
    _isNeedDisposed = true;
    if (!_isDisposed) {
      await _release();
      _changeState(TXPlayerState.disposed);
      _isDisposed = true;
      _stateStreamController.close();
      _eventStreamController.close();
    }

    super.dispose();
  }

  @override
  TXPlayerValue? playerValue() {
    return _value;
  }

  @override
  void onNetEvent(Map<dynamic, dynamic> event) {
    final Map<dynamic, dynamic> map = event;
    _netStatusStreamController.add(map);
  }

  /// event type
  ///
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  @override
  void onPlayerEvent(Map<dynamic, dynamic> event) {
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

}
