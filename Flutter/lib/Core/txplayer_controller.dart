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
}