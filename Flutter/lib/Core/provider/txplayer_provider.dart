// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

abstract class TXModel extends ChangeNotifier {
}

class TXPlayerModelImpl extends TXModel {
  TXPlayerController controller;

  TXPlayerModelImpl(this.controller);

  void updateController(TXPlayerController playerController) {
    controller = playerController;
    notifyListeners();
  }
}
