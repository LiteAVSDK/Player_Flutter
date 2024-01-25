// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

const topBottomOffset = 0.0;
int manualOrientationDirection = TXVodPlayEvent.ORIENTATION_LANDSCAPE_RIGHT;
FullScreenController _fullScreenController = FullScreenController();

/// superPlayer view widget
class SuperPlayerView extends StatefulWidget {
  final SuperPlayerController _controller;
  final SuperPlayerRenderMode renderMode;

  SuperPlayerView(this._controller, {Key? viewKey, this.renderMode = SuperPlayerRenderMode.ADJUST_RESOLUTION}) : super(key: viewKey);

  @override
  State<StatefulWidget> createState() => SuperPlayerViewState();
}

class SuperPlayerViewState extends State<SuperPlayerView> with WidgetsBindingObserver {
  static const _controlViewShowTime = 7000;
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
  bool _isShowQualityListView = false;
  bool _isShowDownload = false;
  bool _isDownloaded = false;

  late BottomViewController _bottomViewController;
  late QualityListViewController _qualitListViewController;
  late _VideoTitleController _titleViewController;
  late SuperPlayerFullScreenController _superPlayerFullUIController;
  late CoverViewController _coverViewController;
  late MoreViewController _moreViewController;

  StreamSubscription? _volumeSubscription;
  StreamSubscription? _pipSubscription;
  FTXDownloadListener? downloadListener;

  /// init
  Timer _controlViewTimer = Timer(const Duration(milliseconds: _controlViewShowTime), () {});

  final GlobalKey<_VideoBottomViewState> _videoBottomKey = GlobalKey();
  final GlobalKey<_QualityListViewState> _qualityListKey = GlobalKey();
  final GlobalKey<_VideoTitleViewState> _videoTitleKey = GlobalKey();
  final GlobalKey<_SuperPlayerCoverViewState> _coverViewKey = GlobalKey();
  final GlobalKey<_SuperPlayerMoreViewState> _moreViewKey = GlobalKey();

  Uint8List? _currentSprite;
  bool _isShowSprite = false;
  int _pipPreUiStatus = SuperPlayerUIStatus.WINDOW_MODE;

  // Task queue
  final TaskExecutors _taskExecutors = TaskExecutors();

