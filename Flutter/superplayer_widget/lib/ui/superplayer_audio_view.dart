// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class AudioListView extends StatefulWidget {
  final AudioTrackController _controller;
  final List<TXTrackInfo>? _trackInfoList;
  final TXTrackInfo? _currentTrackInfo;
  AudioListView(this._controller, this._trackInfoList, this._currentTrackInfo, Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AudioListState();
  }
}

class AudioListState extends State<AudioListView> {
  List<TXTrackInfo>? _trackInfoList;
  TXTrackInfo? _currentTXTrackInfo;
  final TXTrackInfo closeItem = TXTrackInfo(FSPLocal.current.txAudioTrackClose, -1, 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _trackInfoList = List.from(widget._trackInfoList as Iterable);
    _trackInfoList?.add(closeItem);
    _currentTXTrackInfo = widget._currentTrackInfo;

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
          height: double.infinity,
          width: 300,
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
          decoration: const BoxDecoration(color: Color(ColorResource.COLOR_TRANS_BLACK)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(FSPLocal.current.txAudioTrackTitle, style: TextStyle(fontSize: 16, color: Colors.grey)),
              Expanded(
                  child: Center(
                child: _trackInfoList != null
                      ? ListView.builder(
                    itemCount: _trackInfoList?.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => widget._controller.onSelectAudioTrackInfo(_trackInfoList![index]),
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            getAudioName(_trackInfoList!, index),
                            textAlign: TextAlign.center,
                            style: getTexStyle(index),
                          ),
                        ),
                      );
                    })
                    : Container(),
              ))
            ],
          )),
    );
  }

  TextStyle getTexStyle(int index) {
    if ( _currentTXTrackInfo?.trackIndex == _trackInfoList![index].trackIndex) {
      return ThemeResource.getCheckedTextStyle();
    } else {
      return ThemeResource.getCommonTextStyle();
    }
  }

  String getAudioName(List<TXTrackInfo> trackData, int index) {
    TXTrackInfo trackInfo = trackData[index];
    String name = trackInfo.name;
    if (name.isEmpty) {
      name = FSPLocal.current.txAudioTrackTitleItem + "${trackInfo.trackIndex}";
    }
    return name;
  }

  void updateAudioTrack(List<TXTrackInfo>? trackDataList, TXTrackInfo? trackInfo) {
    if (_trackInfoList != trackDataList || _currentTXTrackInfo != trackInfo) {
      setState(() {
        _trackInfoList = trackDataList;
        _currentTXTrackInfo = trackInfo;
      });
    }
  }
}

class AudioTrackController {
  Function(TXTrackInfo) onSelectAudioTrackInfo;

  AudioTrackController(this.onSelectAudioTrackInfo);
}
