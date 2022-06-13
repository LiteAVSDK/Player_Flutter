// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;
/// superplayer play controller
class SuperPlayerController {
  static const TAG = "SuperPlayerController";

  final StreamController<Map<dynamic, dynamic>> _eventStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _simpleEventStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _playStateStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _playerNetStatusStreamController = StreamController.broadcast();

  /// simple event,see SuperPlayerViewEvent
  Stream<Map<dynamic, dynamic>> get onSimplePlayerEventBroadcast => _simpleEventStreamController.stream;
  /// player net status,see TXVodNetEvent
  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _playerNetStatusStreamController.stream;

  TXVodPlayerController? _vodPlayerController;
  SuperPlayerModel? videoModel;
  int _playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
  PlayInfoProtocol? _currentProtocol;
  _SuperPlayerObserver? _observer;
  VideoQuality? currentQuality;
  List<VideoQuality>? currentQualiyList;

  SuperPlayerState playerState = SuperPlayerState.INIT;
  SuperPlayerType playerType = SuperPlayerType.VOD;

  String _currentPlayUrl = "";

  bool isPrepared = false;
  bool _needToResume = false;
  bool _needToPause = false;
  bool _isMultiBitrateStream = false; // 是否是多码流url播放
  bool _changeHWAcceleration = false; // 切换硬解后接收到第一个关键帧前的标记位
  bool _isFullScreen = false;
  bool _isOpenHWAcceleration = true;
  final BuildContext _context;

  int currentDuration = 0;
  int videoDuration = 0;

  double _seekPos = 0; // 记录切换硬解时的播放时间
  /// 该值会改变新播放视频的播放开始时间点
  double startPos = 0;
  double videoWidth = 0;
  double videoHeight = 0;
  double currentPlayRate = 1.0;

  SuperPlayerController(this._context) {
    _initVodPlayer();
  }

