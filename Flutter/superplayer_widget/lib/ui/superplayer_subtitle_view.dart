// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class SubtitleListView extends StatefulWidget {
  final SubtitleTrackController _controller;
  final List<TXTrackInfo>? _trackInfoList;
  final TXTrackInfo? _currentTrackInfo;

  SubtitleListView(this._controller, this._trackInfoList, this._currentTrackInfo, Key key)
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SubtitleListState();
  }
}

class _SubtitleListState extends State<SubtitleListView> {
  bool _isShowSetting = false;

  static const defaultFontColor = SubtitleTrackController.defaultFontColor;
  static const defaultFontSize = SubtitleTrackController.defaultFontSize;
  static const defaultFondBold = SubtitleTrackController.defaultFondBold;
  static const defaultOutlineWidth = SubtitleTrackController.defaultOutlineWidth;
  static const defaultOutlineColor = SubtitleTrackController.defaultOutlineColor;

  int styleFontColor = defaultFontColor;
  double styleFontSize = defaultFontSize;
  String styleFondBold = defaultFondBold;
  double styleOutlineWidth = defaultOutlineWidth;
  int styleOutlineColor = defaultOutlineColor;

  List<TXTrackInfo>? _trackInfoList;
  TXTrackInfo? _currentTXTrackInfo;
  final TXTrackInfo closeItem = TXTrackInfo(FSPLocal.current.txSubtitleTitleClose, -1, 0);

