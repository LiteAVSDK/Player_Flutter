// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

typedef BoolFunction = bool Function();
typedef DoubleFunction = double Function();

/// Player component more menu.
/// 播放器组件更多菜单
class SuperPlayerMoreView extends StatefulWidget {
  final MoreViewController controller;

  const SuperPlayerMoreView(this.controller, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SuperPlayerMoreViewState();
}

class _SuperPlayerMoreViewState extends State<SuperPlayerMoreView> {
  double _currentBrightness = 0.01;
  double _currentVolume = 0;
  bool _isShowMoreView = false;
  bool _isOpenAccelerate = true;
  bool _isVodPlay = false;
  String _currentRate = "";
  Map<String, double> playRateStr = {"1.0x": 1.0, "1.25x": 1.25, "1.5x": 1.5, "2.0x": 2.0};
  StreamSubscription? eventSubscription;

  @override
  void initState() {
    super.initState();
    _isVodPlay = widget.controller.getIsVodPlay();
    double playerPlayRate = widget.controller.getPlayRate();
    for (String rateStr in playRateStr.keys) {
      if (playerPlayRate == playRateStr[rateStr]) {
        _currentRate = rateStr;
        break;
      }
    }
    // if not found in playRateStr,set 1.0
    if (_currentRate.isEmpty) {
      _currentRate = playRateStr.keys.first;
    }
    _isOpenAccelerate = widget.controller.getAccelerateIsOpen();
    // regist system volume changed event
    eventSubscription = SuperPlayerPlugin.instance.onEventBroadcast.listen((event) {
      int code = event["event"];
      if (mounted) {
        if (code == TXVodPlayEvent.EVENT_VOLUME_CHANGED) {
          refreshVolume();
        } else if (code == TXVodPlayEvent.EVENT_BRIGHTNESS_CHANGED) {
          refreshBrightness();
        }
      }
    });
    _initData();
  }

  void refreshVolume() async {
    _currentVolume = await SuperPlayerPlugin.getSystemVolume() ?? _currentVolume;
    setState(() {});
  }

  void refreshBrightness() async {
    double? brightness = await SuperPlayerPlugin.getBrightness();
    if (_currentBrightness != brightness) {
      if (_currentBrightness > 1) {
        _currentBrightness = 1;
      }
      if (_currentBrightness < 0) {
        _currentBrightness = 0;
      }
      setState(() {
        _currentBrightness = brightness ?? _currentBrightness;
      });
    }
  }