  void _initVodPlayer() async {
    _vodPlayerController = new TXVodPlayerController();
    await _vodPlayerController?.initialize();
    _vodPlayerController?.onPlayerEventBroadcast?.listen((event) async {
      int eventCode = event['event'];
      switch (eventCode) {
        case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED: // vodPrepared
          isPrepared = true;
          if (_isMultiBitrateStream) {
            List<dynamic>? bitrateListTemp = await _vodPlayerController!.getSupportedBitrates();
            List<FTXBitrateItem> bitrateList = [];
            if (null != bitrateListTemp) {
              for (Map<dynamic, dynamic> map in bitrateListTemp) {
                bitrateList.add(FTXBitrateItem(map['index'], map['width'], map['height'], map['bitrate']));
              }
            }

            VideoQuality? defaultQuality;
            List<VideoQuality> videoQualities = [];
            bitrateList.sort((a, b) => b.bitrate.compareTo(a.bitrate)); // 码率从高到低
            for (int i = 0; i < bitrateList.length; i++) {
              FTXBitrateItem bitrateItem = bitrateList[i];
              VideoQuality quality = VideoQualityUtils.convertToVideoQualityByBitrate(_context, bitrateItem);
              videoQualities.add(quality);
            }

            int? bitrateIndex = await _vodPlayerController?.getBitrateIndex(); //获取默认码率的index
            for (VideoQuality quality in videoQualities) {
              if (quality.index == bitrateIndex) {
                defaultQuality = quality;
              }
            }
            _updateVideoQualityList(videoQualities, defaultQuality);
          }

          if (_needToPause) {
            _vodPlayerController?.pause();
          } else if (_needToResume) {
            _vodPlayerController?.resume();
          }
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING: // PLAY_EVT_PLAY_LOADING
          if (playerState == SuperPlayerState.PAUSE) {
            _updatePlayerState(SuperPlayerState.PAUSE);
          } else {
            _updatePlayerState(SuperPlayerState.LOADING);
          }
          break;
        case TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END:
          if (playerState == SuperPlayerState.LOADING) {
            _updatePlayerState(SuperPlayerState.PLAYING);
          }
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN: // PLAY_EVT_PLAY_BEGIN
          if (_needToPause) {
            return;
          }
          _updatePlayerState(SuperPlayerState.PLAYING);
          break;
        case TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME:
          // PLAY_EVT_RCV_FIRST_I_FRAME
          if (_needToPause) {
            return;
          }
          if (_changeHWAcceleration) {
            LogUtils.d(TAG, "seek pos $_seekPos");
            seek(_seekPos);
            _changeHWAcceleration = false;
          }

          _updatePlayerState(SuperPlayerState.PLAYING);
          _observer?.onRcvFirstIframe();
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_END:
          _updatePlayerState(SuperPlayerState.END);
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
          dynamic progress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS];
          dynamic duration = event[TXVodPlayEvent.EVT_PLAY_DURATION];
          if (null != progress) {
            currentDuration = progress.toInt(); // 当前时间，转换后的单位 秒
          }
          if (null != duration) {
            videoDuration = duration.toInt(); // 总播放时长，转换后的单位 秒
          }
          if (videoDuration != 0) {
            _observer?.onPlayProgress(currentDuration, videoDuration);
          }
          break;
      }
      _eventStreamController.add(event);
    });
    _vodPlayerController?.onPlayerNetStatusBroadcast.listen((event) {
      dynamic wd = (event["VIDEO_WIDTH"]);
      dynamic hd = (event["VIDEO_HEIGHT"]);
      if (null != wd && null != hd) {
        double w = wd.toDouble();
        double h = hd.toDouble();
        if (w > 0 && h > 0) {
          if (w != videoWidth) {
            videoWidth = w;
          }
          if (h != videoHeight) {
            videoHeight = h;
          }
        }
      }
      _playerNetStatusStreamController.add(event);
    });
  }

  void _checkVodPlayerIsInit() {
    if (null == _vodPlayerController) {
      _initVodPlayer();
    }
  }

  /// 播放视频
  void playWithModel(SuperPlayerModel videoModel) {
    this.videoModel = videoModel;
    _playAction = videoModel.playAction;
    resetPlayer();
    if (_playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY || _playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
      _playWithModelInner(videoModel);
    } else {
      _observer?.onNewVideoPlay();
    }
  }

  Future<void> _playWithModelInner(SuperPlayerModel videoModel) async {
    _checkVodPlayerIsInit();
    this.videoModel = videoModel;
    _playAction = videoModel.playAction;
    _observer?.onVideoImageSpriteAndKeyFrameChanged(null, null);
    _currentProtocol = null;

    // 优先使用url播放
    if (videoModel.videoURL.isNotEmpty) {
      _playWithUrl(videoModel);
    } else if (videoModel.videoId != null && (videoModel.videoId!.fileId.isNotEmpty)) {
      _currentProtocol = PlayInfoProtocol(videoModel);
      // 没有url的时候，根据field去请求
      await _sendRequest();
    }
  }

  Future<void> _sendRequest() async {
    _currentProtocol?.sendRequest((protocol, resultModel) {
      // onSuccess
      if (videoModel != resultModel) {
        return;
      }
      _playModeVideo(protocol);
      _updatePlayerType(SuperPlayerType.VOD);
      _observer?.onPlayProgress(0, resultModel.duration);
      _observer?.onVideoImageSpriteAndKeyFrameChanged(protocol.getImageSpriteInfo(), protocol.getKeyFrameDescInfo());
    }, (errCode, message) {
      // onError
      _observer?.onError(SuperPlayerCode.VOD_REQUEST_FILE_ID_FAIL, "播放视频文件失败 code = $errCode msg = $message");
      _addSimpleEvent(SuperPlayerViewEvent.onSuperPlayerError);
    });
  }

  void _playModeVideo(PlayInfoProtocol protocol) {
    String? videoUrl = protocol.getUrl();
    _playVodUrl(videoUrl);
    List<VideoQuality>? qualityList = protocol.getVideoQualityList();

    _isMultiBitrateStream = protocol.getResolutionNameList() != null ||
        qualityList != null ||
        (videoUrl != null && videoUrl.contains("m3u8"));

    _updateVideoQualityList(qualityList, protocol.getDefaultVideoQuality());
  }

  void _playUrlVideo(SuperPlayerModel? model) {
    if (model != null) {
      if (model.multiVideoURLs != null && model.multiVideoURLs.isNotEmpty) {
        // 多码率URL播放
        for (int i = 0; i < model.multiVideoURLs.length; i++) {
          if (i == model.defaultPlayIndex) {
            _playVodUrl(model.multiVideoURLs[i].url);
          }
        }
      } else if (model.videoURL != null && model.videoURL.isNotEmpty) {
        _playVodUrl(model.videoURL);
      }
    }
  }

  void _playWithUrl(SuperPlayerModel model) {
    List<VideoQuality> videoQualities = [];
    VideoQuality? defaultVideoQuality;
    late String videoUrl;
    if (model.multiVideoURLs.isNotEmpty) {
      int i = 0;
      for (SuperPlayerUrl superPlayerUrl in model.multiVideoURLs) {
        if (i == model.defaultPlayIndex) {
          videoUrl = superPlayerUrl.url;
        }
        videoQualities.add(VideoQuality(index: i++, title: superPlayerUrl.qualityName, url: superPlayerUrl.url));
      }
      defaultVideoQuality = videoQualities[model.defaultPlayIndex];
    } else {
      videoUrl = model.videoURL;
    }
    if (videoUrl == null || videoUrl.isEmpty) {
      _observer?.onError(SuperPlayerCode.PLAY_URL_EMPTY, "播放视频失败，播放链接为空");
      return;
    }
    _playVodUrl(videoUrl);
    _updatePlayerType(SuperPlayerType.VOD);
    _updateVideoQualityList(videoQualities, defaultVideoQuality);
  }

  Future<void> _playVodUrl(String? url) async {
    if (null == url || url.isEmpty) {
      return;
    }
    _isMultiBitrateStream = url.contains(".m3u8");
    _currentPlayUrl = url;
    if (null != _vodPlayerController) {
      await _vodPlayerController?.setStartTime(startPos);
      if (_playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
        await _vodPlayerController?.setAutoPlay(isAutoPlay: false);
        _playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
      } else if (_playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY ||
          _playAction == SuperPlayerModel.PLAY_ACTION_MANUAL_PLAY) {
        await _vodPlayerController?.setAutoPlay(isAutoPlay: true);
      }
      String drmType = "plain";
      if (_currentProtocol != null) {
        LogUtils.d(TAG, "TOKEN: ${_currentProtocol!.getToken()}");
        await _vodPlayerController?.setToken(_currentProtocol!.getToken());
        if (_currentProtocol!.getDRMType() != null && _currentProtocol!.getDRMType()!.isNotEmpty) {
          drmType = _currentProtocol!.getDRMType()!;
        }
      } else {
        await _vodPlayerController?.setToken(null);
      }
      if (videoModel!.videoId != null && videoModel!.appId != 0) {
        Uri uri = Uri.parse(url);
        String query = uri.query;
        if (query == null || query.isEmpty) {
          query = "";
        } else {
          query = query + "&";
          if (query.contains("spfileid") || query.contains("spdrmtype") || query.contains("spappid")) {
            LogUtils.d(TAG, "url contains superplay key. $query");
          }
          query += "spfileid=${videoModel!.videoId!.fileId}" "&spdrmtype=$drmType&spappid=${videoModel!.appId}";
        }
      }
      LogUtils.d(TAG, "play url:$url");
      await _vodPlayerController?.startPlay(url);
    }
  }

  /// 暂停视频
  /// 涉及到_updatePlayerState相关的方法，不使用异步,避免异步调用导致的playerState更新不及时
  void pause() {
    if (playerType == SuperPlayerType.VOD) {
      if (isPrepared) {
        _vodPlayerController?.pause();
      }
    } else {
      // todo implements live player
    }
    _updatePlayerState(SuperPlayerState.PAUSE);
    _needToPause = true;
  }

  /// 继续播放视频
  void resume() {
    if (playerType == SuperPlayerType.VOD) {
      _needToResume = true;
      if (isPrepared) {
        _vodPlayerController?.resume();
      }
    } else {
      // todo implements live player
    }
    _needToPause = false;
    _updatePlayerState(SuperPlayerState.PLAYING);
  }

  /// 重新开始播放视频
  Future<void> reStart() async {
    if (playerType == SuperPlayerType.LIVE || playerType == SuperPlayerType.LIVE_SHIFT) {
      // todo implements live player
    } else {
      await _playVodUrl(_currentPlayUrl);
    }
  }

  void _updatePlayerType(SuperPlayerType type) {
    if (playerType != type) {
      playerType = type;
    }
    _observer?.onPlayerTypeChange(type);
  }

  void _updatePlayerState(SuperPlayerState state) {
    playerState = state;
    switch (state) {
      case SuperPlayerState.INIT:
        _observer?.onPlayPrepare();
        break;
      case SuperPlayerState.PLAYING:
        _observer?.onPlayBegin(_getPlayName());
        _addSimpleEvent(SuperPlayerViewEvent.onSuperPlayerDidStart);
        break;
      case SuperPlayerState.PAUSE:
        _observer?.onPlayPause();
        break;
      case SuperPlayerState.LOADING:
        _observer?.onPlayLoading();
        break;
      case SuperPlayerState.END:
        _observer?.onPlayStop();
        _addSimpleEvent(SuperPlayerViewEvent.onSuperPlayerDidEnd);
        break;
    }
    Map<String, SuperPlayerState> eventMap = new Map();
    eventMap['event'] = state;
    _playStateStreamController.add(eventMap);
  }

  String _getPlayName() {
    String title = "";
    if (videoModel != null && null != videoModel!.title && videoModel!.title.isNotEmpty) {
      title = videoModel!.title;
    } else if (_currentProtocol != null &&
        null != _currentProtocol!.getName() &&
        _currentProtocol!.getName()!.isNotEmpty) {
      title = _currentProtocol!.getName()!;
    }
    return title;
  }

  void _updateVideoQualityList(List<VideoQuality>? qualityList, VideoQuality? defaultQuality) {
    currentQuality = defaultQuality;
    currentQualiyList = qualityList;
    _observer?.onVideoQualityListChange(qualityList, defaultQuality);
  }

  void _addSimpleEvent(String event) {
    Map<String, String> eventMap = new Map();
    eventMap['event'] = event;
    _simpleEventStreamController.add(eventMap);
  }

  void _updateFullScreenState(bool fullScreen) {
    _isFullScreen = fullScreen;
    if (fullScreen) {
      _addSimpleEvent(SuperPlayerViewEvent.onStartFullScreenPlay);
    } else {
      _addSimpleEvent(SuperPlayerViewEvent.onStopFullScreenPlay);
    }
  }

  /// just for inner invoke
  Future<void> _stopPlay() async {
    await _vodPlayerController?.stop();
  }

  /// 重置播放器状态
  void resetPlayer() async {
    isPrepared = false;
    _needToResume = false;
    _needToPause = false;
    currentDuration = 0;
    videoDuration = 0;
    currentQuality = null;
    currentQualiyList?.clear();
    _currentProtocol = null;

    await _vodPlayerController?.stop(isNeedClear: true);

    _updatePlayerState(SuperPlayerState.INIT);
  }

  /// 释放播放器，播放器释放之后，将不能再使用
  Future<void> releasePlayer() async {
    // 先移除widget的事件监听
    _observer?.onDispose();
    resetPlayer();
    _vodPlayerController?.dispose();
    _vodPlayerController = null;
  }

  /// return true : 执行了退出全屏等操作，消耗了返回事件  false：未消耗事件
  bool onBackPress() {
    if (null != _vodPlayerController && _isFullScreen) {
      _observer?.onSysBackPress();
      return true;
    }
    return false;
  }

  void _onBackTap() {
    _addSimpleEvent(SuperPlayerViewEvent.onSuperPlayerBackAction);
  }

  /// 切换清晰度
  void switchStream(VideoQuality videoQuality) async {
    currentQuality = videoQuality;
    if (playerType == SuperPlayerType.VOD) {
      if (null != _vodPlayerController) {
        if (videoQuality.url.isNotEmpty) {
          // url stream need manual seek
          double currentTime = await _vodPlayerController!.getCurrentPlaybackTime();
          await _vodPlayerController?.stop(isNeedClear: false);
          LogUtils.d(TAG, "onQualitySelect quality.url:${videoQuality.url}");
          await _vodPlayerController?.setStartTime(currentTime);
          await _vodPlayerController?.startPlay(videoQuality.url);
        } else {
          LogUtils.d(TAG, "setBitrateIndex quality.index:${videoQuality.index}");
          await _vodPlayerController?.setBitrateIndex(videoQuality.index);
        }
        _observer?.onSwitchStreamStart(true, SuperPlayerType.VOD, videoQuality);
      }
    } else {
      // todo implements live player
    }
  }

  /// seek 到需要的时间点进行播放
  Future<void> seek(double progress) async {
    if (playerType == SuperPlayerType.VOD) {
      await _vodPlayerController?.seek(progress);
      bool? isPlaying = await _vodPlayerController?.isPlaying();
      // resume when not playing.if isPlaying is null,not resume
      if (!(isPlaying ?? true)) {
        resume();
      }
    } else {
      // todo implements live player
    }
    _observer?.onSeek(progress);
  }

  /// 配置播放器
  Future<void> setPlayConfig(FTXVodPlayConfig config) async {
    await _vodPlayerController?.setConfig(config);
  }

  /// 开关硬解编码播放
  Future<void> enableHardwareDecode(bool enable) async {
    _isOpenHWAcceleration = enable;
    if (playerType == SuperPlayerType.VOD) {
      if (null != _vodPlayerController) {
        await _vodPlayerController?.enableHardwareDecode(enable);
        if (playerState != SuperPlayerState.END) {
          _changeHWAcceleration = true;
          _seekPos = await _vodPlayerController!.getCurrentPlaybackTime();
          LogUtils.d(TAG, "seek pos $_seekPos");
          resetPlayer();
          // 当protocol为空时，则说明当前播放视频为非v2和v4视频
          if (_currentProtocol == null) {
            _playUrlVideo(videoModel);
          } else {
            _playModeVideo(_currentProtocol!);
          }
        }
      }
    } else {
      // todo implements live player
    }
  }

  Future<void> setPlayRate(double rate) async {
    currentPlayRate = rate;
    _vodPlayerController?.setRate(rate);
  }

  /// 获得当前播放器状态
  SuperPlayerState getPlayerState() {
    return playerState;
  }
}
