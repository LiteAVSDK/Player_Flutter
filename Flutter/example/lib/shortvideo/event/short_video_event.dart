part of demo_short_video_player_lib;

abstract class BaseEvent {
  static const PLAY_AND_STOP = 1;
  static const PAUSE = 2;
  static const RESUME = 3; 
}

class ShortVideoEvent extends BaseEvent {
  int playerIndex;
  int eventType;
  ShortVideoEvent(this.playerIndex, this.eventType);
}