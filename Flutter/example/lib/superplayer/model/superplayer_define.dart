// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

enum SuperPlayerState {
  INIT,       // 初始状态
  PLAYING,    // 播放中
  PAUSE,      // 暂停中
  LOADING,    // 缓冲中
  END,         // 播放结束
}

enum SuperPlayerType {
  VOD,        // 点播
  LIVE,       // 直播
  LIVE_SHIFT  // 直播回
}

class EncryptedURLType {

  static const SIMPLEAES = EncryptedURLType("SimpleAES");
  static const WIDEVINE = EncryptedURLType("widevine");

  final String value;
  const EncryptedURLType(this.value);
}

class SuperPlayerCode {
   static const OK                       = 0;
   static const NET_ERROR                = 10001;
   static const PLAY_URL_EMPTY           = 20001;
   static const LIVE_PLAY_END            = 30001;
   static const LIVE_SHIFT_FAIL          = 30002;
   static const VOD_PLAY_FAIL            = 40001;
   static const VOD_REQUEST_FILE_ID_FAIL = 40002;
}

class SuperPlayerViewEvent {
  static const onStartFullScreenPlay = "onStartFullScreenPlay"; //进入全屏播放
  static const onStopFullScreenPlay = "onStopFullScreenPlay"; //退出全屏播放
  static const onSuperPlayerDidStart = "onSuperPlayerDidStart"; //播放开始通知
  static const onSuperPlayerDidEnd = "onSuperPlayerDidEnd"; //播放结束通知
  static const onSuperPlayerError = "onSuperPlayerError"; //播放错误通知
  static const onSuperPlayerBackAction = "onSuperPlayerBackAction"; //返回事件
}

/// 播放器插件当前所处的布局状态
class SuperPlayerUIStatus {
  static const WINDOW_MODE = 0;
  static const FULLSCREEN_MODE = 1;
  static const PIP_MODE = 2;
}