  void _initData() async {
    double? tempBrightness = await SuperPlayerPlugin.getBrightness();
    if (tempBrightness == -1) {
      _onChangeBrightness(1);
    } else {
      _currentBrightness = tempBrightness ?? _currentBrightness;
      if (_currentBrightness > 1) {
        _currentBrightness = 1;
      }
      if (_currentBrightness < 0) {
        _currentBrightness = 0;
      }
    }
    _currentVolume = await SuperPlayerPlugin.getSystemVolume() ?? _currentVolume;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: _isShowMoreView,
        child: Positioned(
          right: 0,
          bottom: 0,
          top: 0,
          child: Container(
              height: double.infinity,
              width: 320,
              padding: const EdgeInsets.only(left: 15, right: 20, top: 15, bottom: 15),
              decoration: const BoxDecoration(color: Color(ColorResource.COLOR_TRANS_BLACK)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getVolumeWidget(),
                    _getBrightnessWidget(),
                    _getPlayRateWidget(),
                    _getSwitchHardwareWidget(),
                  ],
                ),
              )),
        ));
  }

  Widget _getSwitchHardwareWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Text(
            FSPLocal.current.txSpwMultiPlay,
            textAlign: TextAlign.center,
            style: ThemeResource.getCommonLabelTextStyle(),
          ),
          Switch(
              activeColor: const Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
              value: _isOpenAccelerate,
              onChanged: _onChangeAccelerate)
        ],
      ),
    );
  }

  Widget _getPlayRateWidget() {
    List<Widget> playRateChild = [
      Text(
        FSPLocal.current.txSpwMultiPlay,
        textAlign: TextAlign.center,
        style: ThemeResource.getCommonLabelTextStyle(),
      )
    ];
    for (String rateStr in playRateStr.keys) {
      playRateChild.add(Container(
        padding: const EdgeInsets.only(left: 5, right: 5),
        child: InkWell(
          onTap: () => _onChangePlayRate(rateStr),
          child: Text(
            rateStr,
            textAlign: TextAlign.center,
            style: rateStr == _currentRate
                ? ThemeResource.getCheckedLabelTextStyle()
                : ThemeResource.getCommonLabelTextStyle(),
          ),
        ),
      ));
    }
    return Visibility(
      visible: _isVodPlay,
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: playRateChild,
        ),
      ),
    );
  }

  Widget _getBrightnessWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(children: [
        Text(
          FSPLocal.current.txSpwBrightness,
          textAlign: TextAlign.center,
          style: ThemeResource.getCommonLabelTextStyle(),
        ),
        const Image(
            width: 30,
            height: 30,
            image: AssetImage("images/superplayer_ic_light_min.png", package: PlayerConstants.PKG_NAME)),
        Expanded(
          child: Theme(
              data: ThemeResource.getCommonSliderTheme(),
              child: Slider(
                min: 0,
                max: 1,
                value: _currentBrightness,
                onChanged: _onChangeBrightness,
              )),
        ),
        const Image(
            width: 30,
            height: 30,
            image: AssetImage("images/superplayer_ic_light_max.png", package: PlayerConstants.PKG_NAME)),
      ]),
    );
  }

  Widget _getVolumeWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Text(
            FSPLocal.current.txSpwSound,
            textAlign: TextAlign.center,
            style: ThemeResource.getCommonLabelTextStyle(),
          ),
          const Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_volume_min.png", package: PlayerConstants.PKG_NAME)),
          Expanded(
            child: Theme(
                data: ThemeResource.getCommonSliderTheme(),
                child: Slider(
                  min: 0,
                  max: 1,
                  value: _currentVolume,
                  onChanged: _onChangeVolume,
                )),
          ),
          const Image(
              width: 30,
              height: 30,
              image: AssetImage("images/superplayer_ic_volume_max.png", package: PlayerConstants.PKG_NAME)),
        ],
      ),
    );
  }

  void _onChangePlayRate(String rateKey) {
    if (_currentRate != rateKey) {
      setState(() {
        _currentRate = rateKey;
      });
      double rate = playRateStr[_currentRate]!;
      widget.controller.onChangedPlayRate(rate);
    }
  }

  void _onChangeBrightness(double value) {
    if (_currentBrightness != value) {
      setState(() {
        _currentBrightness = value;
      });
      SuperPlayerPlugin.setBrightness(value);
    }
  }

  void _onChangeVolume(double value) {
    if (_currentVolume != value) {
      setState(() {
        _currentVolume = value;
      });
      SuperPlayerPlugin.setSystemVolume(value);
    }
  }

  void _onChangeAccelerate(bool value) {
    if (value != _isOpenAccelerate) {
      setState(() {
        _isOpenAccelerate = value;
      });
      widget.controller.siwtchAccelerate(value);
    }
  }

  void toggleShowMoreView() {
    setState(() {
      _isShowMoreView = !_isShowMoreView;
    });
  }

  void hideShowMoreView() {
    if (_isShowMoreView) {
      setState(() {
        _isShowMoreView = false;
      });
    }
  }

  void updatePlayerType(SuperPlayerType playerType) {
    bool isVodPlay = playerType == SuperPlayerType.VOD;
    if (isVodPlay != _isVodPlay) {
      setState(() {
        _isVodPlay = isVodPlay;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    eventSubscription?.cancel();
  }
}

class MoreViewController {
  BoolFunction getAccelerateIsOpen;
  DoubleFunction getPlayRate;
  Function(bool value) siwtchAccelerate;
  Function(double playRate) onChangedPlayRate;
  BoolFunction getIsVodPlay;

  MoreViewController(
      this.getAccelerateIsOpen, this.getPlayRate, this.siwtchAccelerate, this.onChangedPlayRate, this.getIsVodPlay);
}
