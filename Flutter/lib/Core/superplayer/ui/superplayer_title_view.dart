part of SuperPlayer;

class _VideoTitleView extends StatefulWidget {

  final String _title;
  final _VideoTitleController _controller;

  _VideoTitleView(this._controller ,this._title, GlobalKey<_VideoTitleViewState> key):super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTitleViewState();
}

class _VideoTitleViewState extends State<_VideoTitleView> {

  String _title = "";
  @override
  void initState() {
    super.initState();
    _title = widget._title;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage("images/superplayer_top_shadow.png"), fit: BoxFit.fill)),
      child: Row(
        children: [
          InkWell(
            onTap: _onTapBackBtn,
            child: Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_btn_back_play.png"),
            ),
          ),
          Text(
            _title,
            style: TextStyle(fontSize: 11, color: Colors.white),
          )
        ],
      ),
    );
  }

  void _onTapBackBtn() {
    widget._controller._onTapBack();
  }

  void updateTitle(String name) {
    if(mounted) {
      setState(() {
        _title = name;
      });
    }
  }
}

class _VideoTitleController {
  Function _onTapBack;
  _VideoTitleController(this._onTapBack);
}