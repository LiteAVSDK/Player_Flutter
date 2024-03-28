// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class AudioListView extends StatefulWidget {
  final AudioTrackController _controller;

  AudioListView(this._controller);

  @override
  State<StatefulWidget> createState() {
    return AudioListState();
  }
}

class AudioListState extends State<AudioListView> {
  @override
  Widget build(BuildContext context) {
    List<FTXTrackInfo> trackData = List.from(widget._controller.audioTrackData);
    trackData.add(FTXTrackInfo(FSPLocal.current.txAudioTrackClose, -1, 0));
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
                child: ListView.builder(
                    itemCount: trackData.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => selectTrackInfo(trackData[index]),
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            getAudioName(trackData, index),
                            textAlign: TextAlign.center,
                            style: widget._controller.compareTrackWithCurrent(trackData[index])
                                ? ThemeResource.getCheckedTextStyle()
                                : ThemeResource.getCommonTextStyle(),
                          ),
                        ),
                      );
                    }),
              ))
            ],
          )),
    );
  }

  String getAudioName(List<FTXTrackInfo> trackData, int index) {
    FTXTrackInfo trackInfo = trackData[index];
    String name = trackInfo.name;
    if (name.isEmpty) {
      name = FSPLocal.current.txAudioTrackTitleItem + "${trackInfo.trackIndex}";
    }
    return name;
  }

  void selectTrackInfo(FTXTrackInfo trackInfo) {
    widget._controller.currentTrackInfo = trackInfo;
    for (Function(FTXTrackInfo) listener in widget._controller.onSwitchAudioTrack) {
      listener(trackInfo);
    }
  }
}
