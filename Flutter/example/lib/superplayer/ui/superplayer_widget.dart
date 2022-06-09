part of demo_super_player_lib;

final double topBottomOffset = 0;
DeviceOrientation landscapeOrientation = DeviceOrientation.landscapeLeft;

/// superplayer view widget
class SuperPlayerView extends StatefulWidget {
  final SuperPlayerController _controller;

  SuperPlayerView(this._controller, {Key? viewKey}) : super(key: viewKey);

  @override
  State<StatefulWidget> createState() => SuperPlayerViewState();
}

class SuperPlayerViewState extends State<SuperPlayerView> with WidgetsBindingObserver {
  static final int _controlViewShowTime = 7000;

  late SuperPlayerController _playController;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isShowCover = true;

  double _radioWidth = 0;
  double _radioHeight = 0;
  double _topAndBottomMargin = 0;
  double _leftAndRightMargin = 0;
  double _aspectRatio = 16.0 / 9.0;
  double _videoWidth = 0;
  double _videoHeight = 0;

  bool _isShowControlView = false;
  bool _isShowQualityView = false;
  bool _isShowQualityListView = false;

  late _BottomViewController _bottomViewController;
  late _QualityListViewController _qualitListViewController;
  late _VideoTitleController _titleViewController;
  late _SuperPlayerFullScreenController _fullScreenController;
  late _CoverViewController _coverViewController;

  /// init
  Timer _controlViewTimer = Timer(Duration(milliseconds: _controlViewShowTime), () {});

