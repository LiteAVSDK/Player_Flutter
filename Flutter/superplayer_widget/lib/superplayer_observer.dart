// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// superPlayer's bridge between widget and controller
class _SuperPlayerObserver {
  Function onPlayPrepare;
  Function(String name) onPlayBegin;
  Function onPlayPause;
  Function onPlayStop;
  Function onPlayLoading;
  Function(double current, double duration,double playableDuration) onPlayProgress;
  Function(double position) onSeek;
  Function(bool success, SuperPlayerType playerType, VideoQuality? quality) onSwitchStreamStart;
  Function(bool success, SuperPlayerType playerType, VideoQuality? quality) onSwitchStreamEnd;
  Function(int code, String msg) onError;
  Function(SuperPlayerType playerType) onPlayerTypeChange;
  Function(TXLivePlayerController controller, String url) onPlayTimeShiftLive;
  Function(List<VideoQuality>? qualityList, VideoQuality? defaultQuality) onVideoQualityListChange;
  Function(PlayImageSpriteInfo? info, List<PlayKeyFrameDescInfo>? list) onVideoImageSpriteAndKeyFrameChanged;
  Function onRcvFirstIframe;
  Function onResolutionChanged;
  Function onSysBackPress;
  Function onPreparePlayVideo;
  Function onDispose;

  _SuperPlayerObserver(
      this.onPreparePlayVideo,
      this.onPlayPrepare,
      this.onPlayBegin,
      this.onPlayPause,
      this.onPlayStop,
      this.onRcvFirstIframe,
      this.onPlayLoading,
      this.onPlayProgress,
      this.onSeek,
      this.onSwitchStreamStart,
      /// only support live
      this.onSwitchStreamEnd,
      this.onError,
      this.onPlayerTypeChange,
      /// only support live
      this.onPlayTimeShiftLive,
      this.onVideoQualityListChange,
      this.onVideoImageSpriteAndKeyFrameChanged,
      this.onResolutionChanged,
      this.onSysBackPress,
      this.onDispose,);
}
