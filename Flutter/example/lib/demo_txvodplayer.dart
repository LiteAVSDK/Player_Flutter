// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/res/app_localizations.dart';
import 'package:superplayer_widget/demo_superplayer_lib.dart';
import 'ui/demo_inputdialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'ui/demo_volume_slider.dart';
import 'ui/demo_speed_slider.dart';
import 'ui/demo_bitrate_checkbox.dart';
import 'ui/demo_video_slider_view.dart';
import 'common/demo_config.dart';

class DemoTXVodPlayer extends StatefulWidget {
  @override
  _DemoTXVodPlayerState createState() => _DemoTXVodPlayerState();
}

class _DemoTXVodPlayerState extends State<DemoTXVodPlayer> with WidgetsBindingObserver {
  late TXVodPlayerController _controller;
  double _aspectRatio = 16 / 9;
  double _currentProgress = 0.0;
  bool _isMute = false;
  int _volume = 100;
  List _supportedBitrates = [];
  int _curBitrateIndex = 0;
  String _url = "http://1500005830.vod2.myqcloud.com/43843ec0vodtranscq1500005830/48d0f1f9387702299774251236/adp.10.m3u8";
  TXPlayInfoParams? _videoParams;
  int _appId = 0;
  String _fileId = "";
  double _rate = 1.0;
  bool enableHardware = false;
  int volume = 80;
  bool _isPlaying = false;
  StreamSubscription? playEventSubscription;
  StreamSubscription? playNetEventSubscription;
  FTXAndroidRenderViewType _renderType = FTXAndroidRenderViewType.TEXTURE_VIEW;

  GlobalKey<VideoSliderViewState> progressSliderKey = GlobalKey();

  Future<void> init() async {
    if (!mounted) return;
    await SuperPlayerPlugin.setConsoleEnabled(true);
    _controller.onPlayerState.listen((val) {
      debugPrint("Playback status ${val?.name}");
    });
    LogUtils.logOpen = true;


    playEventSubscription = _controller.onPlayerEventBroadcast.listen((event) async {
      // Subscribe to event distribution
      final int code = event["event"];
      if (code == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
        EasyLoading.dismiss();
        _supportedBitrates = (await _controller.getSupportedBitrates())!;
        _resizeVideo(event);
      } else if (code== TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        _isPlaying = true;
        _currentProgress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS].toDouble();
        double videoDuration = event[TXVodPlayEvent.EVT_PLAY_DURATION].toDouble(); // Total playback time, converted unit in seconds
        if (videoDuration == 0.0) {
          progressSliderKey.currentState?.updateProgress(0.0, 0.0);
        } else {
          progressSliderKey.currentState?.updateProgress(_currentProgress / videoDuration, videoDuration);
        }
      } else if (code == TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION) {
        _resizeVideo(event);
      } else if (code == TXVodPlayEvent.PLAY_EVT_PLAY_LOADING) {
        EasyLoading.show(status: "loading");
      } else if (code == TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END || code == TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN) {
        EasyLoading.dismiss();
      } else if (code != -100 && code < 0) {
        EasyLoading.showToast("playError:$event");
      }
    });

    await _controller.setLoop(true);
    await _controller.enableHardwareDecode(enableHardware);
    await _controller.setConfig(FTXVodPlayConfig());
    await _controller.setStartTime(0);