  GlobalKey<_VideoBottomViewState> _videoBottomKey = GlobalKey();
  GlobalKey<_QualityListViewState> _qualityListKey = GlobalKey();
  GlobalKey<_VideoTitleViewState> _videoTitleKey = GlobalKey();
  GlobalKey<_SuperPlayerCoverViewState> _coverViewKey = GlobalKey();
  GlobalKey<TXPlayerVideoState> _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // ios need landscapeRight,android need landscapeLeft
    if(defaultTargetPlatform == TargetPlatform.iOS) {
      landscapeOrientation = DeviceOrientation.landscapeRight;
    } else {
      landscapeOrientation = DeviceOrientation.landscapeLeft;
    }
    _playController = widget._controller;
    WidgetsBinding.instance?.addObserver(this);
    _fullScreenController = _SuperPlayerFullScreenController(_updateState);
    _titleViewController = _VideoTitleController(_onTapBack);
    _bottomViewController = _BottomViewController(_onTapPlayControl, _onControlFullScreen, _onControlQualityListView);
    _coverViewController = _CoverViewController(_onDoubleTapVideo, _onSingleTapVideo);
    _qualitListViewController = _QualityListViewController((quality) {
      _playController.switchStream(quality);
    });
    _playController.onPlayerNetStatusBroadcast.listen((event) {
      dynamic wd = (event["VIDEO_WIDTH"]);
      dynamic hd = (event["VIDEO_HEIGHT"]);
      if (null != wd && null != hd) {
        double w = wd.toDouble();
        double h = hd.toDouble();
        _calculateSize(w, h);
      }
    });
    _registerObserver();
    _initPlayerState();
  }

  void _registerObserver() {
    _playController._observer = _SuperPlayerObserver(() {
      // onNewVideoPlay
      _isFullScreen = false;
      _isPlaying = false;
      _isShowControlView = false;
      _isShowCover = true;
      _isLoading = true;
    }, () {
      // onPlayPrepare
      _isShowCover = true;
      _coverViewKey.currentState?.showCover(_playController.videoModel!);
      _togglePlayStateView(false);
    }, (name) {
      _togglePlayStateView(true);
      if (_isShowControlView) {
        _videoTitleKey.currentState?.updateTitle(name);
      }
    }, () {
      //onPlayPause
      _togglePlayStateView(false);
    }, () {
      // onPlayStop
      showControlView(false);
      _togglePlayStateView(false);
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
    }, (current, duration) {
      // onPlayProgress
      _videoBottomKey.currentState?.updateDuration(current, duration);
    }, (position) {
      // onSeek
    }, (success, playerType, quality) {
      // onSwitchStreamStart
    }, (success, playerType, quality) {
      // onSwitchStreamEnd
    }, (code, msg) {
      // onError
      _togglePlayStateView(false);
    }, (playerType) {
      // onPlayerTypeChange
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
      if (_isFullScreen) {
        _onControlFullScreen();
      }
    }, () {
      // onDispose
      _playController._observer = null; // close observer
    });
  }

  void _initPlayerState() {
    _isFullScreen = _playController._isFullScreen;
    SuperPlayerState superPlayerState = _playController.getPlayerState();
    switch (superPlayerState) {
      case SuperPlayerState.PLAYING:
        _isPlaying = true;
        _isShowCover = false;
        _isLoading = false;
        break;
      case SuperPlayerState.END:
      case SuperPlayerState.PAUSE:
        _isPlaying = false;
        _isShowCover = false;
        _isLoading = false;
        break;
      case SuperPlayerState.INIT:
      case SuperPlayerState.LOADING:
        _isPlaying = false;
        _isLoading = true;
        break;
    }
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([landscapeOrientation]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _updateState() {
    // 刷新observer的绑定
    _registerObserver();
    // 由于pop之后，无法触发任何回调，并且fulscreen的controller调用setState无效，
    // 所以这里向UI线程添加一个任务，这个任务会在回到这个界面之后触发，来保证播放状态正确。
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => setState(() {
          _initPlayerState();
          _resizeVideo();
        }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPlaying) {
      if (state == AppLifecycleState.resumed) {
        // 页面从后台回来
        // 不更新状态，直接resume
        _playController._vodPlayerController?.resume();
        // 从后台回来之后，如果手机横竖屏状态发生更改，被改为竖屏，那么这里根据判断切换横屏
        if (_isFullScreen && defaultTargetPlatform == TargetPlatform.iOS) {
          Orientation currentOrientation = MediaQuery.of(context).orientation;
          bool isLandscape = currentOrientation == Orientation.landscape;
          if (!isLandscape) {
            ///关闭状态栏，与RootViewController底部虚拟操作按钮
            SystemChrome.setPreferredOrientations([landscapeOrientation]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            AutoOrientation.landscapeAutoMode();
          }
        }
      } else if (state == AppLifecycleState.inactive) {
        // 页面退到后台
        // 不更新状态，直接pause
        _playController._vodPlayerController?.pause();
      }
    }
  }

  void _calculateSize(double videoWidth, double videoHeight) {
    if ((0 != videoWidth && 0 != videoHeight) && (_videoWidth != videoWidth && _videoHeight != videoHeight)) {
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
    if (_isFullScreen) {
      _radioWidth = isLandscape ? size.width : size.height;
      _radioHeight = isLandscape ? size.height : size.width;
      _aspectRatio = _radioWidth / _radioHeight;
    } else {
      double playerWidth = isLandscape ? size.height : size.width;
      if (_videoWidth <= 0 || _videoHeight <= 0) {
        _radioWidth = 0;
        _radioHeight = 0;
        _aspectRatio = 16.0 / 9.0;
      } else {
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
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _getPlayer(),
            _getTitleArea(),
            _getCover(),
            _getBottomView(),
            _getQualityView(),
            _getStartOrResumeBtn(),
            _getQualityListView(),
            _getLoading(),
          ],
        ),
      ),
    );
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
      child: TXPlayerVideo(controller: _playController._vodPlayerController!, key: _playerKey),
    );
  }

  Widget _getTitleArea() {
    return Visibility(
      visible: _isShowControlView,
      child: Positioned(
        top: topBottomOffset,
        left: 0,
        right: 0,
        child: _VideoTitleView(_titleViewController, _playController._getPlayName(), _videoTitleKey),
      ),
    );
  }

  void _onSingleTapVideo() {
    if (_isShowControlView) {
      hideControlView();
    } else {
      showControlView(true);
    }
  }

  void _onDoubleTapVideo() {
    _onTapPlayControl();
    showControlView(true);
  }

  void _onTapBack() {
    if (_isFullScreen) {
      _onControlFullScreen();
    }
    _playController._onBackTap();
  }

  void _onTapPlayControl() {
    setState(() {
      if (_isPlaying) {
        _playController.pause();
        _isPlaying = false;
      } else {
        _onResume();
        _isPlaying = true;
      }
      _videoBottomKey.currentState?.updatePlayState(_isPlaying);
    });
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

  void _fullScreenOrientation() {
    if (_isFullScreen) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return SuperPlayerFullScreenView(_playController, _fullScreenController);
      }));
    } else {
      // exit fullscreen widget
      Navigator.of(context).pop();

      ///显示状态栏，与底部虚拟操作按钮
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      AutoOrientation.portraitAutoMode();
    }
    _videoBottomKey.currentState?.updateFullScreen(_isFullScreen);
  }

  void _onControlFullScreen() {
    _isFullScreen = !_isFullScreen;
    if (_isFullScreen) {
      hideControlView();
      _fullScreenOrientation();
    } else {
      hideControlView();
      _fullScreenOrientation();
    }
    _playController._updateFullScreenState(_isFullScreen);
  }

  void _onControlQualityListView() {
    if (mounted) {
      setState(() {
        _isShowQualityListView = !_isShowQualityListView;
      });
    }
  }

  void _togglePlayStateView(bool playing) {
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
    setState(() {
      _isShowQualityListView = false;
      _isShowControlView = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
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

    ///关闭状态栏，与底部虚拟操作按钮
    SystemChrome.setPreferredOrientations([landscapeOrientation]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    AutoOrientation.landscapeAutoMode();
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
            body:
                Container(width: double.infinity, child: SuperPlayerView(widget._playController, viewKey: widget.key)),
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

