// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_short_video_player_lib;

class ShortVideoDataLoader {
  List<SuperPlayerModel> _currentModels = [];
  int _appId = 1500005830;
  var _fileIdArray = [
    "387702294394366256",
    "387702294394228858",
    "387702294394228636",
    "387702294394228527",
    "387702294167066523",
    "387702294167066515",
    "387702294168748446",
    "387702294394227941"
  ];
  List<SuperPlayerModel> _defaultData = [];

  SuperVodDataLoader _loader = SuperVodDataLoader();

  getPageListDataOneByOneFunction(Function(List<SuperPlayerModel> model) callback) {
    _currentModels.clear();
    for (int i = 0; i < _fileIdArray.length; i++) {
      SuperPlayerModel model = new SuperPlayerModel();
      model.appId = _appId;
      model.videoId = new SuperPlayerVideoId();
      model.videoId?.fileId = _fileIdArray[i];
      _defaultData.add(model);
    }

    List<Future<void>> requestList = [];
    for (var model in _defaultData) {
      requestList.add(_getVodListData(model, callback));
    }
    Future.wait(requestList).then((value) => callback(_currentModels));
  }

  Future<void> _getVodListData(SuperPlayerModel model, Function(List<SuperPlayerModel> models) callback) async {
    await _loader.getVideoData(model, (resultModel) {
      _currentModels.add(resultModel);
    });
  }
}

