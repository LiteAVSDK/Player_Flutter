part of SuperPlayer;

class QualityListView extends StatefulWidget {
  final List<VideoQuality>? _qualityList;
  final VideoQuality? _currentQuality;
  final _QualityListViewController _controller;

  QualityListView(this._controller, this._qualityList, this._currentQuality, Key key) : super(key: key);

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
        padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
        decoration: BoxDecoration(color: Color(ColorResource.COLOR_TRANS_BLACK)),
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
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        child: Text(
                          _qualityList![index].title,
                          textAlign: TextAlign.center,
                          style: _currentQuality == _qualityList![index]
                              ? TextStyle(fontSize: 12, color: Color(ColorResource.COLOR_MAIN_THEME))
                              : TextStyle(fontSize: 12, color: Colors.white),
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

class _QualityListViewController {
  Function(VideoQuality) onSwitchStream;

  _QualityListViewController(this.onSwitchStream);
}
