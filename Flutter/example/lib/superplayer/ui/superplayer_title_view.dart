// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class _VideoTitleView extends StatefulWidget {
  final String _title;
  final _VideoTitleController _controller;
  final bool initIsFullScreen;

  _VideoTitleView(this._controller, this.initIsFullScreen, this._title, GlobalKey<_VideoTitleViewState> key)
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoTitleViewState();
}

class _VideoTitleViewState extends State<_VideoTitleView> {
  String _title = "";
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _title = widget._title;
    _isFullScreen = widget.initIsFullScreen;
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
          ),
          Expanded(child: SizedBox()),
          Visibility(
              visible: _isFullScreen,
              child: InkWell(
                onTap: _onTapMore,
                child: Image(
                  width: 30,
                  height: 30,
                  image: AssetImage("images/superplayer_ic_vod_more_normal.png"),
                ),
              ))
        ],
      ),
    );
  }

  void _onTapMore() {
    widget._controller._onTapMore();
  }

  void _onTapBackBtn() {
    widget._controller._onTapBack();
  }

  void updateTitle(String name) {
    if (mounted) {
      setState(() {
        _title = name;
      });
    }
  }

  void updateUIStatus(int status) {
    setState(() {
      _isFullScreen = status == SuperPlayerUIStatus.FULLSCREEN_MODE;
    });
  }
}

class _VideoTitleController {
  Function _onTapBack;
  Function _onTapMore;

  _VideoTitleController(this._onTapBack, this._onTapMore);
}
