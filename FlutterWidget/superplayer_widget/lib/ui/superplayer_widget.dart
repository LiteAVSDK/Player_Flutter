// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

const topBottomOffset = 0.0;
int manualOrientationDirection = TXVodPlayEvent.ORIENTATION_LANDSCAPE_RIGHT;

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
  int _currentUIStatus = SuperPlayerUIStatus.WINDOW_MODE;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isShowCover = true;

  bool _isShowControlView = false;
  bool _isShowQualityListView = false;
  bool _isShowDownload = false;
  bool _isDownloaded = false;
  bool _isShowSubtitleListView = false;
  bool _isShowAudioListView = false;

  late BottomViewController _bottomViewController;
  late QualityListViewController _qualitListViewController;
  late _VideoTitleController _titleViewController;
  late CoverViewController _coverViewController;
  late MoreViewController _moreViewController;
  late AudioTrackController _audioTrackController;
  late SubtitleTrackController _subtitleTrackController;
  Completer<int> _playerViewIdCompleter = Completer();

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
  final GlobalKey<AudioListState> _audioListViewKey = GlobalKey();
  final GlobalKey<_SubtitleListState> _subtitleListViewKey = GlobalKey();
  final GlobalKey<TXPlayerVideoState> _videoKey = GlobalKey();

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
    _currentUIStatus = _playController._playerUIStatus;
    _applyRenderMode();
    _titleViewController = _VideoTitleController(
        // onTapBack
        _onTapBack,
        // onTapMore
        () => _moreViewKey.currentState?.toggleShowMoreView(),
        // onTapDownload
        () {
      if (_playController.videoModel != null) {
        _playController.startDownload();
        EasyLoading.showToast(FSPLocal.current.txSpwStartDownload);
      }
    }, () {
      // _onTapSubtitle
      setState(() {
        _isShowSubtitleListView = true;
      });
      _cancelHideRunnable();
    }, () {
      // _onTapAudio
      setState(() {
        _isShowAudioListView = true;
      });
      _cancelHideRunnable();
    });
    _bottomViewController = BottomViewController(_onTapPlayControl, _onControlFullScreen, _onControlQualityListView, (value) {
      _taskExecutors.addTask(() => _controlTest(true, value));
    }, () {
      _taskExecutors.addTask(() => _controlTest(false, 0));
    });
    _coverViewController = CoverViewController(_onDoubleTapVideo, _onSingleTapVideo);
    _qualitListViewController = QualityListViewController((quality)  {
      _playController.switchStream(quality);
      hideControlView();
    });
    _audioTrackController = AudioTrackController((trackInfo) {
      _playController.onSelectAudioTrack(trackInfo);
    });
    _subtitleTrackController = SubtitleTrackController((trackInfo) {
      _playController.onSelectSubtitleTrack(trackInfo);
    }, (subtitleRenderModel) {
      _playController.onSubtitleRenderModelChange(subtitleRenderModel);
    });
    _moreViewController = MoreViewController(
        () => _playController._isOpenHWAcceleration,
        () => _playController.currentPlayRate,
        (value) => _playController.enableHardwareDecode(value),
        (playRate) => _playController.setPlayRate(playRate),
        () => _playController.playerType == SuperPlayerType.VOD);

    // only register listen once
    _pipSubscription =
        SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_EXIT
        || eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_RESTORE_UI) {
        _playController._updatePlayerUIStatus(_pipPreUiStatus);
        _currentUIStatus = _pipPreUiStatus;
      } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_REQUEST_START) {
        _pipPreUiStatus = _playController._playerUIStatus;
        _currentUIStatus = SuperPlayerUIStatus.PIP_MODE;
        _playController._updatePlayerUIStatus(SuperPlayerUIStatus.PIP_MODE);
      } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_WILL_EXIT) {
        EasyLoading.showToast(FSPLocal.current.txSpwClosingPip);
      } else if (eventCode < 0) {
        EasyLoading.showToast(FSPLocal.current.txSpwOpenPipFailed);
        _currentUIStatus = _pipPreUiStatus;
        _playController._updatePlayerUIStatus(_pipPreUiStatus);
      }
    });
    _volumeSubscription =
        SuperPlayerPlugin.instance.onEventBroadcast.listen((event) {
      int eventCode = event["event"];
      if (_currentUIStatus ==  SuperPlayerUIStatus.PIP_MODE && _isPlaying) {
        if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PAUSE) {
          _onPause();
        } else if (eventCode == TXVodPlayEvent.EVENT_AUDIO_FOCUS_PLAY) {
          _onResume();
        }
      }
      // Do not rotate the screen in picture-in-picture mode.
      else if (eventCode == TXVodPlayEvent.EVENT_ORIENTATION_CHANGED && _currentUIStatus != SuperPlayerUIStatus.PIP_MODE) {
        int orientation = event[TXVodPlayEvent.EXTRA_NAME_ORIENTATION];
        _playController.fullScreenController.switchToOrientation(orientation);
      }
    });
    _registerObserver();
    _initPlayerState();
    connectPlayerView();
  }

  @override
  void didUpdateWidget(covariant SuperPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_playController != oldWidget) {
      _playController = widget._controller;
      _applyRenderMode();
    } else if (widget.renderMode != oldWidget.renderMode) {
      _applyRenderMode();
    }
  }

  void _applyRenderMode() {
    if (widget.renderMode == SuperPlayerRenderMode.FILL_VIEW) {
      _playController._vodPlayerController.setRenderMode(FTXPlayerRenderMode.FULL_FILL_CONTAINER);
      _playController._livePlayerController.setRenderMode(FTXPlayerRenderMode.FULL_FILL_CONTAINER);
    } else if (widget.renderMode == SuperPlayerRenderMode.ADJUST_RESOLUTION) {
      _playController._vodPlayerController.setRenderMode(FTXPlayerRenderMode.ADJUST_RESOLUTION);
      _playController._livePlayerController.setRenderMode(FTXPlayerRenderMode.ADJUST_RESOLUTION);
    }
  }

  void _registerObserver() async {
    _playController._observer = _SuperPlayerObserver(() {
      // preparePlayVideo
      setState(() {
        _currentSprite = null;
        _isShowSprite = false;
        _isShowControlView = false;
        _isLoading = _playController.videoModel!.playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
        if (null != _playController.videoModel) {
          // Only VOD video download is supported.
          _isShowDownload = _playController.videoModel!.isEnableDownload && _playController.playerType == SuperPlayerType.VOD;
        }
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
      // _calculateSize(_playController.videoWidth, _playController.videoHeight);
    }, () {
      // onSysBackPress
      _onControlFullScreen();
    }, (audioTrackList, selectedTrack) {
      // onAudioTrackListChange
      setState(() {
        _audioListViewKey.currentState?.updateAudioTrack(audioTrackList, selectedTrack);
      });
    }, (subtitleTrackList, selectedTrack) {
      // onSubtitleTrackListChange
      setState(() {
        _subtitleListViewKey.currentState?.updateSubtitleTrack(subtitleTrackList, selectedTrack);
      });
    }, (subtitleData) {
      // onSubtitleData
      setState(() {
        _playController.currentSubtitleData = subtitleData;
      });
    }, () {
      // onDispose
      _playController._observer = null; // close observer
    });
    _playController.fullScreenController.setListener(() async {
      // enter full screen
      _playController._updatePlayerUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);
      _videoBottomKey.currentState?.updateUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);
      _videoTitleKey.currentState?.updateUIStatus(SuperPlayerUIStatus.FULLSCREEN_MODE);
      hideControlView();
      setState(() {
        _currentUIStatus = SuperPlayerUIStatus.FULLSCREEN_MODE;
      });
      if (_playController.playerType != SuperPlayerType.VOD) {
        Future.delayed(Duration(milliseconds: 180), () async {
          // reset render mode for live
          await _playController.setPlayerView(-1);
          await connectPlayerView();
        });
      }
    }, () async {
      _playController._updatePlayerUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      _videoBottomKey.currentState?.updateUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      _videoTitleKey.currentState?.updateUIStatus(SuperPlayerUIStatus.WINDOW_MODE);
      hideControlView();
      // exit full screen
      setState(() {
        _currentUIStatus = SuperPlayerUIStatus.WINDOW_MODE;
      });
      if (_playController.playerType != SuperPlayerType.VOD) {
        Future.delayed(Duration(milliseconds: 180), () async {
          // reset render mode for live
          await _playController.setPlayerView(-1);
          await connectPlayerView();
        });
      }
    });
    WidgetsBinding.instance.removeObserver(this);
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
      case SuperPlayerState.START:
        _isPlaying = false;
        _isShowCover = true;
        _isLoading = true;
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

  Future<void> connectPlayerView() async {
    int viewId = await _playerViewIdCompleter.future;
    _playController.setPlayerView(viewId);
  }

  void _onPlayerViewCreated(int viewId) {
    if (_playerViewIdCompleter.isCompleted) {
      _playerViewIdCompleter = Completer();
      _playerViewIdCompleter.complete(viewId);
      connectPlayerView();
    } else {
      _playerViewIdCompleter.complete(viewId);
    }
  }

  void _refreshDownloadStatus() async {
    _isDownloaded = await _playController.isDownloaded();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPlaying && _currentUIStatus != SuperPlayerUIStatus.PIP_MODE) {
      if (state == AppLifecycleState.resumed) {
        // The page does not update the status when it returns from the background, and directly resumes.
        _playController.getCurrentController().resume();
        checkBrightness();
        // If the screen orientation is changed from landscape to portrait after returning from the background,
        // switch to landscape mode based on the judgment made here.
        if (_playController._playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE
            && defaultTargetPlatform == TargetPlatform.iOS) {
          Orientation currentOrientation = MediaQuery.of(context).orientation;
          bool isLandscape = currentOrientation == Orientation.landscape;
          if (!isLandscape) {
            _playController.fullScreenController.forceSwitchOrientation(manualOrientationDirection);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(left: false, right: false, top: false, bottom: false, minimum: EdgeInsets.zero,
          child: _getNoPaddingBody(context)),
    );
  }

  Widget _getNoPaddingBody(BuildContext context) {
    bool isFullMode = _currentUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE;
    final Size screenSize = MediaQuery.of(context).size;
    return OverflowBox(
      alignment: Alignment.topCenter,
      maxWidth: isFullMode ? double.infinity : null,
      maxHeight: isFullMode ? double.infinity : null,
      child: Center(
        child: Container(
          width: isFullMode ? screenSize.width : null,
          height: isFullMode ? screenSize.height : null,
          child: _getWidgetBody(),
        ),
      ),
    );
  }

  Widget _getWidgetBody() {
    return Stack(
      children: [
        _getPlayer(),
        _getTitleArea(),
        _getPipEnterView(),
        _getImageSpriteView(),
        _getSubtitleDisplayView(),
        _getCover(),
        _getBottomView(),
        _getStartOrResumeBtn(),
        _getQualityListView(),
        _getSubtitleListView(),
        _getAudioListView(),
        _getMoreMenuView(),
        _getLoading(),
      ],
    );
  }

  Widget _getAudioListView() {
    return Visibility(
        visible:_isShowAudioListView,
        child: AudioListView(_audioTrackController, _playController.audioTrackInfoList, _playController.currentAudioTrackInfo, _audioListViewKey));
  }

  Widget _getSubtitleListView() {
    return Visibility(visible: _isShowSubtitleListView,
        child: SubtitleListView(_subtitleTrackController, _playController.subtitleTrackInfoList, _playController.currentSubtitleTrackInfo, _subtitleListViewKey));
  }

  Widget _getSubtitleDisplayView() {
    // When switching between horizontal and vertical screens, different State-instances need to be synchronized
    TXVodSubtitleData? subtitleData = _playController.currentSubtitleData;
    bool needShowSubtitle = (subtitleData?.subtitleData ?? "") != "";

    return IgnorePointer(
      ignoring: true,
      child: needShowSubtitle && subtitleData != null
          ? SubtitleDisplayView(subtitleData,
            renderModel: _playController._currentSubtitleRenderModel ?? TXSubtitleRenderModel(),
            alignment: Alignment.bottomCenter,)
          : Container(),
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
          _playController._playerUIStatus == SuperPlayerUIStatus.WINDOW_MODE,
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
    return GestureDetector(
        onDoubleTap: _onDoubleTapVideo,
        onTap: _onSingleTapVideo,
        child: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: TXPlayerVideo(viewKey: _videoKey, onRenderViewCreatedListener: _onPlayerViewCreated,),
        )
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
          _currentUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE,
          _playController._getPlayName(),
          _isShowDownload,
          _isDownloaded,
          _videoTitleKey,
          showAudioView: _playController.audioTrackInfoList?.isNotEmpty ?? false,
          showSubtitleView: _playController.subtitleTrackInfoList?.isNotEmpty ?? false,
        ),
      ),
    );
  }

  void _onEnterPipMode() async {
    if (_currentUIStatus != SuperPlayerUIStatus.PIP_MODE) {
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
          failedStr = "enterPip failed,unkonw error:$result";
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
    if (_currentUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
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
      _playController.fullScreenController.switchToOrientation(manualOrientationDirection);
    } else {
      _playController.fullScreenController.switchToOrientation(TXVodPlayEvent.ORIENTATION_PORTRAIT_UP);
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
      _cancelHideRunnable();
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

  void _cancelHideRunnable() {
    if (_controlViewTimer.isActive) {
      _controlViewTimer.cancel();
    }
  }

  void _startHideRunnable() {
    _cancelHideRunnable();
    _controlViewTimer = Timer(const Duration(milliseconds: _controlViewShowTime), () {
      hideControlView(needHideMenuView: false);
    });
  }

  /// Hide all control components.
  /// 隐藏所有控制组件
  void hideControlView({bool needHideMenuView = true}) {
    if (!_isShowControlView || !mounted) {
      return;
    }

    if (_currentUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    // Hide moreView
    if (needHideMenuView) {
      _moreViewKey.currentState?.hideShowMoreView();
    }
    setState(() {
      _isShowControlView = false;
      if (needHideMenuView) {
        _isShowQualityListView = false;
        _isShowSubtitleListView = false;
        _isShowAudioListView = false;
      }
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
  final SuperPlayerRenderMode renderMode;

  const SuperPlayerFullScreenView(this._playController, this.controller, this.renderMode, {Key? viewKey}) : super(key: viewKey);

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
                  child: SuperPlayerView(
                    widget._playController,
                    viewKey: widget.key,
                    renderMode: widget.renderMode,
                  )),
            )));
  }

  Future<bool> _onFullScreenWillPop() async {
    widget._playController.onBackPress();
    return true;
  }

  @override
  void dispose() {
    widget._playController.fullScreenController._isInFullScreenUI = false;
    widget.controller.onExitFullScreen();
    super.dispose();
  }
}

class SuperPlayerFullScreenController {
  Function onExitFullScreen;

  SuperPlayerFullScreenController(this.onExitFullScreen);
}
