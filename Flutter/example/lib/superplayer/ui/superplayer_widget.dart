// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

final double topBottomOffset = 0;
int manualOrientationDirection = TXVodPlayEvent.ORIENTATION_LANDSCAPE_RIGHT;
FullScreenController _fullScreenController = FullScreenController();

/// superplayer view widget
class SuperPlayerView extends StatefulWidget {
  final SuperPlayerController _controller;

  SuperPlayerView(this._controller, {Key? viewKey}) : super(key: viewKey);

  @override
  State<StatefulWidget> createState() => SuperPlayerViewState();
}

class SuperPlayerViewState extends State<SuperPlayerView> with WidgetsBindingObserver {
  static final int _controlViewShowTime = 7000;
  static const TAG = "SuperPlayerViewState";

  late SuperPlayerController _playController;
  bool _isFloatingMode = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isShowCover = true;

  double _radioWidth = 0;
  double _radioHeight = 0;
  double _aspectRatio = 16.0 / 9.0;
  double _videoWidth = 0;
  double _videoHeight = 0;

  bool _isShowControlView = false;
  bool _isShowQualityView = false;
  bool _isShowQualityListView = false;

  late _BottomViewController _bottomViewController;
  late _QualityListViewController _qualitListViewController;
  late _VideoTitleController _titleViewController;
  late _SuperPlayerFullScreenController _superPlayerFullUIController;
  late _CoverViewController _coverViewController;
  late _MoreViewController _moreViewController;

  StreamSubscription? _volumeSubscription;
  StreamSubscription? _pipSubscription;

  /// init
  Timer _controlViewTimer = Timer(Duration(milliseconds: _controlViewShowTime), () {});

