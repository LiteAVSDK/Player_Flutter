// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// Picture-in-picture state storage parameters.
/// 画中画状态存储参数
class TXPipPlayerData {
  /// Picture-in-picture player instance, only one can exist at the same time.
  /// 画中画播放器实例，同时只能存在一个
  final TXPlayerController _playerController;
  int playerMode = TXPlayerType.VOD_PLAY;
  bool isEnterPip = false;

  TXPipPlayerData(this._playerController) {
    playerMode = _playerController is TXVodPlayerController ? TXPlayerType.VOD_PLAY : playerMode = TXPlayerType.LIVE_PLAY;
  }
}
