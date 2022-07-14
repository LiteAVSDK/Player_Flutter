// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// superplayer play controller
class SuperPlayerController {
  static const TAG = "SuperPlayerController";

  final StreamController<Map<dynamic, dynamic>> _simpleEventStreamController = StreamController.broadcast();
  final StreamController<Map<dynamic, dynamic>> _playerNetStatusStreamController = StreamController.broadcast();

  /// simple event,see SuperPlayerViewEvent
  Stream<Map<dynamic, dynamic>> get onSimplePlayerEventBroadcast => _simpleEventStreamController.stream;

  /// player net status,see TXVodNetEvent
  Stream<Map<dynamic, dynamic>> get onPlayerNetStatusBroadcast => _playerNetStatusStreamController.stream;

  late TXVodPlayerController _vodPlayerController;
  late TXLivePlayerController _livePlayerController;

  SuperPlayerModel? videoModel;
  int _playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
  PlayInfoProtocol? _currentProtocol;
  _SuperPlayerObserver? _observer;
  VideoQuality? currentQuality;
  List<VideoQuality>? currentQualiyList;
  StreamController<TXPlayerHolder> playerStreamController = StreamController.broadcast();
  SuperPlayerState playerState = SuperPlayerState.INIT;
  SuperPlayerType playerType = SuperPlayerType.VOD;
  FTXVodPlayConfig _vodConfig = FTXVodPlayConfig();
  FTXLivePlayConfig _liveConfig = FTXLivePlayConfig();
  StreamSubscription? _vodPlayEventListener;
  StreamSubscription? _vodNetEventListener;
  StreamSubscription? _livePlayEventListener;
  StreamSubscription? _liveNetEventListener;

  String _currentPlayUrl = "";

  bool isPrepared = false;
  bool _needToResume = false;
  bool _needToPause = false;
  bool _isMultiBitrateStream = false; // 是否是多码流url播放
  bool _changeHWAcceleration = false; // 切换硬解后接收到第一个关键帧前的标记位
  bool _isOpenHWAcceleration = true;
  int _playerUIStatus = SuperPlayerUIStatus.WINDOW_MODE;
  final BuildContext _context;

  double currentDuration = 0;
  double videoDuration = 0;
  int _maxLiveProgressTime = 0;

  double _seekPos = 0; // 记录切换硬解时的播放时间
  /// 该值会改变新播放视频的播放开始时间点
  double startPos = 0;
  double videoWidth = 0;
  double videoHeight = 0;
  double currentPlayRate = 1.0;

  SuperPlayerController(this._context) {
    _initVodPlayer();
    _initLivePlayer();
  }

  void _initVodPlayer() async {
    _vodPlayerController = new TXVodPlayerController();
    await _vodPlayerController.initialize();
    _setVodListener();
  }

  void _initLivePlayer() async {
    _livePlayerController = TXLivePlayerController();
    await _livePlayerController.initialize();
    _setLiveListener();
  }