  GlobalKey<_VideoBottomViewState> _videoBottomKey = GlobalKey();
  GlobalKey<_QualityListViewState> _qualityListKey = GlobalKey();
  GlobalKey<_VideoTitleViewState> _videoTitleKey = GlobalKey();
  GlobalKey<_SuperPlayerCoverViewState> _coverViewKey = GlobalKey();
  GlobalKey<_SuperPlayerMoreViewState> _moreViewKey = GlobalKey();
  GlobalKey<_SuperPlayerFloatState> floatPlayerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _playController = widget._controller;
    _superPlayerFullUIController = _SuperPlayerFullScreenController(_updateState);
    _titleViewController = _VideoTitleController(_onTapBack, () {
      _moreViewKey.currentState?.toggleShowMoreView();
    });
    _bottomViewController = _BottomViewController(_onTapPlayControl, _onControlFullScreen, _onControlQualityListView);
    _coverViewController = _CoverViewController(_onDoubleTapVideo, _onSingleTapVideo);
    _qualitListViewController = _QualityListViewController((quality) {
      _playController.switchStream(quality);
    });
    _moreViewController = _MoreViewController(
        () => _playController._isOpenHWAcceleration,
        () => _playController.currentPlayRate,
        (value) => _playController.enableHardwareDecode(value),
        (playRate) => _playController.setPlayRate(playRate),
        () => _playController.playerType == SuperPlayerType.VOD);
    _playController.onPlayerNetStatusBroadcast.listen((event) {
      dynamic wd = (event["VIDEO_WIDTH"]);
      dynamic hd = (event["VIDEO_HEIGHT"]);
      if (null != wd && null != hd) {
        double w = wd.toDouble();
        double h = hd.toDouble();
        _calculateSize(w, h);
      }
    });
    // only register listen once
    _pipSubscription =
        SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_EXIT) {
        // exit floatingMode
        if (Platform.isAndroid) {
          Navigator.of(context).pop();
          if (_isPlaying) {
            // pause play when exit PIP, prevent user just close PIP, but not back to app
            _playController.getCurrentController().pause();
          }
        } else if (Platform.isIOS) {
          EasyLoading.dismiss();
        }
        _isFloatingMode = false;
      } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_REQUEST_START) {
        // EVENT_PIP_MODE_ALREADY_ENTER 的状态变化有滞后性，进入PIP之后才会通知，这里需要监听EVENT_PIP_MODE_REQUEST_START,
        // 在即将进入PIP模式下就要开始进行PIP模式的UI准备
        // enter floatingMode
        if (Platform.isAndroid) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return SuperPlayerFloatView(_playController, _aspectRatio, key: floatPlayerKey);
          }));
        } else if (Platform.isIOS) {
          EasyLoading.showToast(StringResource.OPEN_PIP);
        }
        _isFloatingMode = true;
      } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_ENTER) {
        if (Platform.isIOS) {
          EasyLoading.dismiss();
        }
      } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_WILL_EXIT) {
        if (Platform.isIOS) {
          EasyLoading.showToast(StringResource.CLOSE_PIP);
        }
      } else {
        if (Platform.isIOS) {
          EasyLoading.showToast(StringResource.ERROR_PIP);
        }
        _isFloatingMode = false;
        print('$eventCode');
      }
    });
    _volumeSubscription =
        SuperPlayerPlugin.instance.onEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (_isFloatingMode && _isPlaying) {
        if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PAUSE) {
          _onPause();
        } else if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PLAY) {
          _onResume();
        }
      }

      // 画中画模式下，不进行旋转屏幕操作
      if (eventCode == TXVodPlayEvent.EVENT_ORIENTATION_CHANGED && !_isFloatingMode) {
        int orientation = event[TXVodPlayEvent.EXTRA_NAME_ORIENTATION];
        _fullScreenController.switchToOrientation(orientation);
      }
    });
    _registerObserver();
    _initPlayerState();
  }

  void _registerObserver() {
    _playController._observer = _SuperPlayerObserver(() {
      // onNewVideoPlay
      setState(() {
        _isPlaying = false;
        _isShowControlView = false;
        _isShowCover = true;
        _isLoading = true;
      });
      _coverViewKey.currentState?.showCover(_playController.videoModel!);
    }, () {
      // onPlayPrepare
      _isShowCover = true;
      _coverViewKey.currentState?.showCover(_playController.videoModel!);
      _togglePlayUIState(false);
    }, (name) {
      _togglePlayUIState(true);
      if (_isShowControlView) {
        _videoTitleKey.currentState?.updateTitle(name);
      }
    }, () {
      //onPlayPause
      _togglePlayUIState(false);
    }, () {
      // onPlayStop
      showControlView(false);
      _togglePlayUIState(false);
    }, () {
      // onRcvFirstIframe
      _coverViewKey.currentState?.hideCover();
    }, () {
      // onPlayLoading
      if (!_isPlaying) {
        setState(() {
          _isLoading = true;
        });
      }
    }, (current, duration, playableDuration) {
      // onPlayProgress
      _videoBottomKey.currentState?.updateDuration(current, duration, playableDuration);
      floatPlayerKey.currentState?.updateDuration(current, duration);
    }, (position) {
      // onSeek
    }, (success, playerType, quality) {
      // onSwitchStreamStart
    }, (success, playerType, quality) {
      // onSwitchStreamEnd
    }, (code, msg) {
      // onError
      _togglePlayUIState(false);
    }, (playerType) {
      // onPlayerTypeChange
      _videoBottomKey.currentState?.updatePlayerType(playerType);
      _moreViewKey.currentState?.updatePlayerType(playerType);
    }, (controller, url) {
      // onPlayTimeShiftLive
    }, (qualityList, defaultQuality) {
      // onVideoQualityListChange
      _videoBottomKey.currentState?.updateQuality(defaultQuality);
      _qualityListKey.currentState?.updateQuality(qualityList, defaultQuality);
    }, (info, list) {
      // onVideoImageSpriteAndKeyFrameChanged
    }, () {
      // onSysBackPress
      _onControlFullScreen();
    }, () {
      // onDispose
      _playController._observer = null; // close observer
    });
    _fullScreenController.setListener(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return SuperPlayerFullScreenView(_playController, _superPlayerFullUIController);
      }));
      WidgetsBinding.instance.removeObserver(this);
      _playController._updatePlayerUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);
      _videoBottomKey.currentState?.updateUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);
      _videoTitleKey.currentState?.updateUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);

      hideControlView();
    }, () {
      Navigator.of(context).pop();
      _playController._updatePlayerUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      _videoBottomKey.currentState?.updateUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      _videoTitleKey.currentState?.updateUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      hideControlView();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void _initPlayerState() {
    SuperPlayerState superPlayerState = _playController.getPlayerState();
    switch (superPlayerState) {
      case SuperPlayerState.PLAYING:
        _isPlaying = true;
        _isShowCover = false;
        _isLoading = false;
        _coverViewKey.currentState?.hideCover();
        break;
      case SuperPlayerState.END:
      case SuperPlayerState.PAUSE:
        _isPlaying = false;
        _isShowCover = false;
        _isLoading = false;
        _coverViewKey.currentState?.hideCover();
        break;
      case SuperPlayerState.INIT:
      case SuperPlayerState.LOADING:
        _isPlaying = false;
        _isLoading = true;
        break;
    }
  }

  void _updateState() {
    // 刷新observer的绑定
    _registerObserver();
    // 由于pop之后，无法触发任何回调，并且fulscreen的controller调用setState无效，
    // 所以这里向UI线程添加一个任务，这个任务会在回到这个界面之后触发，来保证播放状态正确。
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => setState(() {
          _initPlayerState();
          _resizeVideo();
        }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPlaying && !_isFloatingMode) {
      if (state == AppLifecycleState.resumed) {
        // 页面从后台回来
        // 不更新状态，直接resume
        _playController.getCurrentController().resume();
        // 从后台回来之后，如果手机横竖屏状态发生更改，被改为竖屏，那么这里根据判断切换横屏
        if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE &&
            defaultTargetPlatform == TargetPlatform.iOS) {
          Orientation currentOrientation = MediaQuery.of(context).orientation;
          bool isLandscape = currentOrientation == Orientation.landscape;
          if (!isLandscape) {
            _fullScreenController.forceSwitchOrientation(manualOrientationDirection);
          }
        }
      } else if (state == AppLifecycleState.inactive) {
        // 页面退到后台
        // 不更新状态，直接pause
        _playController.getCurrentController().pause();
      }
    }
  }

  void _calculateSize(double videoWidth, double videoHeight) {
    if ((0 != videoWidth && 0 != videoHeight) && (_videoWidth != videoWidth && _videoHeight != videoHeight)) {
      floatPlayerKey.currentState?._calculateSize(videoWidth, videoHeight);
      _videoWidth = videoWidth;
      _videoHeight = videoHeight;
      _resizeVideo();
      setState(() {});
    }
  }

  void _resizeVideo() {
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    bool isLandscape = currentOrientation == Orientation.landscape;
    Size size = MediaQuery.of(context).size;
    // 当有视频宽高数据的时候，按照 全屏：高度为基准，计算宽度。 非全屏：宽度为基准，计算高度的方式进行宽高计算
    // 当没有视频宽高数据的时候，按照 全屏：等于屏幕宽高。 非全屏：16:9 的方式进行宽高计算
    if (_videoWidth <= 0 || _videoHeight <= 0) {
      if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
        _radioWidth = isLandscape ? size.width : size.height;
        _radioHeight = isLandscape ? size.height : size.width;
        _aspectRatio = _radioWidth / _radioHeight;
      } else {
        _radioWidth = 0;
        _radioHeight = 0;
        _aspectRatio = 16.0 / 9.0;
      }
    } else {
      if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
        double playerHeight = isLandscape ? size.width : size.height;
        // remain height
        double videoRadio = _videoWidth / _videoHeight;
        _radioHeight = playerHeight;
        _radioWidth = playerHeight * videoRadio;

        _aspectRatio = _radioWidth / _radioHeight;
      } else {
        double playerWidth = isLandscape ? size.height : size.width;
        // remain width
        double videoRadio = _videoWidth / _videoHeight;
        _radioWidth = playerWidth;
        _radioHeight = playerWidth / videoRadio;

        _aspectRatio = _radioWidth / _radioHeight;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
          child: Stack(
        children: [
          _getPlayer(),
          _getTitleArea(),
          _getPipEnterView(),
          _getCover(),
          _getBottomView(),
          _getQualityView(),
          _getStartOrResumeBtn(),
          _getQualityListView(),
          _getMoreMenuView(),
          _getLoading(),
        ],
      )),
    );
  }

  Widget _getPipEnterView() {
    return Visibility(
      visible: _isShowControlView &&
          _playController._playerUIStatus == SuperPlayerUIStatus.WINDOW_MODE,
      child: Positioned(
        right: 10,
        top: 0,
        bottom: 0,
        child: Center(
          child: InkWell(
              onTap: _onEnterPipMode,
              child: Container(
                padding: EdgeInsets.all(5), // expand click area
                child: Image(
                  width: 30,
                  height: 30,
                  image: AssetImage("images/ic_pip_play_icon.png"),
                ),
              )),
        ),
      ),
    );
  }

  Widget _getMoreMenuView() {
    return SuperPlayerMoreView(_moreViewController, key: _moreViewKey);
  }

  Widget _getQualityView() {
    return Visibility(
      visible: _isShowQualityView,
      child: ListView.builder(itemBuilder: (BuildContext context, int index) {
        return Container();
      }),
    );
  }

  Widget _getQualityListView() {
    return Visibility(
      visible: _isShowQualityListView,
      child: QualityListView(_qualitListViewController, _playController.currentQualiyList,
          _playController.currentQuality, _qualityListKey),
    );
  }

  Widget _getBottomView() {
    return Visibility(
      visible: _isShowControlView,
      child: VideoBottomView(_playController, _bottomViewController, _videoBottomKey),
    );
  }

  Widget _getLoading() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: Visibility(
            visible: _isLoading,
            child: CircularProgressIndicator(
              color: Colors.grey,
            )),
      ),
    );
  }

  Widget _getStartOrResumeBtn() {
    return Center(
      child: Visibility(
        visible: !_isPlaying && !_isLoading,
        maintainState: false,
        child: InkWell(
          onTap: _onTapPlayControl,
          child: Image(
            width: 40,
            height: 40,
            image: AssetImage("images/superplayer_ic_vod_play_normal.png"),
          ),
        ),
      ),
    );
  }

  Widget _getCover() {
    return SuperPlayerCoverView(_coverViewController, _coverViewKey, _isShowCover ? _playController.videoModel : null);
  }

  Widget _getPlayer() {
    return InkWell(
      onDoubleTap: _onDoubleTapVideo,
      onTap: _onSingleTapVideo,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Center(
        child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: TXPlayerVideo(
                controller: _playController.getCurrentController(), playerStream: _playController.getPlayerStream())),
      ),
    );
  }

  Widget _getTitleArea() {
    return Visibility(
      visible: _isShowControlView,
      child: Positioned(
        top: topBottomOffset,
        left: 0,
        right: 0,
        child: _VideoTitleView(
            _titleViewController,
            _playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE,
            _playController._getPlayName(),
            _videoTitleKey),
      ),
    );
  }

  void _onEnterPipMode() async {
    if (!_isFloatingMode) {
      int result = await _playController.enterPictureInPictureMode(
          backIcon: "images/ic_pip_play_replay.png",
          playIcon: "images/ic_pip_play_normal.png",
          pauseIcon: "images/ic_pip_play_pause.png",
          forwardIcon: "images/ic_pip_play_forward.png");
      String failedStr = "";
      if (result != TXVodPlayEvent.NO_ERROR) {
        if (result == TXVodPlayEvent.ERROR_PIP_LOWER_VERSION) {
          failedStr = "enterPip failed,because android version is too low,Minimum supported version is android 24";
        } else if (result == TXVodPlayEvent.ERROR_PIP_DENIED_PERMISSION) {
          failedStr = "enterPip failed,because PIP feature is disabled or device not support";
        } else if (result == TXVodPlayEvent.ERROR_PIP_ACTIVITY_DESTROYED) {
          failedStr = "enterPip failed,because activity is destroyed";
        } else {
          failedStr = "enterPip failed,unkonw error";
        }
        LogUtils.e(TAG, failedStr);
      }
    }
  }

  void _onSingleTapVideo() {
    if (_isShowControlView) {
      hideControlView();
      _moreViewKey.currentState?.hideShowMoreView();
    } else {
      showControlView(true);
    }
  }

  void _onDoubleTapVideo() {
    _onTapPlayControl();
    showControlView(true);
  }

  void _onTapBack() async {
    if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
      _onControlFullScreen();
    }
    _playController._onBackTap();
  }

  void _onTapPlayControl() {
    setState(() {
      if (_isPlaying) {
        _onPause();
      } else {
        _onResume();
        _isPlaying = true;
      }
      _videoBottomKey.currentState?.updatePlayState(_isPlaying);
    });
  }

  void _onPause() {
    _playController.pause();
    _isPlaying = false;
  }

  void _onResume() {
    SuperPlayerState playerState = _playController.playerState;
    int playAction = _playController._playAction;
    if (playerState == SuperPlayerState.LOADING && playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
      _playController.resume();
    } else if (playerState == SuperPlayerState.INIT) {
      if (playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
        _playController.resume();
      } else if (playAction == SuperPlayerModel.PLAY_ACTION_MANUAL_PLAY) {
        if (null != _playController.videoModel) {
          SuperPlayerModel videoModel = _playController.videoModel as SuperPlayerModel;
          _playController._playWithModelInner(videoModel);
        }
      }
    } else if (playerState == SuperPlayerState.END) {
      //重播
      _playController.reStart();
    } else if (playerState == SuperPlayerState.PAUSE) {
      //继续播放
      _playController.resume();
    }
  }

  void _handleFullScreen(bool toSwitchFullScreen) {
    if (toSwitchFullScreen) {
      _fullScreenController.switchToOrientation(manualOrientationDirection);
    } else {
      _fullScreenController.switchToOrientation(TXVodPlayEvent.ORIENTATION_PORTRAIT_UP);
    }
  }

  void _onControlFullScreen() {
    if (_playController._playerUIStatus != SuperPlayerUIStatus.PIP_MODE) {
      bool toSwitchFullScreen = _playController._playerUIStatus == SuperPlayerUIStatus.WINDOW_MODE;
      _handleFullScreen(toSwitchFullScreen);
    }
  }

  void _onControlQualityListView() {
    if (mounted) {
      setState(() {
        _isShowQualityListView = !_isShowQualityListView;
      });
    }
  }

  void _togglePlayUIState(bool playing) {
    if (mounted) {
      setState(() {
        if (playing) {
          _isLoading = false;
        }
        _isPlaying = playing;
      });
      _videoBottomKey.currentState?.updatePlayState(playing);
    }
  }

  /// 显示控制组件，包括底部进度条控制区域、顶部标题区域
  /// 显示后，controlViewShowTime 毫秒后会自动隐藏
  void showControlView(bool isNeedAutoDisappear) {
    if (_isShowControlView) {
      return;
    }
    setState(() {
      _isShowControlView = true;
    });
    if (_controlViewTimer.isActive) {
      _controlViewTimer.cancel();
    }

    if (isNeedAutoDisappear) {
      _controlViewTimer = new Timer(Duration(milliseconds: _controlViewShowTime), () {
        hideControlView();
      });
    }
  }

  /// 隐藏所有控制组件
  void hideControlView() {
    if (!_isShowControlView || !mounted) {
      return;
    }
    /// 隐藏moreView
    _moreViewKey.currentState?.hideShowMoreView();
    setState(() {
      _isShowQualityListView = false;
      _isShowControlView = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipSubscription?.cancel();
    _volumeSubscription?.cancel();
    super.dispose();
  }
}

class SuperPlayerFullScreenView extends StatefulWidget {
  final SuperPlayerController _playController;
  final _SuperPlayerFullScreenController controller;

  SuperPlayerFullScreenView(this._playController, this.controller, {Key? viewKey}) : super(key: viewKey);

  @override
  State<StatefulWidget> createState() => SuperPlayerFullScreenState();
}

class SuperPlayerFullScreenState extends State<SuperPlayerFullScreenView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: Scaffold(
            body: Container(
                decoration: BoxDecoration(color: Colors.black),
                width: double.infinity,
                child: SuperPlayerView(widget._playController, viewKey: widget.key)),
          )),
      onWillPop: _onFullScreenWillPop,
    );
  }

  Future<bool> _onFullScreenWillPop() async {
    widget._playController.onBackPress();
    return true;
  }

  @override
  void dispose() {
    widget.controller.onExitFullScreen();
    super.dispose();
  }
}

