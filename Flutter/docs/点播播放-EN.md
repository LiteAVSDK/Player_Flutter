English| [简体中文](./点播播放.md)

## SDK Download

You can download the Tencent Cloud RT-Cube Superplayer SDK for Flutter [here](https://github.com/LiteAVSDK/Player_Flutter/tree/main/Flutter).

## Intended Audience

This document describes some of the capabilities of Tencent Cloud. Make sure that you have activated relevant [Tencent Cloud](https://intl.cloud.tencent.com/) services before using them. If you haven't registered an account, please [sign up for free](https://intl.cloud.tencent.com/account/register) first.

## This Document Describes
* How to integrate the Tencent Cloud RT-Cube Player SDK for Flutter.
* How to use the Player SDK for VOD playback.
* How to use the underlying capabilities of the Player SDK to implement more features.

## Basics
This document describes the VOD playback feature of the Player SDK. You can start by understanding the following basics:

- **Live streaming and video on demand**
  In live streaming, the video source is pushed by the host in real time. When the host stops pushing the source, the player will also stop playing the video. Because the live stream is played back in real time, no progress bar will be displayed in the player during the playback.

In video on demand (VOD), the video source is a video file in the cloud, which can be played back at any time as long as it is not deleted from the cloud. A progress bar is displayed for controlling the playback progress. Typical VOD scenarios include viewing videos on video websites such as Tencent Video and Youku Tudou.

- **Supported protocols**
  Common VOD protocols are as listed below. Currently, VOD URLs in HLS format (starting with `http` and ending with `.m3u8`) are popular.
  ![](https://mc.qcloudimg.com/static/img/4b42a00bb7ce2f58f362f35397734177/image.jpg)

## Notes
The Player SDK **does not impose any limits on the sources of playback URLs**, which means that you can use it to play back videos from both Tencent Cloud and non-Tencent Cloud URLs. However, players in the SDK support only live streaming URLs in FLV, RTMP, and HLS (M3U8) formats, as well as VOD URLs in MP4, HLS (M3U8), and FLV formats.

## How Shared Texture Works
Flutter internally provides a mechanism to share the native textures with Flutter for rendering. The following figure uses iOS as an example to show how the official external texture mechanism works:

![](texture_arch.png)

Blocks in red are the native code to be written, and blocks in yellow are the internal code logic of the Flutter engine. The entire process consists of texture registration and overall texture rendering logic.

### Registering texture

1. Create an object to implement the `FlutterTexture` protocol and manage specific texture data.
2. Use `FlutterTextureRegistry` to register the `FlutterTexture` object described in step 1 to get a Flutter texture ID.
3. Send the ID through the channel mechanism to Dart, where you can use the `Texture` widget and pass in the ID as the parameter to use the texture.

### Rendering texture

1. Create an object to implement the `FlutterTexture` protocol and manage specific texture data.
2. Use `FlutterTextureRegistry` to register the `FlutterTexture` object described in step 1 to get a Flutter texture ID.
3. Send the ID through the channel mechanism to Dart, where you can use the `Texture` widget and pass in the ID as the parameter to use the texture.
4. The Flutter engine calls `copyPixelBuffer` to get the specific texture data and uses GPU to render it at the underlying layer.


## Integration Guide[](id:Guide)

1. Add the following configuration to `pubspec.yaml`.
```yaml
super_player:
  git:
    url: https://github.com/LiteAVSDK/Player_Flutter
    path: Flutter
```

2. Update the dependency package.
```yaml
flutter pub upgrade
```

3. To integrate the Professional Edition, change the configuration in `pubspec.yaml` as follows:

```yaml
super_player:
  git:
    url: https://github.com/tencentyun/SuperPlayer
    path: Flutter
    ref: Professional
```

4. Add the native configuration.

### Android configuration[](id:Android_config)

Add the following configuration to the `AndroidManifest.xml` file of Android.

```xml
<!--network permission-->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<!--VOD player floating window permission-->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<!--storage-->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS configuration[](id:iOS_config)

Add the following configuration to the `Info.plist` file of iOS:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

To change the TXLiteAVSDK version depended on in the project, you can specify the version, such as `TXLiteAVSDK_Player','9.5.29016'` in the Podfile. If the version is unspecified, the latest version will be used.
```xml
pod 'TXLiteAVSDK_Player'
```

## SDK Integration[](id:stepone)

### Step 1. Apply for and integrate a video playback license[](id:step1)

To integrate a player, you need to [sign up for a Tencent Cloud account](https://intl.cloud.tencent.com/account/register), apply for the video playback license, and then integrate the license as follows. We recommend you integrate it during application start.

If no license is integrated, exceptions may occur during playback.

```dart
String licenceURL = ""; // The obtained license URL
String licenceKey = ""; // The obtained license key
SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
```

### Step 2. Create a controller[](id:step2)

```dart
TXVodPlayerController _controller = TXVodPlayerController();
```

### Step 3. Configure event listening[](id:step3)

```dart
// Listen for the video width and height change and set an appropriate aspect ratio. You can also customize the aspect ratio, and the video texture will be stretched proportionally
_controller.onPlayerNetStatusBroadcast.listen((event) async {
  double w = (event["VIDEO_WIDTH"]).toDouble();
  double h = (event["VIDEO_HEIGHT"]).toDouble();

  if (w > 0 && h > 0) {
    setState(() {
      _aspectRatio = 1.0 * w / h;
    });
  }
});
```

### Step 4. Add a layout[](id:step4)
```dart
@override
Widget build(BuildContext context) {
return Container(
  decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("images/ic_new_vod_bg.png"),
        fit: BoxFit.cover,
      )),
  child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('VOD'),
      ),
      body: SafeArea(
          child: Container(
            height: 150,
            color: Colors.black,
            child: Center(
              child: _aspectRatio > 0
                  ? AspectRatio(
                aspectRatio: _aspectRatio,
                child: TXPlayerVideo(controller: _controller),
              ) : Container(),
            ),
          ))));
}
```

### Step 5. Initialize the player[](id:step5)

```dart
// Initialize the player and assign the shared texture
await _controller.initialize();
```

### Step 6. Start the playback[](id:step6)
::: Playback via URL
`TXVodPlayerController` will internally recognize the playback protocol automatically. You only need to pass in your playback URL to the `startVodPlay` function.
```dart
// Play back the video resource
String _url =
    "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";
await _controller.startVodPlay(_url);
```
:::
::: Playback via `fileId`
```dart
TXPlayerAuthParams authParams = TXPlayerAuthParams();
authParams.appId = 1252463788;
authParams.fileId = "4564972819220421305";
await _controller.startVodPlayWithParams(authParams);
```
Find the target video file in [Media Assets](https://console.cloud.tencent.com/vod/media), and you can view the `FileId` below the filename.

Play back the video through the `FileId`, and the player will request the backend for the real playback URL. If the network is abnormal or the `FileId` doesn't exist, the `TXLiveConstants.PLAY_ERR_GET_PLAYINFO_FAIL` event will be received; otherwise, `TXLiveConstants.PLAY_EVT_GET_PLAYINFO_SUCC` will be received, indicating that the request succeeded.
:::
</dx-tabs>

### Step 7. Stop the playback[](id:step7)
**Remember to call the controller termination method** when stopping the playback, especially before the next call of `startVodPlay`. This can prevent memory leak and screen flashing issues.
```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```


## SDK API List[](id:sdkList)

#### Initializing player

**Description**

This API is used to initialize the controller and request assignment of shared textures.

**API**

```dart
await _controller.initialize();
```

#### Playing back through URL

**Notice**

Starting from version 10.7.0, the Licence needs to be set through {@link SuperPlayerPlugin#setGlobalLicense} before it can be played successfully, otherwise the playback will fail (black screen), and it can only be set once globally. Live Licence, UGC Licence, and Player Licence can all be used. If you have not obtained the above Licence, you can quickly apply for a beta Licence for free To play, the official licence needs to be [purchased](https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96 .B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).

**Description**

This API is used to play back a video via URL.

**API**

```dart
_controller.startVodPlay(url);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| url | String | The URL of the video to be played back. |

#### Playing back via file ID

**Notice**

Starting from version 10.7.0, the Licence needs to be set through {@link SuperPlayerPlugin#setGlobalLicense} before it can be played successfully, otherwise the playback will fail (black screen), and it can only be set once globally. Live Licence, UGC Licence, and Player Licence can all be used. If you have not obtained the above Licence, you can quickly apply for a beta Licence for free To play, the official licence needs to be [purchased](https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96 .B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).

**Description**

This API is used to play back a video via `fileId`.

**API**

```dart
TXPlayerAuthParams params = TXPlayerAuthParams();
params.appId = 1252463788;
params.fileId = "4564972819220421305";
_controller.startVodPlayWithParams(params);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| appId | int | Application's `appId`, which is required |
| fileId | String | The File ID, which is required |
| timeout | String | Encrypted link timeout timestamp, which will be converted to a hexadecimal lowercase string. The CDN server will determine whether the link is valid based on the timestamp |
| exper | String | Preview duration in seconds |
| us | String | Unique ID request, which increases the link uniqueness |
| sign | String | Hotlink protection signature. For more information, visit https://cloud.tencent.com/document/product/266/11243 |
| https | String | Whether to use HTTPS request. Default value: false |

#### Pausing playback

**Description**

This API is used to pause a video during playback.

**API**

```dart
_controller.pause();
```

#### Resuming playback

**Description**

This API is used to resume the playback of a paused video.

**API**

```dart
_controller.resume();
```

#### Stopping playback

**Description**

This API is used to stop a video during playback

**API**

```dart
_controller.stop();
```
**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| isNeedClear | bool | Whether to clear the last-frame image. |

#### Enabling/Disabling auto playback

**Description**

This API is used to set whether to automatically play back the video after calling `startVodPlay` to load the video URL.

**API**

```dart
_controller.setIsAutoPlay(true);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| isAutoPlay | bool | Whether to play back the video automatically. |

#### Querying player playback status

**Description**

This API is used to query whether the player is currently playing a video.

**API**

```dart
_controller.isPlaying();
```

#### Muting/Unmuting playback

**Description**

This API is used to set whether to mute the current playback.

**API**

```dart
_controller.setMute(true);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| mute | bool | Whether to mute the playback |

#### Looping playback

**Description**

This API is used to specify whether to loop the video after the video playback ends.

**API**

```dart
_controller.setLoop(true);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| loop | bool | Whether to loop the video |

#### Adjusting playback progress (seek)

**Description**

This API is used to adjust the playback progress to the specified time.

**API**

```dart
_controller.seek(progress);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| progress | double | Target playback time in seconds |

#### Setting playback rate

**Description**

This API is used to set the playback rate.

**API**

```dart
_controller.setRate(rate);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| rate | double | Video playback rate. Default value: 1.0 |

#### Getting bitrate information

**Description**

This API is used to get the bitrates supported by the video being played back.

**API**

```dart
_controller.getSupportedBitrates();
```

**Returned value description:**

| Returned Value | Type | Description |
| ------ | ------ | ------------------ |
| index | int | Bitrate number |
| width | int | Video width for the bitrate |
| height | int | Video height for the bitrate |
| bitrate | int | Bitrate value |

#### Getting bitrate setting

**Description**

This API is used to get the set bitrate number.

**API**

```dart
_controller.getBitrateIndex();
```

#### Setting bitrate

**Description**

This API is used to set the current bitrate by bitrate number.

**API**

```dart
_controller.setBitrateIndex(index);
```

#### Specifying playback start time

**Description**

This API is used to specify the playback start time.

**API**

```dart
_controller.setStartTime(startTime);
```

#### Setting video volume level

**Description**

This API is used to set the video volume level.

**API**

```dart
_controller.setAudioPlayoutVolume(volume);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| volume | int | Video volume level. Value range: 0–100 |

#### Getting audio focus

**Description**

This API is used to get the audio focus.

**API**

```dart
_controller.setRequestAudioFocus(focus);
```

#### Configuring player

**Description**

This API is used to configure the player.

**API**

```dart
_controller.setConfig(config);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| connectRetryCount | int | Number of player reconnections. If the SDK is disconnected from the server due to an exception, the SDK will attempt to reconnect to the server |
| connectRetryInterval | int | Interval between two player reconnections. If the SDK is disconnected from the server due to an exception, the SDK will attempt to reconnect to the server |
| timeout | int | Player connection timeout period |
| playerType | int | Player type. Valid values: 0: VOD; 1: live streaming; 2: live stream replay |
| headers | Map | Custom HTTP headers |
| enableAccurateSeek | bool | Whether to enable accurate seek. Default value: true |
| autoRotate | bool | If it is set to `true`, the MP4 file will be automatically rotated according to the rotation angle set in the file, which can be obtained from the `PLAY_EVT_CHANGE_ROTATION` event. Default value: true |
| smoothSwitchBitrate | bool | Whether to enable smooth multi-bitrate HLS stream switch. If it is set to `false` (default), multi-bitrate URLs are opened faster. If it is set to `true`, the bitrate can be switched smoothly when IDR frames are aligned |
| cacheMp4ExtName | String | Cached MP4 filename extension. Default value: mp4 |
| progressInterval | int | Progress callback interval in ms. If it is not set, the SDK will call back the progress once every 0.5 seconds |
| maxBufferSize | int | Maximum size of playback buffer in MB. The setting will affect `playableDuration`. The greater the value, the more the data that is buffered in advance |
| maxPreloadSize | int | Maximum preload buffer size in MB |
| firstStartPlayBufferTime | int | Duration of the video data that needs to be loaded during the first buffering in ms. Default value: 100 ms |
| nextStartPlayBufferTime | int | Minimum buffered data size to stop buffering (secondary buffering for insufficient buffered data or progress bar drag buffering caused by `seek`) in ms. Default value: 250 ms |
| overlayKey | String | HLS security hardening encryption and decryption key |
| overlayIv | String | HLS security hardening encryption and decryption IV |
| extInfoMap | Map | Some special configuration items |
| enableRenderProcess | bool | Whether to allow the postrendering and postproduction feature, which is enabled by default. If the super-resolution plugin exists after it is enabled, the plugin will be loaded by default |
| preferredResolution | int | Resolution of the video used for playback preferably. `preferredResolution` = `width` * `height` |

#### Configuring global caching

**Description**

This API is used to set the number of cache files and the cache directory.

**API**

```dart
// Set the VOD cache directory, which takes effect for MP4 and HLS files
SuperPlayerPlugin.setGlobalMaxCacheSize(size);
// Set the maximum number of cache files
SuperPlayerPlugin.setGlobalCacheFolderPath(path);
```

#### Getting current playback time

**Description**

This API is used to get the current playback time in seconds.

**API**

```dart
_controller.getCurrentPlaybackTime();
```

#### Getting currently buffered video duration

**Description**

This API is used to get the currently buffered video duration in seconds.

**API**

```dart
_controller.getBufferDuration();
```

#### Getting playable duration

**Description**

This API is used to get the playable duration of the video being played back in seconds.

**API**

```dart
_controller.getPlayableDuration();
```

#### Getting video width

**Description**

This API is used to get the width of the video being played back.

**API**

```dart
_controller.getWidth();
```

#### Getting video height

**Description**

This API is used to get the height of the video being played back.

**API**

```dart
_controller.getHeight();
```

#### Setting token

**Description**

This API is used to set the token for HLS encryption. After the token is set, the player will automatically add `voddrm.token` before the filename in the URL.

**API**

```dart
_controller.setToken(token);
```

#### Getting loop status

**Description**

This API is used to get the current loop status of the player.

**API**

```dart
_controller.isLoop();
```

#### Enabling/Disabling hardware decoding

**Description**

This API is used to enable/disable playback based on hardware decoding. After the value is set, it will not take effect until the video playback is restarted.

**API**

```dart
_controller.enableHardwareDecode(enable);
```

#### Terminating the controller

**Description**

This API is used to terminate the controller. After it is called, all notification events will be terminated, and the player will be released.

**API**

```dart
_controller.dispose();
```

## Event Notifications

#### Listening for playback events

**Description**

This callback is used to listen for the various playback statuses of the player.

**Code**

```dart
_controller.onPlayerEventBroadcast.listen((event) async {
  if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN || event["event"] == TXVodPlayEvent.PLAY_EVT_RCV_FIRST_I_FRAME) {
    // code ...
  } else if (event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
   // code ...
  }
});
```

**Event description**

For more information, see [Playback events](https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6).

#### Listening for player network event

**Description**

This callback is used to listen for the player network status.

**Code**

```dart
_controller.onPlayerNetStatusBroadcast.listen((event) async { });
```

**Event description**

For more information, see [Periodic status notifications](https://cloud.tencent.com/document/product/454/7886#.E5.AE.9A.E6.97.B6.E8.A7.A6.E5.8F.91.E7.9A.84.E7.8A.B6.E6.80.81.E9.80.9A.E7.9F.A5).

#### Listening for playback status

**Description**

This callback is used to listen for the video playback status and status change after encapsulation.

**Code**

```dart
_controller.onPlayerState.listen((val) { });
```

**Event description**

The enumeration class `TXPlayerState` is used to transfer the event.

| Status | Description |
| ------ | ------ |
| paused | The playback was paused |
| failed | The playback failed |
| buffering | Buffering |
| playing | Playing back |
| stopped | The playback was stopped |
| disposed | The control was released |

## Advanced Features

### Preloading
In UGSV playback scenarios, the preloading feature contributes to a smooth viewing experience: When a video is being played, you can load the URL of the next video to be played back on the backend. When users switch to the next video, it will have been loaded and can be played back immediately.

This is how seamless switch works in video playback. You can use `isAutoPlay` in `TXVodPlayerController` to implement the feature as follows:

![](https://mc.qcloudimg.com/static/img/7331417ebbdfe6306fe96f4b76c8d0ad/image.jpg)

```dart
// Play back video A: If `isAutoPlay` is set to `true`, the video will be immediately loaded and played back when `startVodPlay` is called
String url_A = "http://1252463788.vod2.myqcloud.com/xxxxx/v.f10.mp4";
await _controller_A.setIsAutoPlay(isAutoPlay: true);
await _controller_A.startVodPlay(url_A);

// To preload video B when playing back video A, set `isAutoPlay` to `false`
String url_B = "http://1252463788.vod2.myqcloud.com/xxxxx/v.f20.mp4";
await _controller_B.setIsAutoPlay(isAutoPlay: false);
await _controller_B.startVodPlay(url_B);
```

After video A ends and video B is automatically or manually switched to, you can call the `resume` function to immediately play back video B.
```dart
_controller.onPlayerEventBroadcast.listen((event) async {// Subscribe to status change
  if(event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_END) { // For more information, see the native SDK status codes of iOS or Android
    await _controller_A.stop();
    await _controller_B.resume();
  }
});
```

## Progress Display

There are two metrics for the VOD progress: **loading progress** and **playback progress**. Currently, the SDK notifies the two progress metrics in real time through event notifications.

![](https://mc.qcloudimg.com/static/img/6ac5e2fe87e642e6c2e6342d72464f4a/image.png)

```dart
_controller.onPlayerEventBroadcast.listen((event) async {
  if(event["event"] == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {// For more information, see the native SDK status codes of iOS or Android
    // Playable duration, i.e., loading progress, in milliseconds
    double playableDuration = event[TXVodPlayEvent.EVT_PLAYABLE_DURATION_MS].toDouble();
    // Playback progress in seconds
    int progress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS].toInt();
    // Total video duration in seconds
    int duration = event[TXVodPlayEvent.EVT_PLAY_DURATION].toInt();
  }
});
```













