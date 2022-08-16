// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;
  final Stream<TXPlayerHolder>? playerStream;

  TXPlayerVideo({required this.controller, this.playerStream});

  @override
  TXPlayerVideoState createState() => TXPlayerVideoState();
}

class TXPlayerVideoState extends State<TXPlayerVideo> {
  static const TAG = "TXPlayerVideo";
  int _textureId = -1;

  StreamSubscription? streamSubscription;
  late TXPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    _checkStreamListen();
    _resetControllerLink();
  }

  void _checkStreamListen() {
    if(null != streamSubscription) {
      streamSubscription!.cancel();
    }
    streamSubscription = widget.playerStream?.listen((event) {
      controller = event.controller;
      _resetControllerLink();
    });
  }

  void _resetControllerLink() async {
    int remainTextureId = await controller.textureId;
    if (remainTextureId >= 0) {
      if (remainTextureId != _textureId) {
        setState(() {
          LogUtils.d(TAG, "_textureId = $remainTextureId");
          _textureId = remainTextureId;
        });
      }
    } else {
      setState(() {
        _textureId = -1;
      });
      controller.textureId.then((newTextureId) {
        if (_textureId != newTextureId) {
          setState(() {
            LogUtils.d(TAG, "_textureId = $newTextureId");
            _textureId = newTextureId;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((defaultTargetPlatform == TargetPlatform.android) &&
        (controller.resizeVideoHeight! > 0 && controller.resizeVideoWidth! > 0)) {
      return _textureId == -1
          ? Container()
          : LayoutBuilder(builder: (context, constrains) {
        var viewWidth = constrains.maxWidth;
        var viewHeight = constrains.maxHeight;
        var videoWidth = controller.resizeVideoWidth!;
        var videoHeight = widget.controller.resizeVideoHeight!;

        double left = controller.videoLeft! * viewWidth / videoWidth;
        double top = controller.videoTop! * viewHeight / videoHeight;
        double right = controller.videoRight! * viewWidth / videoWidth;
        double bottom = controller.videoBottom! * viewHeight / videoHeight;
        return Stack(
          children: [
            Positioned(
                top: top, left: left, right: right, bottom: bottom, child: Texture(textureId: _textureId))
          ],
        );
      });
    } else {
      return _textureId == -1 ? Container() : Texture(textureId: _textureId);
    }
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }
}
