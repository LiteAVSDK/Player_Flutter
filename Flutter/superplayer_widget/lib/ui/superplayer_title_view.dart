// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class _VideoTitleView extends StatefulWidget {
  final String _title;
  final _VideoTitleController _controller;
  final bool initIsFullScreen;

  const _VideoTitleView(this._controller, this.initIsFullScreen, this._title, GlobalKey<_VideoTitleViewState> key)
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
      padding: const EdgeInsets.only(left: 10, right: 15),
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("images/superplayer_top_shadow.png", package: StringResource.PKG_NAME),
              fit: BoxFit.fill)),
      child: Row(
        children: [
          InkWell(
            onTap: _onTapBackBtn,
            child: const Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_btn_back_play.png", package: StringResource.PKG_NAME),
            ),
          ),
          Text(
            _title,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          const Expanded(child: SizedBox()),
          Visibility(
              visible: _isFullScreen,
              child: InkWell(
                onTap: _onTapMore,
                child: const Image(
                  width: 40,
                  height: 40,
                  image: AssetImage("images/superplayer_ic_vod_more_normal.png", package: StringResource.PKG_NAME),
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
  final Function _onTapBack;
  final Function _onTapMore;

  _VideoTitleController(this._onTapBack, this._onTapMore);
}
