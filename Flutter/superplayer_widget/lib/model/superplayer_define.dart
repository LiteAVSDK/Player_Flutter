// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

enum SuperPlayerState {
  INIT,       // Initial state
  PLAYING,    // Playing
  PAUSE,      // Paused
  LOADING,    // Buffering
  END,         // Playback finished
}

enum SuperPlayerType {
  VOD,        // VOD (Video on Demand)
  LIVE,       // Live streaming
  LIVE_SHIFT  // Live streaming playback
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
  static const onStartFullScreenPlay = "onStartFullScreenPlay"; // Enter full screen playback
  static const onStopFullScreenPlay = "onStopFullScreenPlay"; // Exit full screen playback
  static const onSuperPlayerDidStart = "onSuperPlayerDidStart"; // Playback start notification
  static const onSuperPlayerDidEnd = "onSuperPlayerDidEnd"; // Playback end notification
  static const onSuperPlayerError = "onSuperPlayerError"; // Playback error notification
  static const onSuperPlayerBackAction = "onSuperPlayerBackAction"; // Back event
}

/// Current layout state of the player plugin.
/// 播放器插件当前所处的布局状态
class SuperPlayerUIStatus {
  static const WINDOW_MODE = 0;
  static const FULLSCREEN_MODE = 1;
  static const PIP_MODE = 2;
}

/// super player render mode
enum SuperPlayerRenderMode {
  FILL_VIEW,
  ADJUST_RESOLUTION
}


