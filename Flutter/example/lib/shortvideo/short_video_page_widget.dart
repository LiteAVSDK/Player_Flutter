// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_short_video_player_lib;

class ShortVideoPageWidget extends StatefulWidget {
  String videoUrl;
  String coverUrl;
  int position;
  late TXVodPlayerController _controller;

  ShortVideoPageWidget(
      {required this.position,
      required this.videoUrl,
      required this.coverUrl});

  @override
  State<StatefulWidget> createState() {
    return _TXVodPlayerPageState();
  }
}

class _TXVodPlayerPageState extends State<ShortVideoPageWidget> {
  static const TAG = "ShortVideo::TXVodPlayerPageState";
  late TXPlayerVideo _txPlayerVideo;
  bool _isVideoPrepared = false;
  bool _isVideoPlaying = true;
  GlobalKey<VideoSliderViewState> _progressSliderKey = GlobalKey();
  late StreamSubscription _streamSubscriptionStopAndPlay;

  late StreamSubscription _streamSubscriptionApplicationResume;

  late StreamSubscription _streamSubscriptionApplicationPause;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    widget._controller = new TXVodPlayerController();
    _txPlayerVideo = new TXPlayerVideo(controller: widget._controller);
    await widget._controller.initialize();
    widget._controller.setConfig(FTXVodPlayConfig());
    LogUtils.i(TAG, " [init] ${widget.position.toString()} ${this.hashCode.toString()} ${widget._controller.hashCode.toString()}");
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
    _streamSubscriptionStopAndPlay.cancel();
    _streamSubscriptionApplicationResume.cancel();
    _streamSubscriptionApplicationPause.cancel();
    await _stop();
    widget._controller.dispose();
    LogUtils.i(TAG, " [dispose] ${widget.position.toString()} ${this.hashCode.toString()} ${widget._controller.hashCode.toString()}");
  }

  Widget _getTXVodPlayerMainPage() {
    return Stack(
      children: <Widget>[
        _getGestureDetectorView(),
        _getPreviewImg(),
        _getSeekBarView()
      ],
    );
  }

  GestureDetector _getGestureDetectorView() {
    return GestureDetector(
        child: Stack(
          children: <Widget>[
            Container(
              child: _txPlayerVideo,
            ),
            _getPauseView()
          ],
        ),
        onTap: () {
          _onTapPageView();
        });
  }

  _onTapPageView() {
    widget._controller.isPlaying().then((value) {
      value == true ? _pause() :_resume();
    });
    LogUtils.i(TAG, "tap ${_isVideoPlaying.toString()}");
  }

  Widget _getSeekBarView() {
    return Positioned(
      child: VideoSliderView(widget._controller, _progressSliderKey),
      bottom: 20,
      right: 0,
      left: 0,
    );
  }

  Widget _getPauseView() {
    return Offstage(
        offstage: _isVideoPlaying,
        child: Align(
          child: Container(
              child: Image.asset('images/superplayer_ic_vod_play_normal.png'),
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
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage(widget.coverUrl),
                  fit: BoxFit.fill,
                )),
            child: Scaffold(
              backgroundColor: Colors.transparent, //把scaffold的背景色改成透明
            )));
  }

  _pause() {
    LogUtils.i(TAG, "[_pause]");
    widget._controller.pause();
    setState(() {
      _isVideoPlaying = false;
    });
  }

  _resume() {
    LogUtils.i(TAG, "[_resume]");
    widget._controller.resume();
    setState(() {
      _isVideoPlaying = true;
    });
  }

  _stopLastAndPlayCurrent(StopAndResumeEvent event) {
    LogUtils.i(TAG, " [received at not current outside] ${widget.position.toString()} ${this.hashCode.toString()} ${widget.hashCode.toString()} ${widget._controller.hashCode.toString()}");
    event.index != widget.position ? _stop() :_startPlay();
  }

  Future<void> _stop() async{
    if (!mounted) return;
    LogUtils.i(TAG, " [stop] ${widget.position.toString()} ${widget.hashCode.toString()}");
    _isVideoPrepared = false;
    _isVideoPlaying = true;
    widget._controller.stop();
  }



  _startPlay() async {
    LogUtils.i(TAG, " [_startPlay]");
    setState(() {
      _isVideoPlaying = true;
    });
    await widget._controller.setLoop(true);
    widget._controller.startVodPlay(widget.videoUrl);
  }

  _hideCover() {
    if (!mounted) return;
    LogUtils.i(TAG, " [received] ${widget.position.toString()} ${widget.hashCode.toString()}");
    setState(() {
      _isVideoPrepared = true;
    });
  }

  _setEventBusListener() {
    _streamSubscriptionStopAndPlay = EventBusUtils.getInstance().on<StopAndResumeEvent>().listen((event) {
      _stopLastAndPlayCurrent(event);
    });

    _streamSubscriptionApplicationResume = EventBusUtils.getInstance().on<ApplicationResumeEvent>().listen((event) {
          _resume();
    });

    _streamSubscriptionApplicationPause = EventBusUtils.getInstance().on<ApplicationPauseEvent>().listen((event) {
          _pause();
    });
  }

  _setPlayerListener() {
    widget._controller.onPlayerEventBroadcast.listen((event) async {
      if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        if (!mounted) return;
        double currentProgress = event["EVT_PLAY_PROGRESS"].toDouble();
        double videoDuration = event["EVT_PLAY_DURATION"].toDouble(); // 总播放时长，转换后的单位 秒
        _progressSliderKey.currentState?.updateProgress(currentProgress / videoDuration, videoDuration);
      } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        LogUtils.i(TAG, " [received] TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME");
        _hideCover();
      }
    });
  }
}