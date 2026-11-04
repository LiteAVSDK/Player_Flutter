# TRTC Real-time Audio/Video Streaming API Documentation

This document describes the TRTC real-time audio/video streaming related APIs in `TXVodPlayerController`.

### enableTRTC
**Description**
Enable/disable the connection with TRTC real-time audio and video. **This method must be called before playback starts.** Once enabled, the player will establish a connection with TRTC real-time audio and video transmission, allowing the player's audio and video data to be pushed to the TRTC room.
**API**
```dart
Future<void> enableTRTC(bool isEnable) async
```
**Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| isEnable | bool | Yes | true: enable TRTC connection; false: disable TRTC connection |

### publishVideo
**Description**
Start publishing video stream to the TRTC room. After calling this method, the player's video will be pushed to the TRTC room, and other users in the room can see the video. `enableTRTC(true)` must be called before this method.
**API**
```dart
Future<void> publishVideo() async
```

### unpublishVideo
**Description**
Stop publishing video stream to the TRTC room. After calling this method, the player's video will stop being pushed to the TRTC room.
**API**
```dart
Future<void> unpublishVideo() async
```

### publishAudio
**Description**
Start publishing audio stream to the TRTC room. After calling this method, the player's audio will be pushed to the TRTC room, and other users in the room can hear the audio. `enableTRTC(true)` must be called before this method.
**API**
```dart
Future<void> publishAudio() async
```

### unpublishAudio
**Description**
Stop publishing audio stream to the TRTC room. After calling this method, the player's audio will stop being pushed to the TRTC room.
**API**
```dart
Future<void> unpublishAudio() async
```
