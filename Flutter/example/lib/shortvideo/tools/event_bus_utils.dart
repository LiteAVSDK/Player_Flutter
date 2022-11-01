// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_short_video_player_lib;

class EventBusUtils {

  static final EventBus _instance  = EventBus();

  static EventBus getInstance() {
    return _instance;
  }
}

class ApplicationPauseEvent{
  ApplicationPauseEvent();
}

class StopAndResumeEvent{
  int index;
  StopAndResumeEvent(this.index);
}

class ApplicationResumeEvent{
  ApplicationResumeEvent();
}