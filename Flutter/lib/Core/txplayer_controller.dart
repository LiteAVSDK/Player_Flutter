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

  Future<bool> startPlay(String url);
  Future<void> initialize({bool? onlyAudio});
  Future<void> setAutoPlay({bool? isAutoPlay});
  Future<bool> stop({bool isNeedClear = false});
  Future<bool> isPlaying();
  Future<void> pause();
  Future<void> resume();
  Future<void> setMute(bool mute);
  Future<void> seek(double progress);
  Future<void> setRate(double rate);
  Future<bool> enableHardwareDecode(bool enable);
  Future<int> enterPictureInPictureMode(
      {String? backIconForAndroid, String? playIconForAndroid, String? pauseIconForAndroid, String? forwardIconForAndroid});
}