class _SuperPlayerFullScreenController {
  Function onExitFullScreen;

  _SuperPlayerFullScreenController(this.onExitFullScreen);
}

class SuperPlayerFloatView extends StatefulWidget {
  final SuperPlayerController _controller;
  final double initAspectRatio;

  SuperPlayerFloatView(this._controller, this.initAspectRatio, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SuperPlayerFloatState();
}

class _SuperPlayerFloatState extends State<SuperPlayerFloatView> {
  double _videoDuration = 0;
  double _currentDuration = 0;
  double _aspectRatio = 16.0 / 9.0;
  double _videoWidth = 0;
  double _videoHeight = 0;
  StreamSubscription? sizeStreamSubscription;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.initAspectRatio;
  }

  void _calculateSize(double videoWidth, double videoHeight) {
    if ((0 != videoWidth && 0 != videoHeight) && (_videoWidth != videoWidth && _videoHeight != videoHeight)) {
      _videoWidth = videoWidth;
      _videoHeight = videoHeight;

      Size size = MediaQuery.of(context).size;
      double playerHeight = size.height;
      // remain height
      double videoRadio = _videoWidth / _videoHeight;
      double radioHeight = playerHeight;
      double radioWidth = playerHeight * videoRadio;

      _aspectRatio = radioWidth / radioHeight;

      setState(() {});
    }
  }

