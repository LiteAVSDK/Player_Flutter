// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class _VideoTitleView extends StatefulWidget {
  final String _title;
  final _VideoTitleController _controller;
  final bool initIsFullScreen;
  final bool showDownload;
  final bool isDownloaded;
  bool showAudioView = false;
  bool showSubtitleView = false;

  _VideoTitleView(
      this._controller, this.initIsFullScreen, this._title, this.showDownload, this.isDownloaded, GlobalKey<_VideoTitleViewState> key,
      {this.showAudioView = false, this.showSubtitleView = false})
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
              image: AssetImage("images/superplayer_top_shadow.png", package: PlayerConstants.PKG_NAME),
              fit: BoxFit.fill)),
      child: Row(
        children: [
          // back
          InkWell(
            onTap: _onTapBackBtn,
            child: Container(
              padding: const EdgeInsets.only(top:5, bottom: 5),
              child:  Image(
                width: _isFullScreen ? 50 : 30,
                height: _isFullScreen ? 50 : 30,
                image: AssetImage("images/superplayer_btn_back_play.png", package: PlayerConstants.PKG_NAME),
              ),
            ),
          ),
          // video name
          Text(
            _title,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          const Expanded(child: SizedBox()),
          // subtitle
          Visibility(
            visible: _isFullScreen && widget.showSubtitleView,
            child: InkWell(
              onTap: _onTapSubtitle,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 8, right: 8),
                width: 40,
                height: 40,
                child: const Image(
                  image: AssetImage("images/superplayer_multi_subtitle.png", package: PlayerConstants.PKG_NAME),
                ),
              ),
            ),
          ),
          // audio
          Visibility(
            visible: _isFullScreen && widget.showAudioView,
            child: InkWell(
              onTap: _onTapAudio,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 8, right: 8),
                width: 40,
                height: 40,
                child: const Image(
                  image: AssetImage("images/superplayer_multi_audio.png", package: PlayerConstants.PKG_NAME),
                ),
              ),
            ),
          ),
          // download
          Visibility(
            visible: _isFullScreen && widget.showDownload,
            child: InkWell(
              onTap: _onTapDownload,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 8, right: 8),
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    const Image(
                        image: AssetImage("images/superplayer_ic_vod_download.png", package: PlayerConstants.PKG_NAME)),
                    Visibility(
                        visible: widget.isDownloaded,
                        child: const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Image(
                                width: 12,
                                height: 12,
                                image: AssetImage("images/superplayer_ic_vod_check_done.png",
                                    package: PlayerConstants.PKG_NAME))))
                  ],
                ),
              ),
            ),
          ),
          // more menu
          Visibility(
              visible: _isFullScreen,
              child: InkWell(
                onTap: _onTapMore,
                child: const Image(
                  width: 40,
                  height: 40,
                  image: AssetImage("images/superplayer_ic_vod_more_normal.png", package: PlayerConstants.PKG_NAME),
                ),
              ))
        ],
      ),
    );
  }

  void _onTapSubtitle() {
    widget._controller._onTapSubtitle();
  }

  void _onTapAudio() {
    widget._controller._onTapAudio();
  }

  void _onTapMore() {
    widget._controller._onTapMore();
  }

  void _onTapBackBtn() {
    widget._controller._onTapBack();
  }

  void _onTapDownload() {
    if (!widget.isDownloaded) {
      widget._controller._onTapDownload();
    }
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
  final Function _onTapDownload;
  final Function _onTapSubtitle;
  final Function _onTapAudio;

  _VideoTitleController(this._onTapBack, this._onTapMore, this._onTapDownload, this._onTapSubtitle, this._onTapAudio);
}
