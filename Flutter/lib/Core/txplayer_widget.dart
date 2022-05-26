
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;

  TXPlayerVideo({required this.controller}):assert(controller != null);

  @override
  _TXPlayerVideoState createState() => _TXPlayerVideoState();
}

class _TXPlayerVideoState extends State<TXPlayerVideo> {
  static const TAG = "TXPlayerVideo";
  int _textureId = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.textureId.then((val) {
      setState(() {
        LogUtils.d(TAG, "_textureId = $val");
        _textureId = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((defaultTargetPlatform == TargetPlatform.android) && (widget.controller.resizeVideoHeight! > 0 && widget.controller.resizeVideoWidth! > 0)) {
      return _textureId == -1
          ? Container()
          : LayoutBuilder(builder: (context, constrains) {
        var viewWidth = constrains.maxWidth;
        var viewHeight = constrains.maxHeight;
        var videoWidth = widget.controller.resizeVideoWidth!;
        var videoHeight = widget.controller.resizeVideoHeight!;

        double left = widget.controller.videoLeft! * viewWidth/videoWidth;
        double top = widget.controller.videoTop! * viewHeight/videoHeight;
        double right = widget.controller.videoRight! * viewWidth/videoWidth;
        double bottom = widget.controller.videoBottom! * viewHeight/videoHeight;
        return Stack(
          children: [
            Positioned(
                top: top,
                left: left,
                right: right,
                bottom: bottom,
                child:Texture(
                  textureId: _textureId,
                )
            )
          ],
        );
      });
    }else {
      return _textureId == -1
          ? Container()
          : Texture(
        textureId: _textureId,
      );
    }
  }
}