  void updateDuration(double duration, double videoDuration) {
    if (duration != _currentDuration || _videoDuration != videoDuration) {
      if (duration <= videoDuration) {
        setState(() {
          _currentDuration = duration;
          _videoDuration = videoDuration;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _aspectRatio,
                  child: TXPlayerVideo(
                    controller: widget._controller.getCurrentController(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _getSlider(),
              )
            ],
          )),
    );
  }

  Widget _getSlider() {
    return Theme(
        data: ThemeResource.getMiniSliderTheme(),
        child: Slider(
          min: 0,
          max: _videoDuration,
          value: _currentDuration,
          onChanged: (double value) {
            setState(() {
              _currentDuration = value;
            });
          },
        ));
  }

  @override
  void dispose() {
    super.dispose();
    // 移除的时候，解除对进度事件的订阅
    sizeStreamSubscription?.cancel();
  }
}

class FullScreenController {
  bool _isInFullScreenUI = false;
  int currentOrientation = TXVodPlayEvent.ORIENTATION_PORTRAIT_UP;
  Function? onEnterFullScreenUI;
  Function? onExitFullScreenUI;

  FullScreenController();

  void switchToOrientation(int orientationDirection) {
    if (currentOrientation != orientationDirection) {
      forceSwitchOrientation(orientationDirection);
    }
  }

