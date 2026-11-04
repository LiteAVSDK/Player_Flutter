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

### 1. Requesting video data in advance through fileId

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

### 2. Using Picture-in-Picture mode

#### 1. Android platform configuration

1.1 In your project's android package, find build.gradle, and ensure that the compileSdkVersion and targetSdkVersion versions are 31 or higher.

#### 2. iOS platform configuration

2.1 Under your project's target, select Signing & Capabilities, add Background Modes, and check Audio, AirPlay, and Picture in Picture.

#### 3. Copy superPlayer sample code

Import the superplayer_widget from the github project into your own lib directory, and integrate the player component by following the example code in demo_superplayer.dart. Then you can see the Picture-in-Picture mode button in the middle right of the player component's playback interface. Click it to enter Picture-in-Picture mode.

#### 4. Listening to the lifecycle of Picture-in-Picture mode

You can use onExtraEventBroadcast in SuperPlayerPlugin to listen to the lifecycle of Picture-in-Picture mode. The example code is as follows:

```dart
SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) {
  int eventCode = event["event"];
  if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_EXIT) {
    // exit pip mode
  } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_REQUEST_START) {
    // enter pip mode
  } else if (eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_ENTER) {
    // already enter pip mode
  } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_WILL_EXIT) {
    // will exit pip mode
  } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_RESTORE_UI) {
    // restore UI only support iOS
  } 
});
```

#### 5. Picture-in-Picture mode entry error code

When entering Picture-in-Picture mode fails, in addition to log prompts, there will also be toast prompts. You can modify the error handling in the _onEnterPipMode method in superplayer_widget.dart. The error code meanings are as follows:

| Parameter Name | Value | Description |
| ------ | ------ | ------------------ |
| NO_ERROR | 0 | Start successfully, no errors |
| ERROR_PIP_LOWER_VERSION | -101 | The Android version is too low to support Picture-in-Picture mode |
| ERROR_PIP_DENIED_PERMISSION | -102 | Picture-in-Picture mode permission is not turned on, or the current device does not support Picture-in-Picture |
| ERROR_PIP_ACTIVITY_DESTROYED | -103 | The current interface has been destroyed |
| ERROR_IOS_PIP_DEVICE_NOT_SUPPORT | -104 | The device or system version is not supported (PIP is only supported on iPad iOS9+) | only support iOS
| ERROR_IOS_PIP_PLAYER_NOT_SUPPORT | -105 | The player is not supported | only support iOS
| ERROR_IOS_PIP_VIDEO_NOT_SUPPORT | -106 | The video is not supported | only support iOS
| ERROR_IOS_PIP_IS_NOT_POSSIBLE | -107 | PIP controller is not available | only support iOS
| ERROR_IOS_PIP_FROM_SYSTEM | -108 | PIP controller error | only support iOS
| ERROR_IOS_PIP_PLAYER_NOT_EXIST | -109 | The player object does not exist | only support iOS
| ERROR_IOS_PIP_IS_RUNNING | -110 | PIP function is already running | only support iOS
| ERROR_IOS_PIP_NOT_RUNNING | -111 | PIP function is not started | only support iOS

#### 6. Determining whether the current device supports Picture-in-Picture

You can use isDeviceSupportPip in SuperPlayerPlugin to determine whether Picture-in-Picture can be enabled at the current time. The code example is as follows:

```dart
int result = await SuperPlayerPlugin.isDeviceSupportPip();
if(result == TXVodPlayEvent.NO_ERROR) {
  // pip support
}
```

The meaning of the return result is consistent with the Picture-in-Picture mode error code.

#### 7. Using Picture-in-Picture controller to manage Picture-in-Picture

The Picture-in-Picture controller TXPipController is a Picture-in-Picture tool encapsulated in superplayer_widget, and **must be used in conjunction with SuperPlayerView**. When entering Picture-in-Picture, the current interface will be automatically closed, and the pre-set listener method will be called back. In the callback method, you can save the necessary parameters of the current player interface. After the Picture-in-Picture is restored, the previous interface will be pushed back and the previously saved parameters will be passed.
When using this controller, there can only be one instance of Picture-in-Picture or player. When re-entering the player interface, Picture-in-Picture will be automatically closed.

7.1 In your project's entry point, such as main.dart, call TXPipController to set the Picture-in-Picture control jump, and the page to jump to is the player page used to enter Picture-in-Picture. You can set different interfaces according to your own project. The code example is as follows:

```dart
TXPipController.instance.setNavigatorHandle((params) {
  navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => DemoSuperPlayer(initParams: params)));
});
```

7.2 Set the listener for the Picture-in-Picture playback page. You need to implement the `TXPipPlayerRestorePage` method. After setting it, when you are about to enter Picture-in-Picture, the controller will call the `void onNeedSavePipPageState(Map<String, dynamic> params)` method back. At this time, you can save the parameters required for the current page in params.

```dart
TXPipController.instance.setPipPlayerPage(this);
```

7.3 Then, when the user clicks the enter Picture-in-Picture button on SuperPlayerView, the internal method `_onEnterPipMode` of `SuperPlayerView` will be called to enter Picture-in-Picture, or you can call the `enterPictureInPictureMode` method of `SuperPlayerController` to enter it.

### 3. Video Download

#### 1. Downloading Videos

1. To use the video download function of the player component, you first need to turn on `isEnableDownload` in SuperPlayerModel. This field is turned off by default.