    if (!isLicenseSuc.isCompleted) {
      SuperPlayerPlugin.setGlobalLicense(LICENSE_URL, LICENSE_KEY);
      await isLicenseSuc.future;
      await _controller.startVodPlay(_url);
    } else {
      await _controller.startVodPlay(_url);
    }
  }

  void _resizeVideo(Map<dynamic, dynamic> event) {
    int? videoWidth = event[TXVodPlayEvent.EVT_PARAM1];
    int? videoHeight = event[TXVodPlayEvent.EVT_PARAM2];
    if ((videoWidth != null && videoWidth != 0) && (videoHeight != null && videoHeight != 0)) {
      setState(() {
        _aspectRatio = 1.0 * videoWidth / videoHeight;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // stop pip window if exists
    TXPipController.instance.exitAndReleaseCurrentPip();
    _controller = TXVodPlayerController();
    init();
    WidgetsBinding.instance.addObserver(this);
    EasyLoading.show(status: 'loading...');
  }

  @override
  Future didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    print("didChangeAppLifecycleState $state");
    switch (state) {
      case AppLifecycleState.inactive:
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_isPlaying) {
          _controller.resume();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage("images/ic_new_vod_bg.png"),
        fit: BoxFit.cover,
      )),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(AppLocals.current.playerVodPlayer),
        ),
        body: SafeArea(
            child: Container(
          child: Column(
            children: [
              Container(
                height: 220,
                color: Colors.black,
                child: Center(
                  child: _aspectRatio > 0
                      ? AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: TXPlayerVideo(
                            androidRenderType: _renderType,
                            onRenderViewCreatedListener: (viewId) {
                              _controller.setPlayerView(viewId);
                            },
                          ),
                        )
                      : Container(),
                ),
              ),
              VideoSliderView(_controller, progressSliderKey),
              Expanded(
                child: GridView.count(
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 30.0,
                  padding: EdgeInsets.all(10.0),
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  children: getFunctionWidgetList(),
                ),
              ),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 100,
                    child: IconButton(icon: Image.asset('images/addp.png'), onPressed: () => {onPressed()}),
                  )
                ],
              )),
            ],
          ),
        )),
      ),
    );
  }

  List<Widget> getFunctionWidgetList() {
    List<Widget> children = [
      _createItem(AppLocals.current.playerPlayback, () => _controller.resume()),
      _createItem(AppLocals.current.playerPause, () {
        _isPlaying = false;
        _controller.pause();
      }),
      _createItem(AppLocals.current.playerVariableSpeedPlay, () {onClickSetRate();}),
      _createItem(_isMute ? AppLocals.current.playerCancelMute : AppLocals.current.playerSetMute, () {
        setState(() {
          _isMute = !_isMute;
          _controller.setMute(_isMute);
        });
      }),
      _createItem(AppLocals.current.playerAdjustVolume, () {onClickVolume();}),
      _createItem(AppLocals.current.playerSwitchBitrate, () {
        if (_supportedBitrates.length > 1) {
          onClickBitrate();
        } else {
          EasyLoading.showError(AppLocals.current.playerNoOtherBitrate);
        }
      }),
      _createItem(AppLocals.current.playerPlaybackDuration, () async {
        double time = await _controller.getCurrentPlaybackTime();
        EasyLoading.showToast('${time.toStringAsFixed(2)}${AppLocals.current.playerSecond}');
      }),
      _createItem(AppLocals.current.playerVideoSize, () async {
        int width = await _controller.getWidth();
        int height = await _controller.getHeight();
        EasyLoading.showToast('width:$width,height:$height');
      }),
      _createItem(AppLocals.current.playerLoopStatus, () async {
        bool isLoop = await _controller.isLoop();
        EasyLoading.showToast('isLoop:$isLoop');
      }),
      _createItem(enableHardware ? AppLocals.current.playerSwitchSoft : AppLocals.current.playerSwitchHard, () async {
        TXPlayerState? state = _controller.playState;
        if (state != TXPlayerState.disposed && state != TXPlayerState.stopped) {
          enableHardware = !enableHardware;
          bool enableSuccess = await _controller.enableHardwareDecode(enableHardware);
          double startTime = await _controller.getCurrentPlaybackTime();
          await _controller.setStartTime(startTime);
          if (_url.isNotEmpty) {
            await _controller.startVodPlay(_url);
          } else if (null != _videoParams) {
            await _controller.startVodPlayWithParams(_videoParams!);
          } else {
            EasyLoading.showError("video source is not exists");
          }
          String wareMode = enableHardware ? AppLocals.current.playerHardEncode : AppLocals.current.playerSoftEncode;
          if (enableSuccess) {
            EasyLoading.showToast(AppLocals.current.playerSwitchSucTo.txFormat([wareMode]));
          } else {
            EasyLoading.showToast(AppLocals.current.playerSwitchFailedTo.txFormat([wareMode]));
          }
        } else {
          EasyLoading.showToast(AppLocals.current.playerPlayEnd);
        }
      }),
      _createItem(AppLocals.current.playerPlayableTime, () async {
        double time = await _controller.getPlayableDuration();
        EasyLoading.showToast(AppLocals.current.playerPlayableDurationTo.txFormat([time.toString()]));
      }),
    ];

    /// iOS does not have this capability.
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      children.add(_createItem(AppLocals.current.playerCacheTime, () async {
        double time = await _controller.getBufferDuration();
        EasyLoading.showToast('${time.toStringAsFixed(2)}${AppLocals.current.playerSecond}');
      }));
    }
    return children;
  }

  Widget _createItem(String name, GestureTapCallback tapBlock) {
    return InkWell(
      onTap: tapBlock,
      child: Container(
        child: Text(
          name,
          style: TextStyle(fontSize: 14, color: Colors.blue),
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }

  @override
  void dispose() {
    playNetEventSubscription?.cancel();
    playEventSubscription?.cancel();
    _controller.dispose();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    EasyLoading.dismiss();
  }

  void onPressed() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoInputDialog("", 0, "", (String url, int appId, String fileId, String pSign, bool enableDownload, bool isDrm) {
            _url = url;
            _appId = appId;
            _fileId = fileId;
            _controller.setStartTime(0);
            if (url.isNotEmpty) {
              _videoParams = null;
              _controller.startVodPlay(url);
            } else if (appId != 0 && fileId.isNotEmpty) {
              FTXAndroidRenderViewType dstRenderType = FTXAndroidRenderViewType.TEXTURE_VIEW;
              if (isDrm) {
                dstRenderType = FTXAndroidRenderViewType.DRM_SURFACE_VIEW;
              }
              if (dstRenderType != _renderType) {
                setState(() {
                  _renderType = dstRenderType;
                });
              }
              _controller.stop(isNeedClear: true);
              TXPlayInfoParams params = TXPlayInfoParams(appId: _appId, fileId: _fileId, psign: pSign != null ? pSign : "");
              _videoParams = params;
              _controller.startVodPlayWithParams(params);
            }
          }, needPisgn: true, needDrm: true,);
        });
  }

  void onClickVolume() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoVolumeSlider(_volume, (int result) {
            _volume = result;
            _controller.setAudioPlayoutVolume(_volume);
          });
        });
  }

  void onClickSetRate() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoSpeedSlider(_rate, (double result) {
            _rate = result;
            _controller.setRate(_rate);
          });
        });
  }

  void onClickBitrate() {
    showDialog(
        context: context,
        builder: (context) {
          return DemoBitrateCheckbox(_supportedBitrates, _curBitrateIndex, (int result) {
            _curBitrateIndex = result;
            _controller.setBitrateIndex(_curBitrateIndex);
            EasyLoading.showSuccess(AppLocals.current.playerSwitchSuc);
          });
        });
  }
}