  void forceSwitchOrientation(int orientationDirection) {
    currentOrientation = orientationDirection;
    if (orientationDirection == TXVodPlayEvent.ORIENTATION_PORTRAIT_UP) {
      exitFullScreen();
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      AutoOrientation.portraitUpMode();
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_LANDSCAPE_RIGHT) {
      enterFullScreen();
      SystemChrome.setPreferredOrientations(Platform.isIOS ? [DeviceOrientation.landscapeRight] : [DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      AutoOrientation.landscapeRightMode();
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_PORTRAIT_DOWN) {
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_LANDSCAPE_LEFT) {
      enterFullScreen();
      SystemChrome.setPreferredOrientations(Platform.isIOS ? [DeviceOrientation.landscapeLeft] : [DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      AutoOrientation.landscapeLeftMode();
    }
  }

  void enterFullScreen() {
    if (!_isInFullScreenUI) {
      _isInFullScreenUI = true;
      onEnterFullScreenUI?.call();
    }
  }

  void exitFullScreen() {
    if (_isInFullScreenUI) {
      _isInFullScreenUI = false;
      onExitFullScreenUI?.call();
    }
  }

  void setListener(Function enterfullScreen, Function exitFullScreen) {
    this.onExitFullScreenUI = exitFullScreen;
    this.onEnterFullScreenUI = enterfullScreen;
  }
}