  @override
  void initState() {
    super.initState();
    TXPipController.instance.exitAndReleaseCurrentPip();
    _playController = widget._controller;
    _superPlayerFullUIController = SuperPlayerFullScreenController(_updateState);
    _titleViewController = _VideoTitleController(
        _onTapBack,
        // onTapMore
        () => _moreViewKey.currentState?.toggleShowMoreView(),
        // onTapDownload
        () {
      if (_playController.videoModel != null) {
        _playController.startDownload();
        EasyLoading.showToast(FSPLocal.current.txSpwStartDownload);
      }
    });
    _bottomViewController = BottomViewController(_onTapPlayControl, _onControlFullScreen, _onControlQualityListView, (value) {
      _taskExecutors.addTask(() => _controlTest(true, value));
    }, () {
      _taskExecutors.addTask(() => _controlTest(false, 0));
    });
    _coverViewController = CoverViewController(_onDoubleTapVideo, _onSingleTapVideo);
    _qualitListViewController = QualityListViewController((quality) {
      _playController.switchStream(quality);
      hideControlView();
    });
    _moreViewController = MoreViewController(
        () => _playController._isOpenHWAcceleration,
        () => _playController.currentPlayRate,
        (value) => _playController.enableHardwareDecode(value),
        (playRate) => _playController.setPlayRate(playRate),
        () => _playController.playerType == SuperPlayerType.VOD);

    _playController.onPlayerNetStatusBroadcast.listen((event) {
      // do nothing
    });
    // only register listen once
    _pipSubscription = SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_EXIT) {
        _isFloatingMode = false;
        _playController._updatePlayerUIStatus(_pipPreUiStatus);
      } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_REQUEST_START) {
        _pipPreUiStatus = _playController._playerUIStatus;
        _isFloatingMode = true;
        _playController._updatePlayerUIStatus(SuperPlayerUIStatus.PIP_MODE);
      } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_WILL_EXIT) {
        EasyLoading.showToast(FSPLocal.current.txSpwClosingPip);
      } else if (eventCode < 0) {
        EasyLoading.showToast(FSPLocal.current.txSpwOpenPipFailed);
        _isFloatingMode = false;
        _playController._updatePlayerUIStatus(_pipPreUiStatus);
      }
    });
    _volumeSubscription = SuperPlayerPlugin.instance.onEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (_isFloatingMode && _isPlaying) {
        if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PAUSE) {
          _onPause();
        } else if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PLAY) {
          _onResume();
        }
      }

      // Do not rotate the screen in picture-in-picture mode.
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
      // preparePlayVideo
      setState(() {
        _currentSprite = null;
        _isShowSprite = false;
        _isShowControlView = false;
        _isLoading = _playController.videoModel!.playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
      });
      _coverViewKey.currentState?.showCover(_playController.videoModel!);
    }, () {
      // onPlayPrepare
      _isShowCover = true;
      _isLoading = false;
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
      if (mounted) {
        showControlView(false);
        _togglePlayUIState(false);
      }
    }, () {
      // onRcvFirstIframe
      _coverViewKey.currentState?.hideCover();
      _refreshDownloadStatus();
    }, () {
      // onPlayLoading
      setState(() {
        // Special handling in preloading mode.
        if (_playController.videoModel!.playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
          if (_playController.callResume) {
            _isLoading = true;
          }
        } else {
          _isLoading = true;
        }
      });
    }, (current, duration, playableDuration) {
      // onPlayProgress
      _videoBottomKey.currentState?.updateDuration(current, duration, playableDuration);
    }, (position) {
      // onSeek
    }, (success, playerType, quality) {
      // onSwitchStreamStart
    }, (success, playerType, quality) {
      // onSwitchStreamEnd
    }, (code, msg) {
      // onError
      _togglePlayUIState(false);
      EasyLoading.showToast(FSPLocal.current.txSpwErrPlayTo.txFormat(["$code", msg]));
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
      _videoBottomKey.currentState?.setKeyFrame(list);
    }, () {
      // onResolutionChanged
      _calculateSize(_playController.videoWidth, _playController.videoHeight);
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
      if (null != downloadListener) {
        DownloadHelper.instance.removeDownloadListener(downloadListener!);
      }
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
    _initDownloadStatus();
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
      case SuperPlayerState.LOADING:
        _isPlaying = false;
        _isShowCover = false;
        _isLoading = true;
        _coverViewKey.currentState?.hideCover();
        break;
      case SuperPlayerState.INIT:
        _isPlaying = false;
        _isLoading = false;
        break;
    }
  }

  void _initDownloadStatus() {
    if (null != downloadListener) {
      DownloadHelper.instance.removeDownloadListener(downloadListener!);
    }
    DownloadHelper.instance.addDownloadListener(downloadListener = FTXDownloadListener((event, info) {
      if (event == TXVodPlayEvent.EVENT_DOWNLOAD_FINISH) {
        EasyLoading.showToast(FSPLocal.current.txSpwDownloadComplete);
      }
      _refreshDownloadStatus();
    }, (errorCode, errorMsg, info) {
      EasyLoading.showToast(FSPLocal.current.txSpwDownloadErrorTo.txFormat(["$errorCode", errorMsg]));
    }));
    if (null != _playController.videoModel) {
      // Only VOD video download is supported.
      _isShowDownload = _playController.videoModel!.isEnableDownload && _playController.playerType == SuperPlayerType.VOD;
    }
    _refreshDownloadStatus();
  }

  void _updateState() {
    // Refresh the binding of the observer.
    _registerObserver();
    // Because no callbacks can be triggered after `pop`, and calling `setState` on the fullscreen controller is invalid,
    // a task is added to the UI thread here. This task will be triggered after returning to this interface to
    // ensure that the playback status is correct.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => setState(() {
          _initPlayerState();
          _resizeVideo();
        }));
  }

  void _refreshDownloadStatus() async {
    _isDownloaded = await _playController.isDownloaded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPlaying && !_isFloatingMode) {
      if (state == AppLifecycleState.resumed) {
        // The page does not update the status when it returns from the background, and directly resumes.
        _playController.getCurrentController().resume();
        checkBrightness();
        // If the screen orientation is changed from landscape to portrait after returning from the background,
        // switch to landscape mode based on the judgment made here.
        if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE && defaultTargetPlatform == TargetPlatform.iOS) {
          Orientation currentOrientation = MediaQuery.of(context).orientation;
          bool isLandscape = currentOrientation == Orientation.landscape;
          if (!isLandscape) {
            _fullScreenController.forceSwitchOrientation(manualOrientationDirection);
          }
        }
      } else if (state == AppLifecycleState.inactive) {
        // The page does not update its status when it is pushed to the background, it goes directly to pause
        _playController.getCurrentController().pause();
      }
    }
  }

  void checkBrightness() async {
    double? sysBrightness = await SuperPlayerPlugin.getSysBrightness();
    double? windowBrightness = await SuperPlayerPlugin.getBrightness();
    if (sysBrightness != windowBrightness && null != sysBrightness) {
      SuperPlayerPlugin.setBrightness(sysBrightness);
    }
  }

  void _calculateSize(double videoWidth, double videoHeight) {
    if (mounted && (0 != videoWidth && 0 != videoHeight) && (_videoWidth != videoWidth || _videoHeight != videoHeight)) {
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
    // When video width and height data are available, the width and height should be calculated based on the height for full-screen mode
    // and based on the width for non-full-screen mode.
    // When video width and height data are not available, the width and height should be set equal to the screen width
    // and height for full-screen mode, and a 16:9 aspect ratio should be used for calculating width and height in non-full-screen mode.
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
    return Center(
        child: widget.renderMode == SuperPlayerRenderMode.ADJUST_RESOLUTION ?
        IntrinsicHeight(
                child: _getWidgetBody(),
              )
            : _getWidgetBody()
    );
  }

  Widget _getWidgetBody() {
    return Stack(
      children: [
        _getPlayer(),
        _getTitleArea(),
        _getPipEnterView(),
        _getImageSpriteView(),
        _getCover(),
        _getBottomView(),
        _getStartOrResumeBtn(),
        _getQualityListView(),
        _getMoreMenuView(),
        _getLoading(),
      ],
    );
  }

  Widget _getImageSpriteView() {
    return Visibility(
      visible: _isShowSprite,
      child: Center(
        child: null != _currentSprite ? Image.memory(_currentSprite!) : Container(),
      ),
    );
  }

  Widget _getPipEnterView() {
    return Visibility(
      visible: _isShowControlView &&
          _playController._playerUIStatus == SuperPlayerUIStatus.WINDOW_MODE &&
          _playController.playerType == SuperPlayerType.VOD,
      child: Positioned(
        right: 10,
        top: 0,
        bottom: 0,
        child: Center(
          child: InkWell(
              onTap: _onEnterPipMode,
              child: Container(
                padding: const EdgeInsets.all(5), // expand click area
                child: const Image(
                  width: 30,
                  height: 30,
                  image: AssetImage("images/ic_pip_play_icon.png", package: PlayerConstants.PKG_NAME),
                ),
              )),
        ),
      ),
    );
  }

  Widget _getMoreMenuView() {
    return SuperPlayerMoreView(_moreViewController, key: _moreViewKey);
  }

  Widget _getQualityListView() {
    return Visibility(
      visible: _isShowQualityListView,
      child:
          QualityListView(_qualitListViewController, _playController.currentQualityList, _playController.currentQuality, _qualityListKey),
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
            child: const CircularProgressIndicator(
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
          child: const Image(
            width: 40,
            height: 40,
            image: AssetImage("images/superplayer_ic_vod_play_normal.png", package: PlayerConstants.PKG_NAME),
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
        child:  widget.renderMode == SuperPlayerRenderMode.ADJUST_RESOLUTION ?
        AspectRatio(
            aspectRatio: _aspectRatio,
            child: TXPlayerVideo(controller: _playController.getCurrentController(), playerStream: _playController.getPlayerStream()))
        : SizedBox(
          child: TXPlayerVideo(
              controller: _playController.getCurrentController(), playerStream: _playController.getPlayerStream()),
        )
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
        child: _VideoTitleView(_titleViewController, _playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE,
            _playController._getPlayName(), _isShowDownload, _isDownloaded, _videoTitleKey),
      ),
    );
  }

  void _onEnterPipMode() async {
    if (!_isFloatingMode) {
      int result = await _playController.enterPictureInPictureMode(
          backIcon: "packages/${PlayerConstants.PKG_NAME}/images/ic_pip_play_replay.png",
          playIcon: "packages/${PlayerConstants.PKG_NAME}/images/ic_pip_play_normal.png",
          pauseIcon: "packages/${PlayerConstants.PKG_NAME}/images/ic_pip_play_pause.png",
          forwardIcon: "packages/${PlayerConstants.PKG_NAME}/images/ic_pip_play_forward.png");
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
    int playAction = _playController.videoModel!.playAction;
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
      // restart
      _playController.reStart();
    } else if (playerState == SuperPlayerState.PAUSE) {
      // resume play
      _playController.resume();
      _isShowCover = false;
      _coverViewKey.currentState?.hideCover();
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

  /// Display control components consist of a bottom progress bar control area and a top title area.
  /// After being displayed, the control view will automatically hide after controlViewShowTime milliseconds.
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
      _startHideRunnable();
    }
  }

  void _startHideRunnable() {
    if (_controlViewTimer.isActive) {
      _controlViewTimer.cancel();
    }
    _controlViewTimer = Timer(const Duration(milliseconds: _controlViewShowTime), () {
      hideControlView();
    });
  }

  /// Hide all control components.
  /// 隐藏所有控制组件
  void hideControlView() {
    if (!_isShowControlView || !mounted) {
      return;
    }

    if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    // Hide moreView
    _moreViewKey.currentState?.hideShowMoreView();
    setState(() {
      _isShowQualityListView = false;
      _isShowControlView = false;
    });
  }

  /// Control the display of the sprite image.
  /// 控制雪碧图显示
  Future _controlTest(bool isShow, double value) async {
    if (isShow) {
      Uint8List? tmp = await _playController._vodPlayerController.getImageSprite(value);
      if (!Utils.compareBuffer(_currentSprite, tmp)) {
        setState(() {
          _currentSprite = tmp;
          _isShowSprite = true;
        });
      }
      _controlViewTimer.cancel();
    } else {
      _startHideRunnable();
      setState(() {
        _currentSprite = null;
        _isShowSprite = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipSubscription?.cancel();
    _volumeSubscription?.cancel();
    if (null != downloadListener) {
      DownloadHelper.instance.removeDownloadListener(downloadListener!);
    }
    super.dispose();
  }
}

class SuperPlayerFullScreenView extends StatefulWidget {
  final SuperPlayerController _playController;
  final SuperPlayerFullScreenController controller;

  const SuperPlayerFullScreenView(this._playController, this.controller, {Key? viewKey}) : super(key: viewKey);

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
        onWillPop: _onFullScreenWillPop,
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: Scaffold(
              body: Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  width: double.infinity,
                  child: SuperPlayerView(widget._playController, viewKey: widget.key)),
            )));
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

class SuperPlayerFullScreenController {
  Function onExitFullScreen;

  SuperPlayerFullScreenController(this.onExitFullScreen);
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
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_LANDSCAPE_RIGHT) {
      SystemChrome.setPreferredOrientations(Platform.isIOS ? [DeviceOrientation.landscapeRight] : [DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      enterFullScreen();
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_PORTRAIT_DOWN) {
    } else if (orientationDirection == TXVodPlayEvent.ORIENTATION_LANDSCAPE_LEFT) {
      SystemChrome.setPreferredOrientations(Platform.isIOS ? [DeviceOrientation.landscapeLeft] : [DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      enterFullScreen();
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

  void setListener(Function enterFullScreen, Function exitFullScreen) {
    onExitFullScreenUI = exitFullScreen;
    onEnterFullScreenUI = enterFullScreen;
  }
}
