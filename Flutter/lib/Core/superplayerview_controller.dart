
part of SuperPlayer;

class SuperPlayerPlatformViewController {
  late MethodChannel _channel;
  StreamSubscription? _eventSubscription;
  final StreamController<Map<dynamic, dynamic>> _eventStreamController =
  StreamController.broadcast();
  Stream<Map<dynamic, dynamic>> get onPlayerEventBroadcast => _eventStreamController.stream;

  SuperPlayerPlatformViewController.init(int id) {
    _channel = new MethodChannel('cloud.tencent.com/superPlayer/$id');
    _eventSubscription =
        EventChannel("cloud.tencent.com/superPlayer/event/$id")
            .receiveBroadcastStream()
            .listen(_eventHandler, onError: _errorHandler);
  }

  _eventHandler(event) {
    if(event == null) return;
    _eventStreamController.add(event);
  }

  _errorHandler(error) {
    //debugPrint("= error = ${error.toString()}");
  }


  Future<void> reloadView({String url = "", int appId = 0, String fileId = "", String psign = ""}) async {
    return _channel.invokeMethod('reloadView', {"url": url, "appId":appId, "fileId": fileId, "psign":psign});
  }

  Future<void> playWithModel(SuperPlayerViewModel model) async {
    return _channel.invokeMethod('play', {"playerModel": model.toJson()});
  }

  Future<void> setPlayConfig(SuperPlayerViewConfig config) async {
    return _channel.invokeMethod('playConfig', {"config": config.toJson()});
  }

  Future<void> setIsAutoPlay({bool? isAutoPlay}) async{
    await _channel.invokeMethod("setIsAutoPlay", {"isAutoPlay": isAutoPlay ?? false});
  }

  Future<void> setStartTime(double startTime) async {
    await _channel.invokeMethod("setStartTime", {"startTime": startTime});
  }

  // Future<void> setIsLockScreen(bool isLock) async {
  //   await _channel.invokeMethod("setIsLockScreen", {"isLock": isLock});
  // }

  Future<void> disableGesture(bool enable) async {
    await _channel.invokeMethod("disableGesture", {"enable": enable});
  }

  Future<void> setLoop(bool loop) async {
    await _channel.invokeMethod("setLoop", {"loop": loop});
  }

  Future<void> resetPlayer() async {
    await _channel.invokeMethod("resetPlayer");
  }
  Future<void> pause() async {
    await _channel.invokeMethod("pause");
  }

  Future<void> resume() async {
    await _channel.invokeMethod("resume");
  }

  Future<void> stop() async {
    await _channel.invokeMethod("stop");
  }


}