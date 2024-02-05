English| [简体中文](./播放器组件.md)

## SDK Download

You can download the Tencent Cloud RT-Cube Superplayer SDK for Flutter [here](https://github.com/LiteAVSDK/Player_Flutter/tree/main/Flutter).

## Intended Audience

This document describes some of the capabilities of Tencent Cloud. Make sure that you have activated relevant [Tencent Cloud](https://intl.cloud.tencent.com/) services before using them. If you haven't registered an account, please [sign up for free](https://intl.cloud.tencent.com/account/register) first.

## This Document Describes

* How to integrate the Tencent Cloud RT-Cube Superplayer for Flutter.
* How to use the Superplayer component for VOD playback.

## Basics

The Superplayer SDK for Flutter is an extension of the VOD player SDK for Flutter. The Superplayer SDK is easy to use and integrates more features, including full-screen playback, video quality change, progress bar, playback control, and thumbnail title.

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

3. Add the native configuration.

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
SuperPlayerController _controller = SuperPlayerController(context);
```

### Step 3. Configure Superplayer[](id:step3)

```dart
FTXVodPlayConfig config = FTXVodPlayConfig();
// If `preferredResolution` is not configured, the 720x1280 resolution stream will be played back preferably during multi-bitrate video playback
config.preferredResolution = 720 * 1280;
_controller.setPlayConfig(config);
```

For detailed configuration in `FTXVodPlayConfig`, see the player configuration API of the VOD player SDK for Flutter.

### Step 4. Configure event listening[](id:step4)

```dart
_controller.onSimplePlayerEventBroadcast.listen((event) {
  String evtName = event["event"];
  if (evtName == SuperPlayerViewEvent.onStartFullScreenPlay) {
    setState(() {
      _isFullScreen = true;
    });
  } else if (evtName == SuperPlayerViewEvent.onStopFullScreenPlay) {
    setState(() {
      _isFullScreen = false;
    });
  } else {
    print(evtName);
  }
});
```

### Step 5. Add a layout[](id:step5)

```dart
Widget _getPlayArea() {
    return Container(
    height: 220,
    child: SuperPlayerView(_controller),
  );
}
```

### Step 6. Listen for the Back button tapping event[](id:step6)

Listen for the Back button tapping event. If the player is in full screen mode when the event is triggered, the SDK exits the full screen mode. When the event is triggered again, the SDK exits the page.
**If you want to directly exit the page from full screen playback mode, you don't need to listen for the event.**

```dart
  @override
Widget build(BuildContext context) {
  return WillPopScope(
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/ic_new_vod_bg.png"),
              fit: BoxFit.cover,
            )),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isFullScreen
              ? null
              : AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('SuperPlayer'),
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) => getBody(),
            ),
          ),
        ),
      ),
      onWillPop: onWillPop);
}

Future<bool> onWillPop() async {
  return !_controller.onBackPress();
}
```

### Step 7. Start the playback[](id:step7)

::: Through URL
```dart
SuperPlayerModel model = SuperPlayerModel();
model.videoURL = "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";
_controller.playWithModelNeedLicence(model);
```
:::

::: Through `fileId`
```dart
SuperPlayerModel model = SuperPlayerModel();
model.appId = 1500005830;
model.videoId = new SuperPlayerVideoId();
model.videoId.fileId = "8602268011437356984";
_controller.playWithModelNeedLicence(model);
```

Find the target video file in [Media Assets](https://console.cloud.tencent.com/vod/media), and you can view the `FileId` below the filename.

Play back the video through the `FileId`, and the player will request the backend for the real playback URL. If the network is abnormal or the `FileId` doesn't exist, the `SuperPlayerViewEvent.onSuperPlayerError` event will be received.

:::

### Step 8. Stop the playback[](id:step8)

**Remember to call the controller termination method** when stopping the playback, especially before the next call of `startVodPlay`. This can prevent memory leak and screen flashing issues, as well as ensure that playback is stopped when the page is exited.
```dart
  @override
