// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

typedef BoolFunction = bool Function();
typedef DoubleFunction = double Function();
/// 超级播放器更多菜单
class SuperPlayerMoreView extends StatefulWidget {
  _MoreViewController controller;

  SuperPlayerMoreView(this.controller, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SuperPlayerMoreViewState();
}

class _SuperPlayerMoreViewState extends State<SuperPlayerMoreView> {
  double _currentBrightness = 0.01;
  double _currentVolumn = 0;
  bool _isShowMoreView = false;
  bool _isOpenAccelerate = true;
  bool _isVodPlay = false;
  String _currentRate = "";
  Map<String, double> playRateStr = {"1.0x": 1.0, "1.25x": 1.25, "1.5x": 1.5, "2.0x": 2.0};
  StreamSubscription? volumeSubscription;

  @override
  void initState() {
    super.initState();
    _isVodPlay = widget.controller.getIsVodPlay();
    double playerPlayRate = widget.controller.getPlayRate();
    for(String rateStr in playRateStr.keys) {
      if(playerPlayRate == playRateStr[rateStr]) {
        _currentRate = rateStr;
        break;
      }
    }
    // if not found in playRateStr,set 1.0
    if(_currentRate.isEmpty) {
      _currentRate = playRateStr.keys.first;
    }
    _isOpenAccelerate = widget.controller.getAccelerateIsOpen();
    // regist system volume changed event
    volumeSubscription = SuperPlayerPlugin.instance.onEventBroadcast.listen((event) {
      int code = event["event"];
      if(mounted) {
        if (code == TXVodPlayEvent.EVENT_VOLUME_CHANGED) {
          refreshVolume();
        }
      }
    });
    _initData();
  }

  void refreshVolume() async {
    _currentVolumn = await SuperPlayerPlugin.getSystemVolume();
    setState(() {});
  }

  void _initData() async {
    double tempBrightness = await SuperPlayerPlugin.getBrightness();
    if (tempBrightness == -1) {
      _onChangeBrightness(1);
    } else {
      _currentBrightness = tempBrightness;
    }
    _currentVolumn = await SuperPlayerPlugin.getSystemVolume();
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
              padding: EdgeInsets.only(left: 15, right: 20, top: 15, bottom: 15),
              decoration: BoxDecoration(color: Color(ColorResource.COLOR_TRANS_BLACK)),
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
      margin: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Text(
            StringResource.HARDWARE_ACCE_LABEL,
            textAlign: TextAlign.center,
            style: ThemeResource.getCommonLabelTextStyle(),
          ),
          Switch(
              activeColor: Color(ColorResource.COLOR_MAIN_THEME),
              value: _isOpenAccelerate,
              onChanged: _onChangeAccelerate)
        ],
      ),
    );
  }

  Widget _getPlayRateWidget() {
    List<Widget> playRateChild = [
      Text(
        StringResource.MULITIPE_SPEED_PLAY_LABEL,
        textAlign: TextAlign.center,
        style: ThemeResource.getCommonLabelTextStyle(),
      )
    ];
    for (String rateStr in playRateStr.keys) {
      playRateChild.add(Container(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: InkWell(
          onTap: () => _onChangePlayRate(rateStr),
          child: Text(
            rateStr,
            textAlign: TextAlign.center,
            style: rateStr == _currentRate ? ThemeResource.getCheckedLabelTextStyle() : ThemeResource.getCommonLabelTextStyle(),
          ),
        ),
      ));
    }
    return Visibility(
      visible: _isVodPlay,
      child: Container(
        margin: EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: playRateChild,
        ),
      ),
    );
  }

  Widget _getBrightnessWidget() {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(children: [
        Text(
          StringResource.BRIGHTNESS_LABEL,
          textAlign: TextAlign.center,
          style: ThemeResource.getCommonLabelTextStyle(),
        ),
        Image(width: 30, height: 30, image: AssetImage("images/superplayer_ic_light_min.png")),
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
        Image(width: 30, height: 30, image: AssetImage("images/superplayer_ic_light_max.png")),
      ]),
    );
  }

  Widget _getVolumeWidget() {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Text(
            StringResource.VOICE_LABEL,
            textAlign: TextAlign.center,
            style: ThemeResource.getCommonLabelTextStyle(),
          ),
          Image(width: 30, height: 30, image: AssetImage("images/superplayer_ic_volume_min.png")),
          Expanded(
            child: Theme(
                data: ThemeResource.getCommonSliderTheme(),
                child: Slider(
                  min: 0,
                  max: 1,
                  value: _currentVolumn,
                  onChanged: _onChangeVolume,
                )),
          ),
          Image(width: 30, height: 30, image: AssetImage("images/superplayer_ic_volume_max.png")),
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
    if (_currentVolumn != value) {
      setState(() {
        _currentVolumn = value;
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
    if(isVodPlay != _isVodPlay) {
      setState(() {
        _isVodPlay = isVodPlay;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    volumeSubscription?.cancel();
  }
}

class _MoreViewController {
  BoolFunction getAccelerateIsOpen;
  DoubleFunction getPlayRate;
  Function(bool value) siwtchAccelerate;
  Function(double playRate) onChangedPlayRate;
  BoolFunction getIsVodPlay;

  _MoreViewController(this.getAccelerateIsOpen, this.getPlayRate, this.siwtchAccelerate, this.onChangedPlayRate, this.getIsVodPlay);
}
