// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

final TXFlutterVodPlayerApi _vodPlayerApi = TXFlutterVodPlayerApi();

class TXVodPlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue?>, TXPlayerController {
  int? _playerId = -1;
  static String kTag = "TXVodPlayerController";

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

  /// Playback State Listener
  ///
  /// 播放状态监听
  /// @see TXPlayerState
  Stream<TXPlayerState?> get onPlayerState => _stateStreamController.stream;

  /// Playback Event Listener
  ///
  /// 播放事件监听
  /// @see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;

  /// VOD player network status callback
  ///
  /// 点播播放器网络状态回调
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
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
    _eventSubscription = EventChannel("cloud.tencent.com/txvodplayer/event/$_playerId")
        .receiveBroadcastStream("event")
        .listen(_eventHandler, onError: _errorHandler);
    _netSubscription = EventChannel("cloud.tencent.com/txvodplayer/net/$_playerId")
        .receiveBroadcastStream("net")
        .listen(_netHandler, onError: _errorHandler);
    _initPlayer.complete(_playerId);
  }

  /// event type:
  ///
  /// 事件类型:
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  _eventHandler(event) {
    if (event == null) return;
    final Map<dynamic, dynamic> map = event;
    switch (map["event"]) {
      case TXVodPlayEvent.PLAY_EVT_RTMP_STREAM_BEGIN:
        break;
      case TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME:
        if (_isNeedDisposed) return;
        _changeState(TXPlayerState.playing);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
        if (_isNeedDisposed) return;
        _changeState(TXPlayerState.playing);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS: // Playback progress.
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
        _changeState(TXPlayerState.stopped);
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
        _changeState(TXPlayerState.buffering);
        break;
      case TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION: // Downstream video resolution change.
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
        int videoDegree = map['EVT_KEY_VIDEO_ROTATION'] ?? 0;
        if (Platform.isIOS && videoDegree == -1) {
          videoDegree = 0;
        }
        value = _value!.copyWith(degree: videoDegree);
        break;
      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED: // VOD loading completed.
        break;
      case TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END: // Loading ended
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

  void printVersionInfo() async {
    LogUtils.d(kTag, "dart SDK version:${Platform.version}");
    LogUtils.d(kTag, "liteAV SDK version:${await SuperPlayerPlugin.platformVersion}");
    LogUtils.d(kTag, "superPlayer SDK version:${FPlayerPckInfo.PLAYER_VERSION}");
  }

  /// Starting from version 10.7, the method `startPlay` has been changed to `startVodPlay` for playing videos via a URL.
  /// To play videos successfully, it is necessary to set the license by using the method `SuperPlayerPlugin#setGlobalLicense`.
  /// Failure to set the license will result in video playback failure (a black screen).
  /// Live streaming, short video, and video playback licenses can all be used. If you do not have any of the above licenses,
  /// you can apply for a free trial license to play videos normally[Quickly apply for a free trial version Licence]
  /// (https://cloud.tencent.com/act/event/License).Official licenses can be purchased
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).
  ///
  /// 通过url开始播放视频
  /// 10.7版本开始，startPlay变更为startVodPlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  ///
  /// @param url : 视频播放地址 video playback address
  /// return 是否播放成功 if play successfully
  Future<bool> startVodPlay(String url) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);
    printVersionInfo();
    BoolMsg boolMsg = await _vodPlayerApi.startVodPlay(StringPlayerMsg()
      ..value = url
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// Starting from version 10.7, the method "startPlayWithParams" has been changed to "startVodPlayWithParams" for playing videos using fileId.
  /// To play the video successfully, you need to set the Licence using "SuperPlayerPlugin#setGlobalLicense" method before playing the video.
  /// If you do not set the Licence, the video will not play (black screen). The Licence for live streaming,
  /// short video, and video playback can all be used. If you have not obtained the Licence, you can apply for a free trial version [here]
  /// (https://cloud.tencent.com/act/event/License) for normal playback. To use the official version, you need to [purchase]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).
  ///
  /// 通过fileId播放视频
  /// 10.7版本开始，startPlayWithParams变更为startVodPlayWithParams，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  ///
  /// @params : see[TXPlayInfoParams]
  /// return 是否播放成功  if play successful
  Future<void> startVodPlayWithParams(TXPlayInfoParams params) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);
    printVersionInfo();
    await _vodPlayerApi.startVodPlayWithParams(TXPlayInfoParamsPlayerMsg()
      ..playerId = _playerId
      ..appId = params.appId
      ..fileId = params.fileId
      ..psign = params.psign);
  }

  /// The shared texture ID is a unique integer value that is used to identify a texture,
  /// and it is passed back after the texture is prepared in the native layer.
  /// By listening to this value, the shared texture can be set where needed.
  ///
  /// 共享纹理id，原生层的纹理准备好之后，会将纹理id传递回来。
  /// 可通过监听该值，来将共享纹理设置在需要的地方
  Future<int> get textureId async {
    return _createTexture.future;
  }

  /// To initialize the player, you would need to create a shared texture and initialize the player.
  /// @param onlyAudio 是否是纯音频模式 if pure audio mode
  ///
  /// 播放器初始化，创建共享纹理、初始化播放器
  @override
  Future<void> initialize({bool? onlyAudio}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    final textureId = await _vodPlayerApi.initialize(BoolPlayerMsg()
      ..value = onlyAudio ?? false
      ..playerId = _playerId);
    _createTexture.complete(textureId.value);
    _changeState(TXPlayerState.paused);
  }

  /// set autoplay
  ///
  /// 设置是否自动播放
  Future<void> setAutoPlay({bool? isAutoPlay}) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setAutoPlay(BoolPlayerMsg()
      ..value = isAutoPlay ?? false
      ..playerId = _playerId);
  }

  /// Stop playback
  ///
  /// 停止播放
  /// return 是否停止成功 if stop successful
  @override
  Future<bool> stop({bool isNeedClear = false}) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    final result = await _vodPlayerApi.stop(BoolPlayerMsg()
      ..value = isNeedClear
      ..playerId = _playerId);
    _changeState(TXPlayerState.stopped);
    return result.value ?? false;
  }

  /// Is the video currently playing
  ///
  /// 视频是否处于正在播放中
  @override
  Future<bool> isPlaying() async {
    await _initPlayer.future;
    BoolMsg boolMsg = await _vodPlayerApi.isPlaying(PlayerMsg()..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// pause video, it must be called when the player starts playing
  ///
  /// 视频暂停，必须在播放器开始播放的时候调用
  @override
  Future<void> pause() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.pause(PlayerMsg()..playerId = _playerId);
    _changeState(TXPlayerState.paused);
  }

  /// resume playback, it should be called when the video is paused
  ///
  /// 继续播放，在暂停的时候调用
  @override
  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.resume(PlayerMsg()..playerId = _playerId);
  }

  /// Set whether to mute or not
  ///
  /// 设置是否静音
  @override
  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setMute(BoolPlayerMsg()
      ..value = mute
      ..playerId = _playerId);
  }

  /// Set whether to loop playback or not
  ///
  /// 设置是否循环播放
  Future<void> setLoop(bool loop) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setLoop(BoolPlayerMsg()
      ..value = loop
      ..playerId = _playerId);
  }

  /// Set the video playback progress to a specific time and start playing.
  ///
  /// 将视频播放进度定位到指定的进度进行播放
  /// @param progress 要定位的视频时间，单位 秒 The video playback time to be located, in seconds
  Future<void> seek(double progress) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.seek(DoublePlayerMsg()
      ..value = progress
      ..playerId = _playerId);
  }

  /// Set the playback speed, with a default speed of 1.
  ///
  /// 设置播放速率，默认速率 1
  Future<void> setRate(double rate) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setRate(DoublePlayerMsg()
      ..value = rate
      ..playerId = _playerId);
  }

  /// get the bitrate information extracted from playing a video
  /// Bitrate：index:bitrate index，
  ///         width:the video with of this bitrate，
  ///         height:the video height of this bitrate,
  ///         bitrate:bitrate value
  ///
  /// 获得播放视频解析出来的码率信息
  /// return List<Map>
  /// Bitrate：index 码率序号，
  ///         width 码率对应视频宽度，
  ///         height 码率对应视频高度,
  ///         bitrate 码率值
  Future<List?> getSupportedBitrates() async {
    if (_isNeedDisposed) return [];
    await _initPlayer.future;
    ListMsg listMsg = await _vodPlayerApi.getSupportedBitrate(PlayerMsg()..playerId = _playerId);
    return listMsg.value;
  }

  /// Get the index of the current bitrate setting
  ///
  /// 获得当前设置的码率序号
  Future<int> getBitrateIndex() async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    IntMsg intMsg = await _vodPlayerApi.getBitrateIndex(PlayerMsg()..playerId = _playerId);
    return intMsg.value ?? -1;
  }

  /// Set the index of the bitrate setting.
  ///
  /// 设置码率序号
  Future<void> setBitrateIndex(int index) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setBitrateIndex(IntPlayerMsg()
      ..value = index
      ..playerId = _playerId);
  }

  /// Set the start time of the video playback, in seconds.
  ///
  /// 设置视频播放开始时间，单位 秒
  Future<void> setStartTime(double startTime) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setStartTime(DoublePlayerMsg()
      ..value = startTime
      ..playerId = _playerId);
  }

  /// Set the volume of the video, ranging from 0 to 100.
  ///
  /// 设置视频声音 0~100
  Future<void> setAudioPlayoutVolume(int volume) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setAudioPlayOutVolume(IntPlayerMsg()
      ..value = volume
      ..playerId = _playerId);
  }

  /// Request audio focus.
  ///
  /// 请求获得音频焦点
  Future<bool> setRequestAudioFocus(bool focus) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    BoolMsg boolMsg = await _vodPlayerApi.setRequestAudioFocus(BoolPlayerMsg()
      ..value = focus
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// Release player resources.
  ///
  /// 释放播放器资源占用
  Future<void> _release() async {
    await _initPlayer.future;
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  /// Set player configuration
  ///
  /// 设置播放器配置
  /// config @see [FTXVodPlayConfig]
  Future<void> setConfig(FTXVodPlayConfig config) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setConfig(config.toMsg()..playerId = _playerId);
  }

  /// Get the current playback time, in seconds.
  ///
  /// 获得当前已经播放的时间，单位 秒
  Future<double> getCurrentPlaybackTime() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    DoubleMsg doubleMsg = await _vodPlayerApi.getCurrentPlaybackTime(PlayerMsg()..playerId = _playerId);
    return doubleMsg.value ?? 0;
  }

  /// Get the current amount of video that has been buffered.
  ///
  /// 获得当前视频已缓存的时间
  Future<double> getBufferDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    DoubleMsg doubleMsg = await _vodPlayerApi.getBufferDuration(PlayerMsg()..playerId = _playerId);
    return doubleMsg.value ?? 0;
  }

  /// Get the current playable duration of the video.
  ///
  /// 获得当前视频的可播放时间
  Future<double> getPlayableDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    DoubleMsg doubleMsg = await _vodPlayerApi.getPlayableDuration(PlayerMsg()..playerId = _playerId);
    return doubleMsg.value ?? 0;
  }

  /// Get the width of the currently playing video.
  ///
  /// 获得当前播放视频的宽度
  Future<int> getWidth() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    IntMsg intMsg = await _vodPlayerApi.getWidth(PlayerMsg()..playerId = _playerId);
    return intMsg.value ?? 0;
  }

  /// Get the height of the currently playing video.
  ///
  /// 获得当前播放视频的高度
  Future<int> getHeight() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    IntMsg intMsg = await _vodPlayerApi.getHeight(PlayerMsg()..playerId = _playerId);
    return intMsg.value ?? 0;
  }

  /// Set the token for playing the video.
  ///
  /// 设置播放视频的token
  Future<void> setToken(String? token) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.setToken(StringPlayerMsg()
      ..value = token
      ..playerId = _playerId);
  }

  /// Is the currently playing video set to loop
  ///
  /// 当前播放的视频是否循环播放
  Future<bool> isLoop() async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    BoolMsg boolMsg = await _vodPlayerApi.isLoop(PlayerMsg()..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// Enable/Disable hardware encoding.
  ///
  /// 开启/关闭硬件编码
  @override
  Future<bool> enableHardwareDecode(bool enable) async {
    if (_isNeedDisposed) return false;
    await _initPlayer.future;
    BoolMsg boolMsg = await _vodPlayerApi.enableHardwareDecode(BoolPlayerMsg()
      ..value = enable
      ..playerId = _playerId);
    return boolMsg.value ?? false;
  }

  /// To enter Picture-in-Picture mode, you need to adapt the interface for Picture-in-Picture mode.
  /// On Android, this feature is only supported on devices running Android 7.0 or higher.
  /// <h1>
  /// Due to Android system limitations, the size of the icon passed cannot exceed 1MB, otherwise it will not be displayed.
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon ：The icons for rewind, play, pause, and fast-forward can be passed as local
  ///     resource images in Flutter. If not passed, the system default icons will be used. The image path should be consistent
  ///     with how Flutter uses image resources, for example: images/back_icon.png.
  ///
  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  @override
  Future<int> enterPictureInPictureMode(
      {String? backIconForAndroid, String? playIconForAndroid, String? pauseIconForAndroid, String? forwardIconForAndroid}) async {
    if (_isNeedDisposed) return -1;
    await _initPlayer.future;
    IntMsg intMsg = await _vodPlayerApi.enterPictureInPictureMode(PipParamsPlayerMsg()
      ..backIconForAndroid = backIconForAndroid
      ..playIconForAndroid = playIconForAndroid
      ..pauseIconForAndroid = pauseIconForAndroid
      ..forwardIconForAndroid = forwardIconForAndroid
      ..playerId = _playerId);
    return intMsg.value ?? -1;
  }

  Future<void> initImageSprite(String? vvtUrl, List<String>? imageUrls) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.initImageSprite(StringListPlayerMsg()
      ..vvtUrl = vvtUrl
      ..imageUrls = imageUrls
      ..playerId = _playerId);
  }

  Future<Uint8List?> getImageSprite(double time) async {
    await _initPlayer.future;
    UInt8ListMsg int8listMsg = await _vodPlayerApi.getImageSprite(DoublePlayerMsg()
      ..value = time
      ..playerId = _playerId);
    return int8listMsg.value;
  }

  /// To get the total duration
  ///
  /// 获取总时长
  Future<double> getDuration() async {
    if (_isNeedDisposed) return 0;
    await _initPlayer.future;
    DoubleMsg doubleMsg = await _vodPlayerApi.getDuration(PlayerMsg()..playerId = _playerId);
    return doubleMsg.value ?? 0;
  }

  /// Exit picture-in-picture mode if the video player is in picture-in-picture mode.
  ///
  /// 退出画中画，如果该播放器处于画中画模式
  @override
  Future<void> exitPictureInPictureMode() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _vodPlayerApi.exitPictureInPictureMode(PlayerMsg()..playerId = _playerId);
  }

  /// release controller
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
      _netStatusStreamController.close();
    }

    super.dispose();
  }

  @override
  TXPlayerValue? playerValue() {
    return _value;
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