void dispose() {
  // must invoke when page exit.
  _controller.releasePlayer();
  super.dispose();
}
```

## SDK API List[](id:sdkList)

#### Playing back video

**Notice**

Starting from version 10.7.0, the Licence needs to be set through {@link SuperPlayerPlugin#setGlobalLicense} before it can be played successfully, otherwise the playback will fail (black screen), and it can only be set once globally. Live Licence, UGC Licence, and Player Licence can all be used. If you have not obtained the above Licence, you can quickly apply for a beta Licence for free To play, the official licence needs to be [purchased](https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96 .B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license).

**Description**

This API is used to start video playback.

**API**

```dart
_controller.playWithModelNeedLicence(model);
```

**Parameter description**

1. SuperPlayerModel

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| appId | int | The application's `appId`, which is required for playback via `fileId`. |
| videoURL | String | The video URL, which is required for playback via URL. |
| multiVideoURLs | List<String> | Multi-bitrate playback URLs, which are required for playback via multi-bitrate URLs |
| defaultPlayIndex | int | The default playback bitrate number, which is used together with `multiVideoURLs`. |
| videoId | SuperPlayerVideoId | `fileId` storage object, which is further described below |
| title | String | The video title. You can use this to customize the title and overwrite the title internally requested by the player from the server. |
| coverUrl | String | The thumbnail image pulled from the Tencent server, whose value will be assigned automatically in `SuperVodDataLoader`. |
| customeCoverUrl | String | A custom video thumbnail. This parameter is used preferentially and is used to customize the video thumbnail. |
| duration | int | The video duration in seconds |
| videoDescription | String | The video description. |
| videoMoreDescription | String | The detailed video description. |
| playAction | int | Valid values: PLAY_ACTION_AUTO_PLAY, PLAY_ACTION_MANUAL_PLAY, PLAY_ACTION_PRELOAD, as described below |

2. SuperPlayerVideoId 

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| fileId | String | The File ID, which is required |
| psign | String | Required if hotlink protection is enabled on v4 |

3. playAction

* PLAY_ACTION_AUTO_PLAY: The video will be automatically played back after `playWithModelNeedLicence` is called.
* PLAY_ACTION_MANUAL_PLAY: The video needs to be played back manually after `playWithModelNeedLicence` is called. The player doesn't load the video and only displays the thumbnail image, which consumes no video playback resources compared with `PLAY_ACTION_PRELOAD`.
* PLAY_ACTION_PRELOAD: The player will display the thumbnail image and won't start the video playback after `playWithModelNeedLicence` is called, but the video will be loaded. This can start the playback faster than `PLAY_ACTION_MANUAL_PLAY`.

#### Pausing playback

**Description**

This API is used to pause video playback.

**API**

```dart
_controller.pause();
```

#### Resuming playback

**Description**

This API is used to resume the playback.

**API**

```dart
_controller.resume();
```
#### Restarting playback

**Description**

This API is used to restart the video playback.

**API**

```dart
_controller.reStart();
```

#### Resetting player

**Description**

This API is used to reset the player status and stop the video playback.

**API**

```dart
_controller.resetPlayer();
```

#### Releasing player

**Description**

This API is used to release the player resources and stop the video playback. After it is called, the controller can no longer be reused.

**API**

```dart
_controller.releasePlayer();
```

#### Callback for player return event

**Description**

This method is used to determine the action to perform when the Back button is tapped in full screen playback mode. If `true` is returned, the full screen mode is exited, and the Back tapping event is consumed; if `false` is returned, the event is unconsumed.

**API**

```dart
_controller.onBackPress();
```

#### Switching definition

**Description**

This API is used to change video quality during playback.

**API**

```dart
_controller.switchStream(videoQuality);
```

**Parameter description**

After playback starts, you can get the valid values of `videoQuality` through `_controller.currentQualiyList` (video quality options) and `_controller.currentQuality` (default video quality). **The video quality change feature has been integrated into Superplayer. In full screen mode, you can click the button in the bottom-right corner to change video quality.**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| index | int | Index of a video quality option |
| bitrate | int | Bitrate for a video quality option |
| width | int | Video width for a video quality option |
| height | int | Video height for a video quality option |
| name | String | Short name of a video quality option |
| title | String | Displayed name of a video quailty option |
| url | String | Multi-bitrate URL, which is optional |

#### Adjusting playback progress (seek)

**Description**

This API is used to adjust the current video playback progress.

**API**

```dart
_controller.seek(progress);
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| progress | double | Target time in seconds |

#### Configuring Superplayer

**Description**

This API is used to configure Superplayer.

**API**

```dart
_controller.setPlayConfig(config);
```

**Parameter description**

