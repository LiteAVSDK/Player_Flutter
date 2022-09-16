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

  double _playableProgress = 0;
  double _currentDuration = 0;
  double _videoDuration = 0;
  double _bufferedDuration = 0;
  bool _showFullScreenBtn = true;
  bool _isPlayMode = false;
  bool _isShowQuality = false; // only showed on fullscreen mode
  bool _isOnDraging = false;
  SuperPlayerType _playerType = SuperPlayerType.VOD;
  VideoQuality? _currentQuality;

  @override
  void initState() {
    if (widget._playerController.isPrepared) {
      _videoDuration = widget._playerController.videoDuration;
      _currentDuration = widget._playerController.currentDuration;
    } else if (null != widget._playerController.videoModel) {
      _videoDuration = widget._playerController.videoModel!.duration.toDouble();
    }

    _isPlayMode = (widget._playerController.playerState == SuperPlayerState.PLAYING);
    bool isFullScreen = widget._playerController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE;
    _showFullScreenBtn = !isFullScreen;
    _isShowQuality = isFullScreen;
    _currentQuality = widget._playerController.currentQuality;
    _playerType = widget._playerController.playerType;

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
      child: VideoSlider(
        min: 0,
        max: _videoDuration,
        value: _currentDuration,
        bufferedValue: _bufferedDuration,
        activeColor: Color(ColorResource.COLOR_MAIN_THEME),
        inactiveColor: Color(ColorResource.COLOR_GRAY),
        sliderColor: Color(ColorResource.COLOR_MAIN_THEME),
        sliderOutterColor: Colors.white,
        progressHeight: 2,
        sliderRadius: 4,
        sliderOutterRadius: 10,
        // 直播禁止时移
        canDrag: _playerType == SuperPlayerType.VOD,
        onDragUpdate: (value) {
          _isOnDraging = true;
        },
        onDragEnd: (value) {
          setState(() {
            _isOnDraging = false;
            _currentDuration = value * _videoDuration;
            widget._playerController.seek(_currentDuration);
            LogUtils.d(TAG,
                "_currentDuration:$_currentDuration,_videoDuration:$_videoDuration");
          });
        },
      ),
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

  void updateDuration(double duration, double videoDuration, double bufferedDration) {
    if (_isOnDraging) {
      return;
    }
    if (duration != _currentDuration || _videoDuration != videoDuration || _bufferedDuration != bufferedDration) {
      if (duration <= videoDuration) {
        setState(() {
          _currentDuration = duration;
          _videoDuration = videoDuration;
          _bufferedDuration = bufferedDration;
        });
      }
    }
  }

  void updatePlayState(bool playing) {
    if (_isPlayMode != playing) {
      setState(() {
        _isPlayMode = playing;
      });
    }
  }

  void updatePlayerType(SuperPlayerType type) {
    if(_playerType != type) {
      setState(() {
        _playerType = type;
      });
    }
  }

  void updateUIStatus(int status) {
    setState(() {
      bool isFullScreen = status == SuperPlayerUIStatus.FULLSCREEN_MODE;
      _showFullScreenBtn = !isFullScreen;
      _isShowQuality = isFullScreen;
    });
  }

  String _buildTextString(double time) {
    Duration duration = Duration(seconds: time.toInt());
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
