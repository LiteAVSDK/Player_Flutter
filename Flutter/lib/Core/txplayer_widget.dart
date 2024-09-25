// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;

  TXPlayerVideo({required this.controller});

  @override
  TXPlayerVideoState createState() => TXPlayerVideoState();
}

class TXPlayerVideoState extends State<TXPlayerVideo> {
  static const TAG = "TXPlayerVideo";
  int _textureId = -1;
  double _iosOffset = -1;

  StreamSubscription? streamSubscription;

  @override
  void initState() {
    super.initState();
    _obtainTextureId();
  }

  @override
  void didUpdateWidget(covariant TXPlayerVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _obtainTextureId();
  }

  void _obtainTextureId() async {
    int remainTextureId = await widget.controller.textureId;
    if (_textureId != remainTextureId) {
      setState(() {
        _textureId = remainTextureId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TXPlayerController controller = widget.controller;
    if ((defaultTargetPlatform == TargetPlatform.android) &&
        (controller.resizeVideoHeight! > 0 && controller.resizeVideoWidth! > 0)) {
      return _textureId == -1
          ? Container()
          : LayoutBuilder(builder: (context, constrains) {
        var viewWidth = constrains.maxWidth;
        var viewHeight = constrains.maxHeight;
        var videoWidth = controller.resizeVideoWidth!;
        var videoHeight = controller.resizeVideoHeight!;

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
      return _textureId == -1 ? Container() : _buildIOSRotate();
    }
  }

  Widget _buildIOSRotate() {
    var degree = widget.controller.playerValue()?.degree;
    var quarterTurns = ( degree! / 90).floor();
    if (quarterTurns == 0) {
      return _buildIOSTexture(_textureId);
    } else {
      return RotatedBox(quarterTurns: quarterTurns, child: _buildIOSTexture(_textureId));
    }
  }

  Widget _buildIOSTexture(int textureId) {
    return Stack(
      children: [
        Positioned(
            top: _iosOffset,
            left: _iosOffset,
            right: _iosOffset,
            bottom: _iosOffset,
            child: Texture(textureId: textureId))
      ],
    );
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }
}
