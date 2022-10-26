// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class SuperPlayerCoverView extends StatefulWidget {
  final CoverViewController _controller;
  final SuperPlayerModel? videoModel;

  const SuperPlayerCoverView(this._controller, Key key, this.videoModel) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SuperPlayerCoverViewState();
}

class _SuperPlayerCoverViewState extends State<SuperPlayerCoverView> {
  bool _isShowCover = true;
  SuperPlayerModel? _videoModel;

  @override
  void initState() {
    super.initState();
    if (widget.videoModel != null) {
      _isShowCover = true;
      _videoModel = widget.videoModel;
    } else {
      _isShowCover = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasCover = false;
    String coverUrl = "";
    if (null != _videoModel) {
      SuperPlayerModel model = _videoModel!;
      // custom cover is preferred
      if (model.customeCoverUrl.isNotEmpty) {
        coverUrl = model.customeCoverUrl;
        hasCover = true;
      } else if (model.coverUrl.isNotEmpty) {
        coverUrl = model.coverUrl;
        hasCover = true;
      }
    }

    return Visibility(
      visible: _isShowCover && hasCover,
      child: Positioned.fill(
          top: topBottomOffset,
          bottom: topBottomOffset,
          left: 0,
          right: 0,
          child: InkWell(
            onDoubleTap: _onDoubleTapVideo,
            onTap: _onSingleTapVideo,
            child: Container(
              decoration: const BoxDecoration(
                // 增加一个半透明背景，防止透明封面图的出现
                color:Color(ColorResource.COLOR_TRANS_GRAY)
              ),
              child: Image.network(coverUrl,fit: BoxFit.cover),
            )
          )),
    );
  }

  void _onDoubleTapVideo() {
    widget._controller.onDoubleTapVideo();
  }

  void _onSingleTapVideo() {
    widget._controller.onSingleTapVideo();
  }

  void showCover(SuperPlayerModel model) {
    setState(() {
      _videoModel = model;
      _isShowCover = true;
    });
  }

  void hideCover() {
    setState(() {
      _isShowCover = false;
    });
  }
}

class CoverViewController {
  Function onDoubleTapVideo;
  Function onSingleTapVideo;

  CoverViewController(this.onDoubleTapVideo, this.onSingleTapVideo);
}
