
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

  final StreamController<TXPlayerState?> _stateStreamController =
  StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic> > _eventStreamController =
  StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic> > _netStatusStreamController =
  StreamController.broadcast();

  Stream<TXPlayerState?> get onPlayerState => _stateStreamController.stream;
  Stream<Map<dynamic, dynamic> > get onPlayerEventBroadcast => _eventStreamController.stream;
  Stream<Map<dynamic, dynamic> > get onPlayerNetStatusBroadcast => _netStatusStreamController.stream;

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
    _eventSubscription =
        EventChannel("cloud.tencent.com/txliveplayer/event/$_playerId")
            .receiveBroadcastStream("event")
            .listen(_eventHandler, onError: _errorHandler);
    _netSubscription =
        EventChannel("cloud.tencent.com/txliveplayer/net/$_playerId")
            .receiveBroadcastStream("net")
            .listen(_netHandler, onError: _errorHandler);
    _initPlayer.complete(_playerId);
  }

  ///
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  _eventHandler(event) {
    if(event == null) return;
    final Map<dynamic, dynamic> map = event;
    //debugPrint("= event = ${map.toString()}");
    switch(map["event"]){
      case 2002:
        break;
      case 2003:
        if(_isNeedDisposed) return;
        if(_state == TXPlayerState.buffering) _changeState(TXPlayerState.playing);
        break;
      case 2004:
        if(_isNeedDisposed) return;
        if(_state == TXPlayerState.buffering) _changeState(TXPlayerState.playing);
        break;
      case 2005://EVT_PLAY_PROGRESS
        break;
      case 2006:
        _changeState(TXPlayerState.stopped);
        break;
      case 2007:
        _changeState(TXPlayerState.buffering);
        break;
      case 2009://下行视频分辨率改变
        if (defaultTargetPlatform == TargetPlatform.android) {
          resizeVideoWidth = (event["videoWidth"]).toDouble();
          resizeVideoHeight = (event["videoHeight"]).toDouble();
          if(resizeVideoWidth! > 0 && resizeVideoHeight! > 0) {
            videoLeft = (event["videoLeft"]).toDouble();
            videoTop = (event["videoTop"]).toDouble();
            videoRight = (event["videoRight"]).toDouble();
            videoBottom = (event["videoBottom"]).toDouble();
          }
        }
        break;
      case 2015://直播，切流成功（切流可以播放不同画面大小的视频）
        break;
      case -2301://disconnect
        _changeState(TXPlayerState.failed);
        break;
      case 2103://reconnect
        break;
      case 3001://dnsFail
        break;
      case 3002://severConnFail
        break;
      case 3003://shakeFail
        break;
      case -2307://failed
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
    if(event == null) return;
    final Map<dynamic, dynamic> map = event;
    _netStatusStreamController.add(map);
  }

  _changeState(TXPlayerState playerState){
    value = _value!.copyWith(state: playerState);
    _state = value!.state;
    _stateStreamController.add(_state);
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  ///
  Future<bool> play(String url, {int? playType}) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    final result =
    await _channel.invokeMethod("play", {"url": url, "playType": playType});
    return result == 0;
  }

  Future<void> initialize({bool? onlyAudio}) async{
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    final textureId = await _channel.invokeMethod("init", {
      "onlyAudio": onlyAudio ?? false,
    });
    _createTexture.complete(textureId);
    _state = TXPlayerState.paused;
  }

  Future<void> setIsAutoPlay({bool? isAutoPlay}) async{
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setIsAutoPlay", {"isAutoPlay":isAutoPlay ?? false});
  }

  Future<bool> stop({bool isNeedClear = true}) async {
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    final result =
    await _channel.invokeMethod("stop", {"isNeedClear": isNeedClear});
    _changeState(TXPlayerState.stopped);
    return result == 0;
  }

  Future<bool?> isPlaying() async {
    await _initPlayer.future;
    return await _channel.invokeMethod("isPlaying");
  }

  Future<void> pause() async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("pause");
    if(_state != TXPlayerState.paused) _changeState(TXPlayerState.paused);
  }

  Future<void> resume() async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("resume");
    if(_state != TXPlayerState.playing) _changeState(TXPlayerState.playing);
  }

  Future<void> setLiveMode(TXPlayerLiveMode mode) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLiveMode", {"type": mode.index});
  }

  Future<void> setVolume(int volume) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setVolume", {"volume": volume});
  }

  Future<void> setMute(bool mute) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMute", {"mute": mute});
  }

  Future<void> setRenderRotation(int rotation) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setRenderRotation", {"rotation": rotation});
  }

  Future<void> switchStream(String url) async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("switchStream", {"url": url});
  }

  Future<void> seek(double progress) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"progress": progress});
  }

  Future<void> setAppID(int appId) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"appId": appId});
  }

  Future<void> prepareLiveSeek(String domain, int bizId) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("prepareLiveSeek", {"domain":domain, "bizId":bizId});
  }

  Future<void> _release() async {
    await _initPlayer.future;
    // await _channel.invokeMethod("destory");
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  @override
  void dispose() async{
    _isNeedDisposed = true;
    if(!_isDisposed){
      await _eventSubscription!.cancel();
      _eventSubscription = null;

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

  set value(TXPlayerValue? val){
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  @override
  // TODO: implement textureId
  Future<int> get textureId  async {
    return _createTexture.future;
  }

  double? resizeVideoWidth = 0;
  double? resizeVideoHeight = 0;
  double? videoLeft = 0;
  double? videoTop = 0;
  double? videoRight = 0;
  double? videoBottom = 0;

}