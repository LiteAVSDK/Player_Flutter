// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;

  TXPlayerVideo({required this.controller, Key? key}) : super(key: key) {
    assert(controller != null);
  }

  @override
  TXPlayerVideoState createState() => TXPlayerVideoState();
}

class TXPlayerVideoState extends State<TXPlayerVideo> {
  static const TAG = "TXPlayerVideo";
  int _textureId = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.textureId.then((newTextureId) {
      if (_textureId != newTextureId) {
        setState(() {
          LogUtils.d(TAG, "_textureId = $newTextureId");
          _textureId = newTextureId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((defaultTargetPlatform == TargetPlatform.android) &&
        (widget.controller.resizeVideoHeight! > 0 && widget.controller.resizeVideoWidth! > 0)) {
      return _textureId == -1
          ? Container()
          : LayoutBuilder(builder: (context, constrains) {
              var viewWidth = constrains.maxWidth;
              var viewHeight = constrains.maxHeight;
              var videoWidth = widget.controller.resizeVideoWidth!;
              var videoHeight = widget.controller.resizeVideoHeight!;

              double left = widget.controller.videoLeft! * viewWidth / videoWidth;
              double top = widget.controller.videoTop! * viewHeight / videoHeight;
              double right = widget.controller.videoRight! * viewWidth / videoWidth;
              double bottom = widget.controller.videoBottom! * viewHeight / videoHeight;
              return Stack(
                children: [
                  Positioned(
                      top: top,
                      left: left,
                      right: right,
                      bottom: bottom,
                      child: Texture(textureId: _textureId)
                  )
                ],
              );
            });
    } else {
      return _textureId == -1
          ? Container()
          : Texture(textureId: _textureId);
    }
  }
}