  void _setVodListener() {
    _vodPlayEventListener?.cancel();
    _vodNetEventListener?.cancel();
    _vodPlayEventListener = _vodPlayerController.onPlayerEventBroadcast.listen((event) async {
      int eventCode = event['event'];
      switch (eventCode) {
        case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED: // vodPrepared
          isPrepared = true;
          if (_isMultiBitrateStream) {
            List<dynamic>? bitrateListTemp = await _vodPlayerController.getSupportedBitrates();
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

            int? bitrateIndex = await _vodPlayerController.getBitrateIndex(); //获取默认码率的index
            for (VideoQuality quality in videoQualities) {
              if (quality.index == bitrateIndex) {
                defaultQuality = quality;
              }
            }
            _updateVideoQualityList(videoQualities, defaultQuality);
          }

          if (_needToPause) {
            _vodPlayerController.pause();
          } else if (_needToResume) {
            _vodPlayerController.resume();
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
        case TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME: // PLAY_EVT_RCV_FIRST_I_FRAME
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
            currentDuration = progress.toDouble(); // 当前时间，转换后的单位 秒
          }
          if (null != duration) {
            videoDuration = duration.toDouble(); // 总播放时长，转换后的单位 秒
          }
          if (videoDuration != 0) {
            _observer?.onPlayProgress(currentDuration, videoDuration, await getPlayableDuration());
          }
          break;
      }
    });
    _vodNetEventListener = _vodPlayerController.onPlayerNetStatusBroadcast.listen((event) {
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

  void _setLiveListener() {
    _livePlayEventListener?.cancel();
    _liveNetEventListener?.cancel();
    _livePlayEventListener = _livePlayerController.onPlayerEventBroadcast.listen((event) async {
      int eventCode = event['event'];
      switch (eventCode) {
        case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED: // vodPrepared
        case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
          _updatePlayerState(SuperPlayerState.PLAYING);
          break;
        case TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT:
        case TXVodPlayEvent.PLAY_EVT_PLAY_END:
          if (playerType == SuperPlayerType.LIVE_SHIFT) {
            _livePlayerController.resumeLive();
            _observer?.onError(SuperPlayerCode.LIVE_SHIFT_FAIL, "时移失败,返回直播");
            _updatePlayerState(SuperPlayerState.PLAYING);
          } else {
            _stop();
            if (eventCode == TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT) {
              _observer?.onError(SuperPlayerCode.NET_ERROR, "网络不给力,点击重试");
            } else {
              _observer?.onError(SuperPlayerCode.LIVE_PLAY_END, event[TXVodPlayEvent.EVT_DESCRIPTION]);
            }
          }
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
          _updatePlayerState(SuperPlayerState.LOADING);
          break;
        case TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME:
          _updatePlayerState(SuperPlayerState.PLAYING);
          _observer?.onRcvFirstIframe();
          break;
        case TXVodPlayEvent.PLAY_EVT_STREAM_SWITCH_SUCC:
          _observer?.onSwitchStreamEnd(true, SuperPlayerType.LIVE, currentQuality);
          break;
        case TXVodPlayEvent.PLAY_ERR_STREAM_SWITCH_FAIL:
          _observer?.onSwitchStreamEnd(false, SuperPlayerType.LIVE, currentQuality);
          break;
        case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
          int progress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS_MS];
          _maxLiveProgressTime = progress > _maxLiveProgressTime ? progress : _maxLiveProgressTime;
          _observer?.onPlayProgress(progress / 1000, _maxLiveProgressTime / 1000, await getPlayableDuration());
          break;
      }
    });
    _liveNetEventListener = _livePlayerController.onPlayerNetStatusBroadcast.listen((event) {
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

  /// 播放视频
  Future<void> playWithModel(SuperPlayerModel videoModel) async {
    this.videoModel = videoModel;
    _playAction = videoModel.playAction;
    await resetPlayer();
    if (_playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY || _playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
      await _playWithModelInner(videoModel);
    } else {
      _observer?.onNewVideoPlay();
    }
  }

  Future<void> _playWithModelInner(SuperPlayerModel videoModel) async {
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
    _currentProtocol?.sendRequest((protocol, resultModel) async {
      // onSuccess
      if (videoModel != resultModel) {
        return;
      }
      _playModeVideo(protocol);
      _updatePlayerType(SuperPlayerType.VOD);
      _observer?.onPlayProgress(0, resultModel.duration.toDouble(), await getPlayableDuration());
      _observer?.onVideoImageSpriteAndKeyFrameChanged(protocol.getImageSpriteInfo(), protocol.getKeyFrameDescInfo());
    }, (errCode, message) {
      // onError
      _observer?.onError(SuperPlayerCode.VOD_REQUEST_FILE_ID_FAIL, "播放视频文件失败 code = $errCode msg = $message");
      _addSimpleEvent(SuperPlayerViewEvent.onSuperPlayerError);
    });
  }

  Future<double> getPlayableDuration() async {
    return await _vodPlayerController.getPlayableDuration();
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
    String? videoUrl;
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
    if (_isRTMPPlay(videoUrl)) {
      _playLiveURL(videoUrl, TXPlayType.LIVE_RTMP);
    } else if (_isFLVPlay(videoUrl)) {
      _playTimeShiftLiveURL(model.appId, videoUrl);
      if (model.multiVideoURLs.isNotEmpty) {
        _startMultiStreamLiveURL(videoUrl);
      }
    } else {
      _playVodUrl(videoUrl);
    }
    bool isLivePlay = (_isRTMPPlay(videoUrl) || _isFLVPlay(videoUrl));
    _observer?.onPlayProgress(0, model.duration.toDouble(), 0);
    _updatePlayerType(isLivePlay ? SuperPlayerType.LIVE : SuperPlayerType.VOD);
    _updateVideoQualityList(videoQualities, defaultVideoQuality);
  }

  Future<void> _playVodUrl(String? url) async {
    if (null == url || url.isEmpty) {
      return;
    }
    _isMultiBitrateStream = url.contains(".m3u8");
    _currentPlayUrl = url;
    await _vodPlayerController.setStartTime(startPos);
    if (_playAction == SuperPlayerModel.PLAY_ACTION_PRELOAD) {
      await _vodPlayerController.setAutoPlay(isAutoPlay: false);
      _playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
    } else if (_playAction == SuperPlayerModel.PLAY_ACTION_AUTO_PLAY ||
        _playAction == SuperPlayerModel.PLAY_ACTION_MANUAL_PLAY) {
      await _vodPlayerController.setAutoPlay(isAutoPlay: true);
    }
    _setVodListener();
    String drmType = "plain";
    if (_currentProtocol != null) {
      LogUtils.d(TAG, "TOKEN: ${_currentProtocol!.getToken()}");
      await _vodPlayerController.setToken(_currentProtocol!.getToken());
      if (_currentProtocol!.getDRMType() != null && _currentProtocol!.getDRMType()!.isNotEmpty) {
        drmType = _currentProtocol!.getDRMType()!;
      }
    } else {
      await _vodPlayerController.setToken(null);
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
      }
      query += "spfileid=${videoModel!.videoId!.fileId}" "&spdrmtype=$drmType&spappid=${videoModel!.appId}";
      Uri newUri = Uri(path: url, query: query);
      LogUtils.d(TAG, 'playVodURL: newurl =  ${Uri.decodeFull(newUri.toString())}  ;url=  $url');
      await _vodPlayerController.startPlay(Uri.decodeFull(newUri.toString()));
    } else {
      LogUtils.d(TAG, "playVodURL url:$url");
      await _vodPlayerController.startPlay(url);
    }
  }

  /// 暂停视频
  /// 涉及到_updatePlayerState相关的方法，不使用异步,避免异步调用导致的playerState更新不及时
  void pause() {
    if (playerType == SuperPlayerType.VOD) {
      if (isPrepared) {
        _vodPlayerController.pause();
      }
    } else {
      _livePlayerController.pause();
    }
    _updatePlayerState(SuperPlayerState.PAUSE);
    _needToPause = true;
  }

  /// 继续播放视频
  void resume() {
    if (playerType == SuperPlayerType.VOD) {
      _needToResume = true;
      if (isPrepared) {
        _vodPlayerController.resume();
      }
    } else {
      _livePlayerController.resume();
    }
    _needToPause = false;
    _updatePlayerState(SuperPlayerState.PLAYING);
  }

  /// 重新开始播放视频
  Future<void> reStart() async {
    if (playerType == SuperPlayerType.LIVE || playerType == SuperPlayerType.LIVE_SHIFT) {
      if (_isRTMPPlay(_currentPlayUrl)) {
        _playLiveURL(_currentPlayUrl, TXPlayType.LIVE_RTMP);
      } else if (_isFLVPlay(_currentPlayUrl) && null != videoModel) {
        _playTimeShiftLiveURL(videoModel!.appId, _currentPlayUrl);
        if (videoModel!.multiVideoURLs.isNotEmpty) {
          _startMultiStreamLiveURL(_currentPlayUrl);
        }
      }
    } else {
      await _playVodUrl(_currentPlayUrl);
    }
  }

  void _startMultiStreamLiveURL(String url) {
    _liveConfig.autoAdjustCacheTime = false;
    _liveConfig.maxAutoAdjustCacheTime = 5.0;
    _liveConfig.minAutoAdjustCacheTime = 5.0;
    _livePlayerController.setConfig(_liveConfig);
    _observer?.onPlayTimeShiftLive(_livePlayerController, url);
  }

  /// 播放直播URL
  void _playLiveURL(String url, int playType) async {
    _currentPlayUrl = url;
    _setLiveListener();
    bool result = await _livePlayerController.startPlay(url, playType: playType);
    if (result) {
      _updatePlayerState(SuperPlayerState.PLAYING);
    } else {
      LogUtils.e(TAG, "playLiveURL videoURL:$url,result:$result");
    }
  }

  /// 播放时移直播url
  void _playTimeShiftLiveURL(int appId, String url) {
    String bizid = url.substring(url.indexOf("//") + 2, url.indexOf("."));
    String streamid = url.substring(url.lastIndexOf("/") + 1, url.lastIndexOf("."));
    LogUtils.i(TAG, "bizid:$bizid,streamid:$streamid,appid:$appId");
    _playLiveURL(url, TXPlayType.LIVE_FLV);
  }

  void _updatePlayerType(SuperPlayerType type) {
    if (playerType != type) {
      playerType = type;
      updatePlayerView();
      _observer?.onPlayerTypeChange(type);
    }
  }

  void updatePlayerView() async {
    TXPlayerController controller = getCurrentController();
    TXPlayerHolder model = TXPlayerHolder(controller);
    playerStreamController.sink.add(model);
  }

  Stream<TXPlayerHolder> getPlayerStream() {
    return playerStreamController.stream;
  }

  /// 获得当前正在使用的controller
  TXPlayerController getCurrentController() {
    TXPlayerController controller;
    if (playerType == SuperPlayerType.VOD) {
      controller = _vodPlayerController;
    } else {
      controller = _livePlayerController;
    }
    return controller;
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

  void _updatePlayerUIStatus(int status) {
    if (_playerUIStatus != status) {
      _playerUIStatus = status;
      if (status == SuperPlayerUIStatus.FULLSCREEN_MODE) {
        _addSimpleEvent(SuperPlayerViewEvent.onStartFullScreenPlay);
      } else {
        _addSimpleEvent(SuperPlayerViewEvent.onStopFullScreenPlay);
      }
    }
  }

  /// 是否是RTMP协议
  bool _isRTMPPlay(String? videoURL) {
    return null != videoURL && videoURL.startsWith("rtmp");
  }

  /// 是否是HTTP-FLV协议
  bool _isFLVPlay(String? videoURL) {
    return (null != videoURL && videoURL.startsWith("http://") || videoURL!.startsWith("https://")) &&
        videoURL.contains(".flv");
  }

  /// 重置播放器状态
  Future<void> resetPlayer() async {
    isPrepared = false;
    _needToResume = false;
    _needToPause = false;
    currentDuration = 0;
    videoDuration = 0;
    currentQuality = null;
    currentQualiyList?.clear();
    _currentProtocol = null;
    // 移除所有事件
    _vodPlayEventListener?.cancel();
    _vodNetEventListener?.cancel();
    _livePlayEventListener?.cancel();
    _liveNetEventListener?.cancel();
    await _vodPlayerController.stop();
    await _livePlayerController.stop();

    _updatePlayerState(SuperPlayerState.INIT);
  }

  void _stop() async {
    resetPlayer();
    _updatePlayerState(SuperPlayerState.END);
  }

  /// 释放播放器，播放器释放之后，将不能再使用
  Future<void> releasePlayer() async {
    // 先移除widget的事件监听
    _observer?.onDispose();
    resetPlayer();
    playerStreamController.close();
    _vodPlayerController.dispose();
    _livePlayerController.dispose();
  }

  /// return true : 执行了退出全屏等操作，消耗了返回事件  false：未消耗事件
  bool onBackPress() {
    if (_playerUIStatus == SuperPlayerUIStatus.FULLSCREEN_MODE) {
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
      if (videoQuality.url.isNotEmpty) {
        // url stream need manual seek
        double currentTime = await _vodPlayerController.getCurrentPlaybackTime();
        await _vodPlayerController.stop(isNeedClear: false);
        LogUtils.d(TAG, "onQualitySelect quality.url:${videoQuality.url}");
        await _vodPlayerController.setStartTime(currentTime);
        await _vodPlayerController.startPlay(videoQuality.url);
      } else {
        LogUtils.d(TAG, "setBitrateIndex quality.index:${videoQuality.index}");
        await _vodPlayerController.setBitrateIndex(videoQuality.index);
      }
      _observer?.onSwitchStreamStart(true, SuperPlayerType.VOD, videoQuality);
    } else {
      bool success = false;
      if (videoQuality.url.isNotEmpty) {
        int result = await _livePlayerController.switchStream(videoQuality.url);
        success = result >= 0;
      }
      _observer?.onSwitchStreamStart(success, SuperPlayerType.LIVE, videoQuality);
    }
  }

  /// seek 到需要的时间点进行播放
  Future<void> seek(double progress) async {
    if (playerType == SuperPlayerType.VOD) {
      await _vodPlayerController.seek(progress);
      bool isPlaying = await _vodPlayerController.isPlaying();
      // resume when not playing.if isPlaying is null,not resume
      if (!isPlaying) {
        resume();
      }
    } else {
      _updatePlayerType(SuperPlayerType.LIVE_SHIFT);
      _livePlayerController.seek(progress);
      bool isPlaying = await _livePlayerController.isPlaying();
      // resume when not playing.if isPlaying is null,not resume
      if (!isPlaying) {
        resume();
      }
    }
    _observer?.onSeek(progress);
  }

  /// 配置点播播放器
  Future<void> setPlayConfig(FTXVodPlayConfig config) async {
    _vodConfig = config;
    await _vodPlayerController.setConfig(config);
  }

  /// 配置直播播放器
  Future<void> setLiveConfig(FTXLivePlayConfig config) async {
    _liveConfig = config;
    await _livePlayerController.setConfig(config);
  }

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  Future<int> enterPictureInPictureMode(
      {String? backIcon, String? playIcon, String? pauseIcon, String? forwardIcon}) async {
    if (_playerUIStatus == SuperPlayerUIStatus.WINDOW_MODE) {
      if (playerType == SuperPlayerType.VOD) {
        return _vodPlayerController.enterPictureInPictureMode(
            backIconForAndroid: backIcon,
            playIconForAndroid: playIcon,
            pauseIconForAndroid: pauseIcon,
            forwardIconForAndroid: forwardIcon);
      } else {
        return _livePlayerController.enterPictureInPictureMode(
            backIconForAndroid: backIcon,
            playIconForAndroid: playIcon,
            pauseIconForAndroid: pauseIcon,
            forwardIconForAndroid: forwardIcon);
      }
    }
    return TXVodPlayEvent.ERROR_PIP_CAN_NOT_ENTER;
  }

  /// 开关硬解编码播放
  Future<void> enableHardwareDecode(bool enable) async {
    _isOpenHWAcceleration = enable;
    if (playerType == SuperPlayerType.VOD) {
      await _vodPlayerController.enableHardwareDecode(enable);
      if (playerState != SuperPlayerState.END) {
        _changeHWAcceleration = true;
        _seekPos = await _vodPlayerController.getCurrentPlaybackTime();
        LogUtils.d(TAG, "seek pos $_seekPos");
        resetPlayer();
        // 当protocol为空时，则说明当前播放视频为非v2和v4视频
        if (_currentProtocol == null) {
          _playUrlVideo(videoModel);
        } else {
          _playModeVideo(_currentProtocol!);
        }
      }
    } else {
      await _vodPlayerController.enableHardwareDecode(enable);
      await playWithModel(videoModel!);
    }
  }

  Future<void> setPlayRate(double rate) async {
    currentPlayRate = rate;
    _vodPlayerController.setRate(rate);
  }

  /// 获得当前播放器状态
  SuperPlayerState getPlayerState() {
    return playerState;
  }
}
