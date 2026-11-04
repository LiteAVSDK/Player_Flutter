# Live Streaming Snapshot and Recording API Documentation

This document describes the snapshot and local recording related APIs in `TXLivePlayerController`.

## APIs

### startLocalRecording
**Description**
Start local recording of the live stream. After calling this method, the player will record the live stream to a local file. The recording status will be notified through `liveListener` callbacks.
**API**
```dart
Future<void> startLocalRecording(FTXLiveLocalRecordingParams params) async
```
**Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| params | FTXLiveLocalRecordingParams | Yes | Local recording parameter configuration |

**FTXLiveLocalRecordingParams Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| filePath | String | Yes | Storage path for the recorded file |
| interval | int | No | Recording segment duration in milliseconds, default -1 means no segmentation |

### stopLocalRecording
**Description**
Stop local recording. After calling this method, the player will stop recording and save the recorded content. The completion will be notified through `liveListener.recordCompleteCallback`.
**API**
```dart
Future<void> stopLocalRecording() async
```

### snapshot
**Description**
Take a snapshot of the current live stream frame. The snapshot data will be returned through `liveListener.snapshotCompleteCallback` when completed.
**API**
```dart
Future<void> snapshot() async
```

## Live Streaming Callback Configuration

### liveListener
**Description**
Set the listener for live streaming related events to receive recording and snapshot callback notifications.
**Configuration**
```dart
TXLivePlayerController controller = TXLivePlayerController();
controller.liveListener = FTXLiveListener(
  recordBeginCallback: (int code, String storagePath) {
    // Recording start callback
    // code: status code, 0 means success
    // storagePath: recorded file storage path
  },
  recordingCallback: (int durationMs, String storagePath) {
    // Recording in progress callback
    // durationMs: recorded duration in milliseconds
    // storagePath: recorded file storage path
  },
  recordCompleteCallback: (int code, String storagePath) {
    // Recording complete callback
    // code: status code, 0 means success
    // storagePath: recorded file storage path
  },
  snapshotCompleteCallback: (Uint8List? imageBytes) {
    // Snapshot complete callback
    // imageBytes: snapshot data, can be displayed using Image.memory(imageBytes)
  },
);
```

**FTXLiveListener Callback Description**
| Callback | Type | Description |
|----------|------|-------------|
| recordBeginCallback | FTXLiveLocalRecordBegin | Triggered when recording starts |
| recordingCallback | FTXLiveLocalRecording | Triggered periodically during recording |
| recordCompleteCallback | FTXLiveLocalRecordComplete | Triggered when recording completes |
| snapshotCompleteCallback | FTXLiveSnapshotComplete | Triggered when snapshot completes |
