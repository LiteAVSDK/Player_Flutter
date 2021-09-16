// @dart = 2.7
part of SuperPlayer;

typedef void SuperPlatformViewCreatedCallback(SuperPlayerPlatformViewController controller);

class SuperPlayerVideo extends StatefulWidget {
  // "playShiftDomain": "liteavapp.timeshift.qcloud.com",
  // "autoPlay": "1",
  // "videoURL": "http://200024424.vod.myqcloud.com/200024424_709ae516bdf811e6ad39991f76a4df69.f20.mp4"
  // final String playShiftDomain;
  // final String autoPlay;
  // final String videoURL;
  // final SuperPlayerViewConfig playerConfig;
  // final SuperPlayerViewModel playerModel;
  // final bool autoPlay;
  // final double startTime;
  //final bool isLockScreen;原生实现问题，暂不支持
  // final bool disableGesture;
  // final bool loop;
  final SuperPlatformViewCreatedCallback onCreated;
  //final bool isFullScreen;原生实现问题，暂不支持

  SuperPlayerVideo({this.onCreated});

  @override
  _SuperPlayerVideoState createState() => _SuperPlayerVideoState();
}

class _SuperPlayerVideoState extends State<SuperPlayerVideo> {
  @override
  Widget build(BuildContext context) {
    return getPlatformView();
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onCreated == null) {
      return;
    }
    SuperPlayerPlatformViewController vc = new SuperPlayerPlatformViewController.init(id);
    widget.onCreated(vc);
  }

  Widget getPlatformView() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      //return Text("Not supported");
      return AndroidView(
          viewType: "super_player_view",
          creationParams: <String, dynamic>{
            //"playerConfig": widget.playerConfig.toJson(),
            //"playerModel":widget.playerModel.toJson(),
            //"autoPlay":widget.autoPlay,
            //"startTime":widget.startTime,
            //"isLockScreen":widget.isLockScreen,
            //"disableGesture":widget.disableGesture,
            //"loop":widget.loop,
            //"isFullScreen":widget.isFullScreen
          },
          onPlatformViewCreated: onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec());
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
          viewType: "super_player_view",
          creationParams: <String, dynamic>{
            //"playerConfig": widget.playerConfig.toJson(),
            //"playerModel":widget.playerModel.toJson(),
            //"autoPlay":widget.autoPlay,
            //"startTime":widget.startTime,
            //"isLockScreen":widget.isLockScreen,
            //"disableGesture":widget.disableGesture,
            //"loop":widget.loop,
            //"isFullScreen":widget.isFullScreen
          },
          onPlatformViewCreated: onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec());
    } else {
      return Text("Not supported");
    }
  }
}