// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

abstract class TXPlayerController {
  Future<int> get textureId;
  double? get resizeVideoWidth;
  double? get resizeVideoHeight;
  double? get videoLeft;
  double? get videoTop;
  double? get videoRight;
  double? get videoBottom;
  TXPlayerValue? playerValue();

  Future<void> initialize({bool? onlyAudio});
  Future<bool> stop({bool isNeedClear = false});
  Future<bool> isPlaying();
  Future<void> pause();
  Future<void> resume();
  Future<void> setMute(bool mute);
  Future<bool> enableHardwareDecode(bool enable);
  Future<int> enterPictureInPictureMode(
      {String? backIconForAndroid, String? playIconForAndroid, String? pauseIconForAndroid, String? forwardIconForAndroid});
  Future<void> exitPictureInPictureMode();
  Future<void> dispose();
}