// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class QualityListView extends StatefulWidget {
  final List<VideoQuality>? _qualityList;
  final VideoQuality? _currentQuality;
  final QualityListViewController _controller;

  const QualityListView(this._controller, this._qualityList, this._currentQuality, Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QualityListViewState();
}

class _QualityListViewState extends State<QualityListView> {
  List<VideoQuality>? _qualityList;
  VideoQuality? _currentQuality;

  @override
  void initState() {
    super.initState();
    _qualityList = widget._qualityList;
    _currentQuality = widget._currentQuality;
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
        child: Center(
          child: null != _qualityList
              ? ListView.builder(
                  itemCount: null != _qualityList ? _qualityList!.length : 0,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => widget._controller.onSwitchStream(_qualityList![index]),
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Text(
                          _qualityList![index].title,
                          textAlign: TextAlign.center,
                          style: _currentQuality == _qualityList![index]
                              ? ThemeResource.getCheckedTextStyle()
                              : ThemeResource.getCommonTextStyle(),
                        ),
                      ),
                    );
                  })
              : Container(),
        ),
      ),
    );
  }

  void updateQuality(List<VideoQuality>? qualities, VideoQuality? quality) {
    if (_qualityList != qualities || _currentQuality != quality) {
      setState(() {
        _qualityList = qualities;
        _currentQuality = quality;
      });
    }
  }
}

class QualityListViewController {
  Function(VideoQuality) onSwitchStream;

  QualityListViewController(this.onSwitchStream);
}
