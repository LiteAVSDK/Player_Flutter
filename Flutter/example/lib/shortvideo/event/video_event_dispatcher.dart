part of demo_short_video_player_lib;

class VideoEventDispatcher {
  StreamController<ShortVideoEvent> playerStreamController = StreamController.broadcast();

  Stream<ShortVideoEvent> getEventStream() {
    return playerStreamController.stream;
  }

  void notifyEvent(ShortVideoEvent event) {
    playerStreamController.sink.add(event);
  }

  void closeStream() {
    playerStreamController.close();
  }
}
