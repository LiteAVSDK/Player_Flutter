# 直播截图与录屏接口文档

本文档介绍 `TXLivePlayerController` 中与截图和本地录制相关的接口。

## 接口

### startLocalRecording
**说明**
开始本地录制直播流。调用此方法后，播放器将把直播流录制到本地文件。录制过程中会通过 `liveListener` 回调录制状态。
**接口**
```dart
Future<void> startLocalRecording(FTXLiveLocalRecordingParams params) async
```
**参数说明**
| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| params | FTXLiveLocalRecordingParams | 是 | 本地录制参数配置 |

**FTXLiveLocalRecordingParams 参数**
| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| filePath | String | 是 | 录制文件的存储路径 |
| interval | int | 否 | 录制分片时长，单位毫秒，默认值 -1 表示不分片 |

### stopLocalRecording
**说明**
停止本地录制。调用此方法后，播放器将停止录制并保存已录制的内容，录制完成后会通过 `liveListener.recordCompleteCallback` 回调通知。
**接口**
```dart
Future<void> stopLocalRecording() async
```

### snapshot
**说明**
对当前直播画面进行截图。截图完成后会通过 `liveListener.snapshotCompleteCallback` 回调返回截图数据。
**接口**
```dart
Future<void> snapshot() async
```

## 直播回调配置

### liveListener
**说明**
设置直播相关事件的监听器，用于接收录制和截图相关的回调通知。
**配置方式**
```dart
TXLivePlayerController controller = TXLivePlayerController();
controller.liveListener = FTXLiveListener(
  recordBeginCallback: (int code, String storagePath) {
    // 录制开始回调
    // code: 状态码，0 表示成功
    // storagePath: 录制文件存储路径
  },
  recordingCallback: (int durationMs, String storagePath) {
    // 录制进行中回调
    // durationMs: 已录制时长，单位毫秒
    // storagePath: 录制文件存储路径
  },
  recordCompleteCallback: (int code, String storagePath) {
    // 录制完成回调
    // code: 状态码，0 表示成功
    // storagePath: 录制文件存储路径
  },
  snapshotCompleteCallback: (Uint8List? imageBytes) {
    // 截图完成回调
    // imageBytes: 截图数据，可通过 Image.memory(imageBytes) 显示
  },
);
```

**FTXLiveListener 回调说明**
| 回调名 | 类型 | 描述 |
|--------|------|------|
| recordBeginCallback | FTXLiveLocalRecordBegin | 录制开始时触发 |
| recordingCallback | FTXLiveLocalRecording | 录制进行中定时触发 |
| recordCompleteCallback | FTXLiveLocalRecordComplete | 录制完成时触发 |
| snapshotCompleteCallback | FTXLiveSnapshotComplete | 截图完成时触发 |