  List<DropdownMenuItem<int>> _colorSettingList = [
    DropdownMenuItem(
      child: Text("White", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFFFFFFFF,
    ),
    DropdownMenuItem(
      child: Text("Black", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFF000000,
    ),
    DropdownMenuItem(
      child: Text("Red", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFFFF0000,
    ),
    DropdownMenuItem(
      child: Text("Blue", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFF87CEEB,
    ),
    DropdownMenuItem(
      child: Text("Green", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFF90EE90,
    ),
    DropdownMenuItem(
      child: Text("Yellow", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFFFFFF00,
    ),
    DropdownMenuItem(
      child: Text("Magenta", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFFCD5C5C,
    ),
    DropdownMenuItem(
      child: Text("Cyan", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0xFFE0FFFF,
    ),
  ];

  List<DropdownMenuItem<int>> _fontSizeSettingList = [12,14,16,18,20,22,24,26,28].map((fontSize){
    return DropdownMenuItem(
      child: Text("$fontSize", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: fontSize,
    );
  }).toList(growable: false);


  List<DropdownMenuItem<String>> _fontBoldSettingList = [
    DropdownMenuItem(
      child: Text("Normal", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: "0",
    ),
    DropdownMenuItem(
      child: Text("BoldFace", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: "1",
    ),
  ];

  List<DropdownMenuItem<double>> _outLineWidthSettingList = [
    DropdownMenuItem(
      child: Text("50%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0.5,
    ),
    DropdownMenuItem(
      child: Text("75%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 0.75,
    ),
    DropdownMenuItem(
      child: Text("100%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 1.00,
    ),
    DropdownMenuItem(
      child: Text("125%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 1.25,
    ),
    DropdownMenuItem(
      child: Text("150%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 1.50,
    ),
    DropdownMenuItem(
      child: Text("175%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 1.75,
    ),
    DropdownMenuItem(
      child: Text("200%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 2.00,
    ),
    DropdownMenuItem(
      child: Text("300%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 3.00,
    ),
    DropdownMenuItem(
      child: Text("400%", style: TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME))),
      value: 4.00,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
          height: double.infinity,
          width: 300,
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
          decoration: const BoxDecoration(color: Color(ColorResource.COLOR_TRANS_BLACK)),
          child: _isShowSetting ? _buildSubtitleStyle() : _buildSubtitleList()),
    );
  }

  Widget _buildSubtitleStyle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            InkWell(
              onTap: _onTapBackBtn,
              child: Container(
                padding: EdgeInsets.all(3),
                width: 30,
                height: 30,
                child: const Image(
                  image: AssetImage("images/superplayer_btn_back_play.png", package: PlayerConstants.PKG_NAME),
                ),
              ),
            ),
            Text("setting", style: TextStyle(fontSize: 16, color: Colors.grey))
          ],
        ),
        Expanded(
          child: getSettingItem("Font Color", _colorSettingList, styleFontColor, (p0) {
            setState(() {
              styleFontColor = p0 as int;
            });
          }),
        ),
        Expanded(
          child: getSettingItem("Font Size", _fontSizeSettingList, styleFontSize, (p0) {
            setState(() {
              styleFontSize = (p0 as int).toDouble();
            });
          }),
        ),
        Expanded(
          child: getSettingItem("Bold Font", _fontBoldSettingList, styleFondBold, (p0) {
            setState(() {
              styleFondBold = p0 as String;
            });
          }),
        ),
        Expanded(
          child: getSettingItem("Outline Width", _outLineWidthSettingList, styleOutlineWidth, (p0) {
            setState(() {
              styleOutlineWidth = p0 as double;
            });
          }),
        ),
        Expanded(
          child: getSettingItem("Outline Color", _colorSettingList, styleOutlineColor, (p0) {
            setState(() {
              styleOutlineColor = p0 as int;
            });
          }),
        ),
        Divider(
          color: Colors.grey,
          height: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
              onPressed: _onTapSettingDone,
              child: Text("Done", style: TextStyle(fontSize: 12, color: Colors.white)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.white, width: 1),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7)))),
            ),
            OutlinedButton(
              onPressed: _onResetSetting,
              child: Text("Reset", style: TextStyle(fontSize: 12, color: Colors.white)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.white, width: 1),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7)))),
            )
          ],
        )
      ],
    );
  }

  Widget getSettingItem(String labelName, List<DropdownMenuItem<Object>> valueList, Object initValue, Function(Object?) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(child: Center(child: Text(labelName, style: TextStyle(fontSize: 16, color: Colors.white))), fit: FlexFit.tight),
            Flexible(
              child: Center(child: DropdownButton(value: initValue, items: valueList, onChanged: onChanged)),
              fit: FlexFit.tight,
            )
          ],
        )
      ],
    );
  }

  Widget _buildSubtitleList() {
    _trackInfoList = List.from(widget._trackInfoList as Iterable);
    _trackInfoList?.add(closeItem);
    _currentTXTrackInfo = widget._currentTrackInfo;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Center(
              child: Text(FSPLocal.current.txSubtitleTitle, style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            Positioned(
                right: 5,
                top: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _onTapSetting,
                  child: const Image(
                    width: 30,
                    height: 30,
                    image: AssetImage("images/superplayer_setting.png", package: PlayerConstants.PKG_NAME),
                  ),
                )),
          ],
        ),
        Expanded(
            child: Center(
          child: ListView.builder(
              itemCount: _trackInfoList?.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => widget._controller.onSelectSubtitleTrackInfo(_trackInfoList![index]),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      _trackInfoList![index].name,
                      textAlign: TextAlign.center,
                      style:  getTexStyle(index),
                    ),
                  ),
                );
              }),
        ))
      ],
    );
  }

  TextStyle getTexStyle(int index) {
    if ( _currentTXTrackInfo?.trackIndex == _trackInfoList![index].trackIndex) {
      return ThemeResource.getCheckedTextStyle();
    } else {
      return ThemeResource.getCommonTextStyle();
    }
  }

  void updateSubtitleTrack(List<TXTrackInfo>? trackDataList, TXTrackInfo? trackInfo) {
    if (_trackInfoList != trackDataList || _currentTXTrackInfo != trackInfo) {
      setState(() {
        _trackInfoList = trackDataList;
        _currentTXTrackInfo = trackInfo;
      });
    }
  }

  void _onTapSettingDone() {
    setState(() {
      _isShowSetting = false;
    });
    _fireRenderModelChange();
  }

  void _onResetSetting() {
    setState(() {
      styleFontColor = defaultFontColor;
      styleFontSize = defaultFontSize;
      styleFondBold = defaultFondBold;
      styleOutlineWidth = defaultOutlineWidth;
      styleOutlineColor = defaultOutlineColor;
      _isShowSetting = false;
    });
    _fireRenderModelChange();
  }

  void _fireRenderModelChange() {
    TXSubtitleRenderModel renderModel = TXSubtitleRenderModel();
    renderModel.outlineWidth = styleOutlineWidth;
    renderModel.outlineColor = styleOutlineColor;
    renderModel.fontColor = styleFontColor;
    renderModel.fontSize = styleFontSize;
    renderModel.isBondFontStyle = styleFondBold == "1";
    widget._controller.onSubtitleRenderModelChange(renderModel);
  }

  void _onTapBackBtn() {
    setState(() {
      _isShowSetting = false;
    });
  }

  void _onTapSetting() {
    setState(() {
      _isShowSetting = true;
    });
  }
}


class SubtitleTrackController {

  static const defaultFontColor = 0xFFFFFFFF;
  static const defaultFontSize = 20.0;
  static const defaultFondBold = "0";
  static const defaultOutlineWidth = 1.00;
  static const defaultOutlineColor = 0xFF000000;

  Function(TXTrackInfo) onSelectSubtitleTrackInfo;
  Function(TXSubtitleRenderModel) onSubtitleRenderModelChange;

  SubtitleTrackController(this.onSelectSubtitleTrackInfo, this.onSubtitleRenderModelChange);
}
