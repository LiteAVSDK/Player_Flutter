// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_short_video_player_lib;

class ShortVideoPageWidget extends StatefulWidget {
  SuperPlayerModel model;
  int position;
  VideoEventDispatcher eventDispatcher;

  ShortVideoPageWidget({required this.position, required this.model, required this.eventDispatcher});

  @override
  State<StatefulWidget> createState() {
    return _TXVodPlayerPageState();
  }
}

class _TXVodPlayerPageState extends State<ShortVideoPageWidget> {
  static const TAG = "ShortVideo::TXVodPlayerPageState";
  bool _isVideoPrepared = false;
  bool _isVideoPlaying = true;
  GlobalKey<VideoSliderViewState> _progressSliderKey = GlobalKey();
  late StreamSubscription _eventSubscription;
  StreamSubscription? _playEventSubscription;

  TXVodPlayerController _controller;

  _TXVodPlayerPageState() : _controller = TXVodPlayerController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    _controller.setConfig(FTXVodPlayConfig());
    LogUtils.i(
        TAG, " [init] ${widget.position.toString()} ${this.hashCode.toString()} ${_controller.hashCode.toString()}");
    _setPlayerListener();
    _setEventBusListener();
    if (widget.position == 0) {
      _startPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getTXVodPlayerMainPage();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  _dispose() async {
    _eventSubscription.cancel();
    _playEventSubscription?.cancel();
    await _stop();
    _controller.dispose();
    LogUtils.i(
        TAG, " [dispose] ${widget.position.toString()} ${this.hashCode.toString()} ${_controller.hashCode.toString()}");
  }

  Widget _getTXVodPlayerMainPage() {
    return Stack(
      children: [_getGestureDetectorView(), _getPreviewImg(), _getSeekBarView()],
    );
  }

  Widget _getGestureDetectorView() {
    return InkWell(
        child: Stack(
          children: [
            Container(
              child: TXPlayerVideo(onRenderViewCreatedListener: (viewId) {
                /// 此处只展示了最基础的纹理和播放器的配置方式。 这里可记录下来 viewId，在多纹理之间进行切换，比如横竖屏切换场景，竖屏的画面，
                /// 要切换到横屏的画面，可以在切换到横屏之后，拿到横屏的viewId 设置上去。回到竖屏的时候，再通过 viewId 切换回来。
                /// Only the most basic configuration methods for textures and the player are shown here.
                /// The `viewId` can be recorded here to switch between multiple textures. For example, in the scenario
                /// of switching between portrait and landscape orientations:
                /// To switch from the portrait view to the landscape view, obtain the `viewId` of the landscape view
                /// after switching to landscape orientation and set it.  When switching back to portrait orientation,
                /// switch back using the recorded `viewId`.
                _controller.setPlayerView(viewId);
              },),
            ),
            _getPauseView()
          ],
        ),
        onTap: () {
          _onTapPageView();
        });
  }

  _onTapPageView() {
    _controller.isPlaying().then((value) {
      value ? _pause() : _resume();
    });
    LogUtils.i(TAG, "tap ${_isVideoPlaying.toString()}");
  }

  Widget _getSeekBarView() {
    return SafeArea(
        child: Stack(children: [
          Positioned(
            child: VideoSliderView(_controller, _progressSliderKey),
            bottom: 20,
            right: 0,
            left: 0,
          )
        ],));
  }

  Widget _getPauseView() {
    return Offstage(
        offstage: _isVideoPlaying,
        child: Align(
          child: Container(
              child: Image(
                  image: AssetImage("images/superplayer_ic_vod_play_normal.png", package: PlayerConstants.PKG_NAME)),
              height: 50,
              width: 50),
          alignment: Alignment.center,
        ));
  }

  Widget _getPreviewImg() {
    return Offstage(
        offstage: _isVideoPrepared,
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.model.coverUrl),
                  fit: BoxFit.cover,
                )),
            child: Scaffold(
              backgroundColor: Colors.transparent, //把scaffold的背景色改成透明
            )));
  }

  _pause() async {
    LogUtils.i(TAG, "[_pause]");
    await _controller.pause();
    setState(() {
      _isVideoPlaying = false;
    });
  }

  _resume() async {
    LogUtils.i(TAG, "[_resume]");
    await _controller.resume();
    setState(() {
      _isVideoPlaying = true;
    });
  }

  _stopLastAndPlayCurrent(int index) {
    LogUtils.i(TAG,
        " [received at not current outside] ${widget.position.toString()} ${this.hashCode.toString()} ${widget.hashCode.toString()} ${_controller.hashCode.toString()}");
    index != widget.position ? _stop() : _startPlay();
  }

  Future<void> _stop() async {
    if (!mounted) return;
    LogUtils.i(TAG, " [stop] ${widget.position.toString()} ${widget.hashCode.toString()}");
    _isVideoPrepared = false;
    _isVideoPlaying = true;
    _controller.stop();
  }

  _startPlay() async {
    LogUtils.i(TAG, " [_startPlay]");
    setState(() {
      _isVideoPlaying = true;
    });
    await _controller.setLoop(true);
    final SuperPlayerModel model = widget.model;
    if (model.videoURL.isNotEmpty) {
      _controller.startVodPlay(model.videoURL);
    } else if(model.videoId != null) {
      _controller.startVodPlayWithParams(TXPlayInfoParams(appId: model.appId, fileId: model.videoId!.fileId, psign: model.videoId!.psign));
    } else {
      LogUtils.e(TAG, "shortVideo model source is empty$model");
    }
  }

  _hideCover() {
    if (!mounted) return;
    LogUtils.i(TAG, " [received] ${widget.position.toString()} ${widget.hashCode.toString()}");
    setState(() {
      _isVideoPrepared = true;
    });
  }

  _setEventBusListener() {
    _eventSubscription = widget.eventDispatcher.getEventStream().listen((event) {
      if (event.eventType == BaseEvent.PLAY_AND_STOP) {
        _stopLastAndPlayCurrent(event.playerIndex);
      } else if (event.eventType == BaseEvent.PAUSE) {
        // for from front to back
        _pause();
      } else if(event.eventType == BaseEvent.RESUME) {
        // for from back to front
        if (_isVideoPlaying) {
          _controller.resume();
        }
      } else {
        LogUtils.e(TAG, "receive unknown eventType${event.eventType}");
      }
    });
  }

  _setPlayerListener() {
    _playEventSubscription = _controller.onPlayerEventBroadcast.listen((event) async {
      final int eventCode = event["event"];
      if (eventCode == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        if (!mounted) return;
        double currentProgress = event["EVT_PLAY_PROGRESS"].toDouble();
        double videoDuration = event["EVT_PLAY_DURATION"].toDouble();
        _progressSliderKey.currentState?.updateProgress(currentProgress / videoDuration, videoDuration);
      } else if (eventCode == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        LogUtils.i(TAG, " [received] TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME");
        _hideCover();
      } else if (eventCode == TXVodPlayEvent.PLAY_EVT_GET_PLAYINFO_SUCC) {
        String coverUrl = event[TXVodPlayEvent.EVT_PLAY_COVER_URL];
        if (coverUrl.isNotEmpty) {
          setState(() {
            widget.model.coverUrl = coverUrl;
          });
        }
      }
    });
  }
}
