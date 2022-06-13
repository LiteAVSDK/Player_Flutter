// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// slider
class VideoBottomView extends StatefulWidget {
  final SuperPlayerController _playerController;
  final _BottomViewController _controller;

  VideoBottomView(this._playerController, this._controller, GlobalKey<_VideoBottomViewState> key) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoBottomViewState();
  }
}

class _VideoBottomViewState extends State<VideoBottomView> {
  static const TAG = "VideoBottomView";

  double _currentProgress = 0;
  int _currentDuration = 0;
  int _videoDuration = 0;
  bool _showFullScreenBtn = true;
  bool _isPlayMode = false;
  bool _isShowQuality = false; // only showed on fullscreen mode
  VideoQuality? _currentQuality;

  @override
  void initState() {
    if (widget._playerController.isPrepared) {
      _videoDuration = widget._playerController.videoDuration;
      _currentDuration = widget._playerController.currentDuration;
    } else if (null != widget._playerController.videoModel) {
      _videoDuration = widget._playerController.videoModel!.duration;
    }

    _isPlayMode = (widget._playerController.playerState == SuperPlayerState.PLAYING);
    _showFullScreenBtn = !widget._playerController._isFullScreen;
    _isShowQuality = widget._playerController._isFullScreen;
    _currentQuality = widget._playerController.currentQuality;
    _fixProgress();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: topBottomOffset,
      right: 0,
      left: 0,
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("images/superplayer_bottom_shadow.png"), fit: BoxFit.fill)),
        padding: EdgeInsets.only(left: 6, right: 6),
        child: Row(
          children: [
            _getPlayImage(),
            Text(
              _buildTextString(_currentDuration),
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            _getSlider(),
            Text(
              _buildTextString(_videoDuration),
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            _getFullScreenImage(),
            _getQualityButton(),
          ],
        ),
      ),
    );
  }

  Widget _getQualityButton() {
    return Visibility(
      visible: _isShowQuality,
      child: InkWell(
          onTap: onTapQualityView,
          child: Container(
            padding: EdgeInsets.only(left: 5),
            child: _currentQuality != null
                ? Text(
                    VideoQualityUtils.transformToQualityName(_currentQuality!.title),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  )
                : Container(),
          )),
    );
  }

  Widget _getPlayImage() {
    return InkWell(
      onTap: onTapStartOrPause,
      child: _isPlayMode
          ? Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_vod_pause_normal.png"),
            )
          : Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_vod_play_normal.png"),
            ),
    );
  }

  Widget _getFullScreenImage() {
    return Visibility(
      visible: _showFullScreenBtn,
      child: InkWell(
        onTap: onSwitchFullScreen,
        child: Image(
          width: 30,
          height: 30,
          image: AssetImage("images/superplayer_ic_vod_fullscreen.png"),
        ),
      ),
    );
  }

  Widget _getSlider() {
    return Expanded(
      child: Theme(
          data: ThemeResource.getCommonSliderTheme(),
          child: Slider(
            min: 0,
            max: 1,
            value: _currentProgress,
            onChanged: (double value) {
              setState(() {
                _currentProgress = value;
              });
            },
            onChangeEnd: (double value) {
              setState(() {
                _currentProgress = value;
                widget._playerController.seek(_currentProgress * _videoDuration);
                LogUtils.d(TAG,
                    "_currentProgress:$_currentProgress,_videoDuration:$_videoDuration,currentDuration:${_currentProgress * _videoDuration}");
              });
            },
          )),
    );
  }

  void onSwitchFullScreen() {
    widget._controller.onTapFullScreen();
  }

  void onTapStartOrPause() {
    widget._controller.onTapStart();
  }

  void onTapQualityView() {
    widget._controller.onTapQuality();
  }

  void updateDuration(int duration, int videoDuration) {
    if (duration != _currentDuration || _videoDuration != videoDuration) {
      if (duration <= videoDuration) {
        setState(() {
          _currentDuration = duration;
          _videoDuration = videoDuration;
          _fixProgress();
        });
      }
    }
  }

  void _fixProgress() {
    // provent division zero problem
    if(_videoDuration == 0) {
      _currentProgress = 0;
    } else {
      _currentProgress = _currentDuration / _videoDuration;
    }
    if(_currentProgress < 0) {
      _currentProgress = 0;
    }
    if(_currentProgress > 1) {
      _currentProgress = 1;
    }
  }

  void updatePlayState(bool playing) {
    if (_isPlayMode != playing) {
      setState(() {
        _isPlayMode = playing;
      });
    }
  }

  void updateFullScreen(bool showFullScreen) {
    setState(() {
      _showFullScreenBtn = !showFullScreen;
      _isShowQuality = showFullScreen;
    });
  }

  String _buildTextString(int time) {
    Duration duration = Duration(seconds: time);
    // 返回此持续时间跨越的整秒数。
    String inSeconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    // 返回此持续时间跨越的整分钟数。
    String inMinutes = duration.inMinutes.toString().padLeft(2, '0');
    return "$inMinutes:$inSeconds";
  }

  void updateQuality(VideoQuality? quality) {
    if (quality != null && quality != _currentQuality) {
      setState(() {
        _currentQuality = quality;
      });
    }
  }
}

class _BottomViewController {
  Function onTapStart;
  Function onTapFullScreen;
  Function onTapQuality;

  _BottomViewController(this.onTapStart, this.onTapFullScreen, this.onTapQuality);
}