| Parameter | Type   | Description |
| ------ |--------| ------------------ |
| connectRetryCount | int    | Number of player reconnections. If the SDK is disconnected from the server due to an exception, the SDK will attempt to reconnect to the server |
| connectRetryInterval | int    | Interval between two player reconnections. If the SDK is disconnected from the server due to an exception, the SDK will attempt to reconnect to the server |
| timeout | int    | Player connection timeout period |
| playerType | int    | Player type. Valid values: 0: VOD; 1: live streaming; 2: live stream replay |
| headers | Map    | Custom HTTP headers |
| enableAccurateSeek | bool   | Whether to enable accurate seek. Default value: true |
| autoRotate | bool   | If it is set to `true`, the MP4 file will be automatically rotated according to the rotation angle set in the file, which can be obtained from the `PLAY_EVT_CHANGE_ROTATION` event. Default value: true |
| smoothSwitchBitrate | bool   | Whether to enable smooth multi-bitrate HLS stream switch. If it is set to `false` (default), multi-bitrate URLs are opened faster. If it is set to `true`, the bitrate can be switched smoothly when IDR frames are aligned |
| cacheMp4ExtName | String | Cached MP4 filename extension. Default value: mp4 |
| progressInterval | int    | Progress callback interval in ms. If it is not set, the SDK will call back the progress once every 0.5 seconds |
| maxBufferSize | double | Maximum size of playback buffer in MB. The setting will affect `playableDuration`. The greater the value, the more the data that is buffered in advance |
| maxPreloadSize | double | Maximum preload buffer size in MB |
| firstStartPlayBufferTime | int    | Duration of the video data that needs to be loaded during the first buffering in ms. Default value: 100 ms |
| nextStartPlayBufferTime | int    | Minimum buffered data size to stop buffering (secondary buffering for insufficient buffered data or progress bar drag buffering caused by `seek`) in ms. Default value: 250 ms |
| overlayKey | String | HLS security hardening encryption and decryption key |
| overlayIv | String | HLS security hardening encryption and decryption IV |
| extInfoMap | Map    | Some special configuration items |
| enableRenderProcess | bool   | Whether to allow the postrendering and postproduction feature, which is enabled by default. If the super-resolution plugin exists after it is enabled, the plugin will be loaded by default |
| preferredResolution | int    | Resolution of the video used for playback preferably. `preferredResolution` = `width` * `height` |

#### Enabling/Disabling hardware decoding

**Description**

This API is used to enable/disable playback based on hardware decoding.

**API**

```dart
_controller.enableHardwareDecode(enable);
```

#### Getting playback status

**Description**

This API is used to get the playback status.

**API**

```dart
SuperPlayerState superPlayerState = _controller.getPlayerState();
```

**Parameter description**

| Parameter | Type | Description |
| ------ | ------ | ------------------ |
| INIT | SuperPlayerState | Initial status |
| PLAYING | SuperPlayerState | Playing back |
| PAUSE | SuperPlayerState | Paused |
| LOADING | SuperPlayerState | Loading |
| END | SuperPlayerState | Ended |

#### Setting a license

**Description**

This API is used to initialize the license after the license is applied for. We recommend you call it during player start.

**API**

```dart
String licenceUrl = "Enter the URL of the purchased license";
String licenseKey = "Enter the license key";
SuperPlayerPlugin.setGlobalLicense(licenceUrl, licenceKey);
```

## Event Notifications

#### Listening for playback status

**Description**

This callback is used to listen for the video playback status and status change after encapsulation.

**Code**

```dart
_playController.onPlayStateBroadcast.listen((event) {
  SuperPlayerState state = event['event'];
});
```

**Event description**

The enumeration class `SuperPlayerState` is used to transfer the event.

| Status | Description |
| ------ |------------------ |
| INIT | Initial status |
| PLAYING | Playing back |
| PAUSE | Paused |
| LOADING  | Loading |
| END | Ended |

#### Listening for playback events

**Description**

This callback is used to listen for player operation events.

**Code**

```dart
_controller.onSimplePlayerEventBroadcast.listen((event) {
    String evtName = event["event"];
    if (evtName == SuperPlayerViewEvent.onStartFullScreenPlay) {
        setState(() {
        _ isFullScreen = true;
        });
    } else if (evtName == SuperPlayerViewEvent.onStopFullScreenPlay) {
        setState(() {
          _isFullScreen = false;
        });
    } else {
        print(evtName);
    }
});
```

**Event description**


| Status | Description |
| ------ |------------------ |
| onStartFullScreenPlay | Entered the full screen playback mode |
| onStopFullScreenPlay | Exited the full screen playback mode |
| onSuperPlayerDidStart | Playback started |
| onSuperPlayerDidEnd  | Playback ended |
| onSuperPlayerError | Playback error |
| onSuperPlayerBackAction | Back tapping event |

## Advanced Features

#### Requesting video data in advance through fileId

The `SuperVodDataLoader` API can be used to request the video data in advance to accelerate the playback start process.

**Code sample**

```dart
SuperPlayerModel model = SuperPlayerModel();
model.appId = 1500005830;
model.videoId = new SuperPlayerVideoId();
model.videoId.fileId = "8602268011437356984";
model.title = "VOD";
SuperVodDataLoader loader = SuperVodDataLoader();
// Values of the required parameters in `model` are directly assigned in `SuperVodDataLoader`
loader.getVideoData(model, (resultModel) {
  _controller.playWithModelNeedLicence(resultModel);
})
```



