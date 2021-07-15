part of SuperPlayer;

class TXVodPlayerController extends ChangeNotifier implements ValueListenable<TXPlayerValue>, TXPlayerController {
  int _playerId = -1;

  final Completer<int> _initPlayer;
  final Completer<int> _createTexture;
  bool _isDisposed = false;
  bool _isNeedDisposed = false;
  MethodChannel _channel;
  TXPlayerValue _value;
  TXPlayerState _state;

  TXPlayerState get playState => _state;
  StreamSubscription _eventSubscription;
  StreamSubscription _netSubscription;

  final StreamController<TXPlayerState> _stateStreamController =
  StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic> > _eventStreamController =
  StreamController.broadcast();

  final StreamController<Map<dynamic, dynamic> > _netStatusStreamController =
  StreamController.broadcast();

  Stream<TXPlayerState> get onPlayerState => _stateStreamController.stream;
  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;
  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _netStatusStreamController.stream;

  TXVodPlayerController()
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = TXPlayerValue.uninitialized();
    _state = _value.state;
    _create();
  }

  Future<void> _create() async {
    _playerId = await SuperPlayerPlugin.createVodPlayer();
    _channel = MethodChannel("cloud.tencent.com/txvodplayer/$_playerId");
    _eventSubscription =
        EventChannel("cloud.tencent.com/txvodplayer/event/$_playerId")
            .receiveBroadcastStream("event")
            .listen(_eventHandler, onError: _errorHandler);
    _netSubscription =
        EventChannel("cloud.tencent.com/txvodplayer/net/$_playerId")
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
      case 2005://播放进度
        break;
      case 2006:
        _changeState(TXPlayerState.stopped);
        break;
      case 2007:
        _changeState(TXPlayerState.buffering);
        break;
      case 2009://下行视频分辨率改变
        break;
      case 2013://点播加载完成
        break;
      case 2014://loading 结束
        break;
      case -2301:
        _changeState(TXPlayerState.failed);
        break;
      case -2303:
        _changeState(TXPlayerState.failed);
        break;
      case -2305:
        _changeState(TXPlayerState.failed);
        break;
      case 2103:
        break;
      case 3001:
        break;
      case 3002:
        break;
      case 3003:

        break;

      default:
        break;
    }

    _eventStreamController.add(map);
  }

  _netHandler(event) {
    if(event == null) return;
    final Map<dynamic, dynamic> map = event;
    _netStatusStreamController.add(map);
  }

  _errorHandler(error) {}

  _changeState(TXPlayerState playerState){
    value = _value.copyWith(state: playerState);
    _state = value.state;
    _stateStreamController.add(_state);
  }

  Future<bool> play(String url) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    final result =
    await _channel.invokeMethod("play", {"url": url});
    return result == 0;
  }

  Future<bool> startPlayWithParams(TXPlayerAuthParams params) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(TXPlayerState.buffering);

    final result =
    await _channel.invokeMethod("startPlayWithParams", params.toJson());
    return result == 0;
  }

  Future<int> get textureId async {
    return _createTexture.future;
  }

  Future<void> initialize({bool onlyAudio}) async{
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    final textureId = await _channel.invokeMethod("init", {
      "onlyAudio": onlyAudio ?? false,
    });
    _createTexture.complete(textureId);
    _changeState(TXPlayerState.paused);
  }

  Future<void> setIsAutoPlay({bool isAutoPlay}) async{
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    await _channel.invokeMethod("setIsAutoPlay", {"isAutoPlay": isAutoPlay ?? false});
  }

  Future<bool> stop({bool isNeedClear = true}) async {
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    final result =
    await _channel.invokeMethod("stop", {"isNeedClear": isNeedClear});
    _changeState(TXPlayerState.stopped);
    return result == 0;
  }

  Future<bool> isPlaying() async {
    await _initPlayer.future;
    return await _channel.invokeMethod("isPlaying");
  }

  Future<void> pause() async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("pause");
    _changeState(TXPlayerState.paused);
  }

  Future<void> resume() async {
    if (_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("resume");
  }

  Future<void> setMute(bool mute) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMute", {"mute": mute});
  }

  Future<void> setLoop(bool loop) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLoop", {"loop": loop});
  }

  Future<void> seek(double progress) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("seek", {"progress": progress});
  }

  Future<void> setRate(double rate) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setRate", {"rate": rate});
  }

  Future<List> getSupportedBitrates() async {
    if(_isNeedDisposed) return [];
    await _initPlayer.future;
    return _channel.invokeMethod("getSupportedBitrates");
  }

  Future<void> setBitrateIndex(int index) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setBitrateIndex", {"index": index});
  }

  Future<void> setStartTime(double startTime) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setStartTime", {"startTime": startTime});
  }

  Future<void> setAudioPlayoutVolume(int volume) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setAudioPlayoutVolume", {"volume": volume});
  }

  Future<void> setRenderRotation(int rotation) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setRenderRotation", {"rotation": rotation});
  }

  Future<void> setMirror(bool isMirror) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMirror", {"isMirror": isMirror});
  }

  Future<void> _release() async {
    await _initPlayer.future;
    await SuperPlayerPlugin.releasePlayer(_playerId);
  }

  @override
  void dispose() async{
    _isNeedDisposed = true;
    if(!_isDisposed){
      await _eventSubscription.cancel();
      _eventSubscription = null;

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
  // TODO: implement value

  get value => _value;

  set value(TXPlayerValue val){
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

}