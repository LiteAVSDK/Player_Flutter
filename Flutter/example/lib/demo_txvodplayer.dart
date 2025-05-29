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
  bool enableHardware = true;
  int volume = 80;
  bool _isPlaying = false;
  StreamSubscription? playEventSubscription;
  StreamSubscription? playNetEventSubscription;
  FTXAndroidRenderViewType _renderType = FTXAndroidRenderViewType.TEXTURE_VIEW;
  FTXPlayerRenderMode _renderMode = FTXPlayerRenderMode.ADJUST_RESOLUTION;

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
      } else if (code== TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        _isPlaying = true;
        _currentProgress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS].toDouble();
        double videoDuration = event[TXVodPlayEvent.EVT_PLAY_DURATION].toDouble(); // Total playback time, converted unit in seconds
        if (videoDuration == 0.0) {
          progressSliderKey.currentState?.updateProgress(0.0, 0.0);
        } else {
          progressSliderKey.currentState?.updateProgress(_currentProgress / videoDuration, videoDuration);
        }
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
    await _controller.setRenderMode(_renderMode);
    if (!isLicenseSuc.isCompleted) {
      SuperPlayerPlugin.setGlobalLicense(LICENSE_URL, LICENSE_KEY);
      await isLicenseSuc.future;
      await _controller.startVodPlay(_url);
    } else {
      await _controller.startVodPlay(_url);
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
                height: 230,
                color: Colors.black,
                child: Center(
                  child:Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: TXPlayerVideo(
                      androidRenderType: _renderType,
                      onRenderViewCreatedListener: (viewId) {
                        /// 此处只展示了最基础的纹理和播放器的配置方式。 这里可记录下来 viewId，在多纹理之间进行切换，比如横竖屏切换场景，竖屏的画面，
                        /// 要切换到横屏的画面，可以在切换到横屏之后，拿到横屏的viewId 设置上去。回到竖屏的时候，再通过 viewId 切换回来。
                        /// Only the most basic configuration methods for textures and the player are shown here.
                        /// The `viewId` can be recorded here to switch between multiple textures. For example, in the scenario
                        /// of switching between portrait and landscape orientations:
                        /// To switch from the portrait view to the landscape view, obtain the `viewId` of the landscape view
                        /// after switching to landscape orientation and set it.  When switching back to portrait orientation,
                        /// switch back using the recorded `viewId`.
                        _controller.setPlayerView(viewId);
                      },
                    ),
                  )
                ),
              ),
              VideoSliderView(_controller, progressSliderKey),
              Expanded(
                child: GridView.count(
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 30.0,
                  padding: EdgeInsets.all(10.0),
                  crossAxisCount: 5,
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
          setState(() {});
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
      _createItem(_renderMode == FTXPlayerRenderMode.ADJUST_RESOLUTION
          ? AppLocals.current.playerRenderModeAdjust
          : AppLocals.current.playerRenderModeFill, () async {
        if (_renderMode == FTXPlayerRenderMode.ADJUST_RESOLUTION) {
          _renderMode = FTXPlayerRenderMode.FULL_FILL_CONTAINER;
        } else {
          _renderMode = FTXPlayerRenderMode.ADJUST_RESOLUTION;
        }
        _controller.setRenderMode(_renderMode);
        setState(() {});
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
            FTXAndroidRenderViewType dstRenderType;
            if (isDrm) {
              dstRenderType = FTXAndroidRenderViewType.DRM_SURFACE_VIEW;
            } else {
              dstRenderType = _renderType;
            }
            if (dstRenderType != _renderType) {
              setState(() {
                _renderType = dstRenderType;
              });
            }
            if (url.isNotEmpty) {
              _videoParams = null;
              _controller.startVodPlay(url);
            } else if (appId != 0 && fileId.isNotEmpty) {
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
