// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// slider
class VideoBottomView extends StatefulWidget {
  final SuperPlayerController _playerController;
  final BottomViewController _controller;

  const VideoBottomView(this._playerController, this._controller, Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoBottomViewState();
  }
}

class _VideoBottomViewState extends State<VideoBottomView> {
  static const TAG = "VideoBottomView";

  double _currentDuration = 0;
  double _videoDuration = 0;
  double _bufferedDuration = 0;
  bool _showFullScreenBtn = true;
  bool _isPlayMode = false;
  bool _isShowQuality = false; // only showed on fullscreen mode
  bool _isOnDraging = false;
  SuperPlayerType _playerType = SuperPlayerType.VOD;
  VideoQuality? _currentQuality;
  final GlobalKey<VideoSliderState> _sliderView = GlobalKey();
  final List<SliderPoint> _playPoints = [];
  List<PlayKeyFrameDescInfo>? keyFrameList;
  PlayKeyFrameDescInfo? showedKeyFrameInfo;

  @override
  void initState() {
    if (widget._playerController.isPrepared) {
      _videoDuration = widget._playerController.videoDuration;
      _currentDuration = widget._playerController.currentDuration;
      _bufferedDuration = 0;
    } else if (null != widget._playerController.videoModel) {
      _videoDuration = widget._playerController.videoModel!.duration.toDouble();
      _currentDuration = 0;
      _bufferedDuration = 0;
    }

    _isPlayMode = (widget._playerController.playerState == SuperPlayerState.PLAYING);
    bool isFullScreen = widget._playerController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE;
    _showFullScreenBtn = !isFullScreen;
    _isShowQuality = isFullScreen;
    _currentQuality = widget._playerController.currentQuality;
    _playerType = widget._playerController.playerType;
    showedKeyFrameInfo = null;
    setKeyFrame(widget._playerController.keyFrameInfo);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: topBottomOffset,
      right: 0,
      left: 0,
      child: Column(
        children: [
          Center(
            child: Visibility(
                visible: null != showedKeyFrameInfo,
                child: null != showedKeyFrameInfo
                    ? Container(
                        decoration: const BoxDecoration(
                            color: Color(ColorResource.COLOR_TRANS_BLACK),
                            borderRadius: BorderRadius.all(Radius.circular(50))),
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                        child: Text(
                          "${Utils.formattedTime(showedKeyFrameInfo!.time)} ${showedKeyFrameInfo!.content}",
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          softWrap: true,
                        ),
                      )
                    : const SizedBox()),
          ),
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/superplayer_bottom_shadow.png", package: PlayerConstants.PKG_NAME),
                    fit: BoxFit.fill)),
            padding: _showFullScreenBtn
                ? const EdgeInsets.only(left: 6, right: 6, bottom: 3)
                : const EdgeInsets.only(left: 20, right: 20, bottom: 13),
            child: Row(
              children: [
                _getPlayImage(),
                SizedBox(
                  width: 35,
                  child: Text(
                    _buildTextString(_currentDuration),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                _getSlider(),
                Text(
                  _buildTextString(_videoDuration),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                _getFullScreenImage(),
                _getQualityButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _getQualityButton() {
    return Visibility(
      visible: _isShowQuality,
      child: InkWell(
          onTap: onTapQualityView,
          child: Container(
            padding: const EdgeInsets.only(left: 5, right: 10),
            child: _currentQuality != null
                ? Text(
                    VideoQualityUtils.transformToQualityName(_currentQuality!.title),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  )
                : Container(),
          )),
    );
  }

  Widget _getPlayImage() {
    return InkWell(
      onTap: onTapStartOrPause,
      child: _isPlayMode
          ? const Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_vod_pause_normal.png", package: PlayerConstants.PKG_NAME),
            )
          : const Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_vod_play_normal.png", package: PlayerConstants.PKG_NAME),
            ),
    );
  }

  Widget _getFullScreenImage() {
    return Visibility(
      visible: _showFullScreenBtn,
      child: InkWell(
        onTap: onSwitchFullScreen,
        child: const Image(
          width: 30,
          height: 30,
          image: AssetImage("images/superplayer_ic_vod_fullscreen.png", package: PlayerConstants.PKG_NAME),
        ),
      ),
    );
  }

  Widget _getSlider() {
    return Expanded(
      child: VideoSlider(
        key: _sliderView,
        min: 0,
        max: _videoDuration,
        value: _currentDuration,
        bufferedValue: _bufferedDuration,
        activeColor: const Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
        inactiveColor: const Color(ColorResource.COLOR_GRAY),
        sliderColor: const Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
        sliderOutterColor: Colors.white,
        progressHeight: 2,
        sliderRadius: 4,
        sliderOutterRadius: 10,
        onPointClick: (double pointX, int pos) {
          if (null != keyFrameList) {
            setState(() {
              showedKeyFrameInfo = keyFrameList![pos];
            });
          }
        },
        // Dragging the progress bar is prohibited during live streaming.
        canDrag: _playerType == SuperPlayerType.VOD,
        playPoints: !_showFullScreenBtn ? _playPoints : [],
        onDragUpdate: (value) {
          _isOnDraging = true;
          _currentDuration = value * _videoDuration;
          widget._controller.onSeekChanged(_currentDuration);
        },
        onDragEnd: (value) {
          setState(() {
            _isOnDraging = false;
            _currentDuration = value * _videoDuration;
            widget._playerController.seek(_currentDuration);
            LogUtils.d(TAG, "_currentDuration:$_currentDuration,_videoDuration:$_videoDuration");
            widget._controller.onSeekEnd();
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
          if (_bufferedDuration > _videoDuration) {
            _bufferedDuration = _videoDuration;
          }
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
    if (_playerType != type) {
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
    // Return the whole number of seconds that this duration spans
    String inSeconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    // Return the whole number of minutes that this duration spans.
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

  void setKeyFrame(List<PlayKeyFrameDescInfo>? keyFrameList) {
    this.keyFrameList = keyFrameList;
    _playPoints.clear();
    if (null != keyFrameList) {
      for (PlayKeyFrameDescInfo info in keyFrameList) {
        double progress = info.time / _videoDuration;
        SliderPoint point = SliderPoint();
        point.progress = progress;
        _playPoints.add(point);
      }
    }
    setState(() {});
  }
}

class BottomViewController {
  Function onTapStart;
  Function onTapFullScreen;
  Function onTapQuality;
  Function(double value) onSeekChanged;
  Function onSeekEnd;

  BottomViewController(this.onTapStart, this.onTapFullScreen, this.onTapQuality, this.onSeekChanged, this.onSeekEnd);
}
