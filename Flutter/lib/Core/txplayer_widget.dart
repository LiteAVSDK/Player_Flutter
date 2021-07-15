part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;

  TXPlayerVideo({@required this.controller}):assert(controller != null);

  @override
  _TXPlayerVideoState createState() => _TXPlayerVideoState();
}

class _TXPlayerVideoState extends State<TXPlayerVideo> {
  int _textureId = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.textureId.then((val) {
      setState(() {
        print("_textureId = $val");
        _textureId = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == -1
        ? Container()
        : Texture(
            textureId: _textureId,
          );
  }
}