```dart
SuperPlayerModel model = SuperPlayerModel();
// Turn on video download capability
model.isEnableDownload = true;
```

The player component currently only enables downloads in VOD playback mode.

2. You can use the `startDownload` method of `SuperPlayerController` to directly download the video currently being played by the player, corresponding to the clarity of the video being played. You can also use `DownloadHelper` to download a specific video, as follows:

```dart
DownloadHelper.instance.startDownloadBySize(videoModel, videoWidth, videoHeight);
```

Using `DownloadHelper`'s `startDownloadBySize`, you can download videos of a specific resolution. If there is no such resolution, a video with a similar resolution will be downloaded.
In addition to the above interfaces, you can also choose to pass in the quality ID or mediaInfo to download directly.

```dart
// QUALITY_240P  240p
// QUALITY_360P  360P
// QUALITY_480P  480p
// QUALITY_540P  540p
// QUALITY_720P  720p
// QUALITY_1080P 1080p
// QUALITY_2K    2k
// QUALITY_4K    4k
// The quality parameter can be customized, taking the minimum value of the resolution width and height (such as a resolution of 1280*720, and you want to download a stream of this resolution, pass QUALITY_720P to the quality parameter)
// The player SDK will select a stream smaller than or equal to the input resolution for download
// Download using quality ID
DownloadHelper.instance.startDownload(videoModel, qualityId);
// Download using mediaInfo
DownloadHelper.instance.startDownloadOrg(mediaInfo);
```

3. Quality ID conversion

The VOD `CommonUtils` provides the `getDownloadQualityBySize` method to convert the resolution to the corresponding quality ID.

```dart
CommonUtils.getDownloadQualityBySize(width, height);
```

#### 2. Stop Downloading Videos

You can use the `stopDownload` method of `DownloadHelper` to stop downloading the corresponding video. The code example is as follows:

```dart
DownloadHelper.instance.stopDownload(mediaInfo);
```

The `mediaInfo` can be obtained by `DownloadHelper`'s `getMediaInfoByCurrent` method, or by using `TXVodDownloadController`'s `getDownloadList` to obtain download information.

#### 3. Delete Downloaded Videos

You can use the `deleteDownload` method of `DownloadHelper` to delete the corresponding video.

```dart
bool deleteResult = await DownloadHelper.instance.deleteDownload(downloadModel.mediaInfo);
```

`deleteDownload` will return the deletion result to determine whether the deletion is successful.

#### 4. Download Status

`DownloadHelper` provides the basic `isDownloaded` method to determine whether the video has been downloaded. You can also register a listener to determine the download status in real time.

`DownloadHelper` distributes download events, and you can register events as shown in the following code:

```dart
// Register download event listener
DownloadHelper.instance.addDownloadListener(FTXDownloadListener((event, info) {
      // Download status changes
    }, (errorCode, errorMsg, info) {
      // Download error callback
    }));
// Remove download event listener
DownloadHelper.instance.removeDownloadListener(listener);
```

In addition, you can also use the `TXVodDownloadController.instance.getDownloadInfo(mediaInfo)` method or the `TXVodDownloadController.instance.getDownloadList()` method to directly query the downloadState in the `mediaInfo` to determine the download status.

#### 5. Playing Downloaded Videos

The video information obtained by `TXVodDownloadController.instance.getDownloadInfo(mediaInfo)` and `TXVodDownloadController.instance.getDownloadList()` has a `playPath` field, which can be played directly using `TXVodPlayerController`.

```dart
controller.startVodPlay(mediaInfo.playPath);
```

### 4. Using Full Screen Mode

#### 1. Configuration for Switching between Portrait and Landscape Modes

To switch between portrait and landscape modes in the player component, iOS needs to be opened using Xcode, and the project configuration needs to be opened. Under the Deployment tab on the General page, check `Landscape left` and `Landscape right`. Make sure that iOS devices support landscape mode.

If you want other pages of your app to remain in portrait mode and not be affected by automatic rotation between portrait and landscape modes, you need to configure portrait mode at the entry point of your own project. The code is as follows:

```dart
SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
```

#### 2. Automatically Switch to Full Screen Mode Based on Sensor Configuration

On the Android side, you need to call the following method to start monitoring the sensor:

```dart
SuperPlayerPlugin.startVideoOrientationService();
```

After calling this method, the Android sensor will be monitored, and rotation events will be sent to the Flutter side through `SuperPlayerPlugin.instance.onEventBroadcast`. The player component will automatically rotate the player based on this event. An example of how to use the listener is as follows:

```dart
SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) {
    int eventCode = event["event"];
    if (eventCode == TXVodPlayEvent.EVENT_ORIENTATION_CHANGED ) {
      int orientation = event[TXVodPlayEvent.EXTRA_NAME_ORIENTATION];
      // do orientation
    }
  });
```

### 5. External Subtitles

You can add external subtitles through `SuperPlayerModel`'s `subtitleSources`.
The code example is as follows:

```dart
model.subtitleSources.add(FSubtitleSourceModel()
  ..name = "ex-cn-srt"
  ..url = "https://mediacloud-76607.gzc.vod.tencent-cloud.com/DemoResource/TED-CN.srt"
  ..mimeType = FSubtitleSourceModel.VOD_PLAY_MIMETYPE_TEXT_SRT);
```

Currently, VTT and SRT formats are supported.




