# TRTC 实时音视频推流接口文档

本文档介绍 `TXVodPlayerController` 中与 TRTC 实时音视频推流相关的接口。

### enableTRTC
**说明**
开启/关闭与 TRTC 实时音视频的连接。**必须在播放之前调用此方法**，开启后播放器将与 TRTC 实时音视频传输建立联系，使播放器的音视频数据可以推送到 TRTC 房间内。
**接口**
```dart
Future<void> enableTRTC(bool isEnable) async
```
**参数说明**
| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| isEnable | bool | 是 | true: 开启 TRTC 连接；false: 关闭 TRTC 连接 |

### publishVideo
**说明**
开始推送视频流到 TRTC 房间。调用此方法后，播放器的视频画面将被推送到 TRTC 房间内，房间内的其他用户可以看到该视频画面。调用前需要先调用 `enableTRTC(true)` 开启 TRTC 连接。
**接口**
```dart
Future<void> publishVideo() async
```

### unpublishVideo
**说明**
停止推送视频流到 TRTC 房间。调用此方法后，播放器的视频画面将停止推送到 TRTC 房间内。
**接口**
```dart
Future<void> unpublishVideo() async
```

### publishAudio
**说明**
开始推送音频流到 TRTC 房间。调用此方法后，播放器的音频将被推送到 TRTC 房间内，房间内的其他用户可以听到该音频。调用前需要先调用 `enableTRTC(true)` 开启 TRTC 连接。
**接口**
```dart
Future<void> publishAudio() async
```

### unpublishAudio
**说明**
停止推送音频流到 TRTC 房间。调用此方法后，播放器的音频将停止推送到 TRTC 房间内。
**接口**
```dart
Future<void> unpublishAudio() async
```
