## Player SDK for Flutter Plugin

English| [简体中文](./README.md)

## Directory Structure

This directory contains the demo source code of the Player SDK for Flutter plugin, which shows you how to call the APIs to implement basic features.

```
├── android                        // Demo source code of the Player for Android plugin
├── ios                            // Demo source code of the Player for iOS plugin
├── lib                            // Demo source code of the Player for Dart plugin
├── docs                           // Help documentation
└── example                        // Superplayer component
    ├── android                    // Demo source code for Android
    ├── ios                        // Demo source code for iOS
    └── lib                        // Code samples for VOD and live players as well as Superplayer
```

## Project Overview

The Player SDK is a subproduct of RT-Cube, which provides VOD and live players based on Tencent Cloud's powerful backend capabilities and AI technologies. It can be used together with VOD or CSS to quickly implement smooth and stable playback for various use cases. It allows you to focus on your business while delivering an ultra fast HD playback experience.

This project provides the VOD and live player SDKs which you can use to set up your own playback services.

- [VOD player SDK](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%82%B9%E6%92%AD%E6%92%AD%E6%94%BE-EN.md): `TXVodPlayerController` encapsulates the APIs of the VOD player SDKs for Android and iOS. You can integrate it to develop your VOD service. For the detailed code sample, see `DemoTXVodPlayer`.

- [Live player SDK](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%9B%B4%E6%92%AD%E6%92%AD%E6%94%BE-EN.md): `TXLivePlayerController` encapsulates the APIs of the live player SDKs for Android and iOS. You can integrate it to develop your live playback service. For the detailed code sample, see `DemoTXLivePlayer`.

To reduce the connection costs, the Superplayer component (player with UIs) is provided in `example`. You can set up your own video playback service based on a few lines of simple code. You can apply the Superplayer code to your project and adjust UI and interaction details based on your project requirements.

- [Superplayer component](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E6%92%AD%E6%94%BE%E5%99%A8%E7%BB%84%E4%BB%B6-EN.md): `SuperPlayerController` is the Superplayer component, which combines the VOD and live player SDKs. It is currently in beta testing, and its features are being optimized. For the detailed code sample, see `DemoSuperplayer`.

## Intended Audience

This document describes some of the capabilities of Tencent Cloud. Make sure that you have activated relevant [Tencent Cloud](https://cloud.tencent.com/) services before using them. If you haven't registered an account, please [sign up for free](https://cloud.tencent.com/login) first.

## Upgrade Notes

Player SDKs for Android, iOS, and Flutter 10.1 or later are developed based on the same playback kernel of Tencent Video with fully optimized and upgraded video playback capabilities.

In addition, those SDKs require license verification for the video playback feature module. **If your app has already been granted the live push or UGSV license, you can still use the license after upgrading the SDK to 10.1 or later.** The license won't be affected by the upgrade. You can log in to the [RT-Cube console](https://console.cloud.tencent.com/vcube) to view the current license information.

If you don't have the necessary license and **need to use the live playback or VOD playback feature in the Player SDK 10.1 or later, you need to purchase the license.** For more information, see [here](https://cloud.tencent.com/document/product/881/74199#.E6.8E.88.E6.9D.83.E8.AF.B4.E6.98.8E). If you don't need to use those features or haven't upgraded the SDK to the latest version, you won't be affected by this change.

## Quick Integration

### Configuring `pubspec.yaml`

Integrate `LiteAVSDK_Player` (which is integrated by default) and add the following configuration to `pubspec.yaml`:

```yaml
super_player:
  git:
    url: https://github.com/tencentyun/SuperPlayer
    path: Flutter
```

To integrate `LiteAVSDK_Professional`, change the configuration in `pubspec.yaml` as follows:

```yaml
super_player:
  git:
    url: https://github.com/tencentyun/SuperPlayer
    path: Flutter
    ref: Professional
```

Then, update the dependency package:

```yaml
flutter packages get
```

### Adding native configuration

#### Android configuration

Add the following configuration to the `AndroidManifest.xml` file of Android:

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

#### iOS configuration

Add the following configuration to the `Info.plist` file of iOS:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

iOS natively uses `pod` for dependency. Edit the `podfile` file and specify your player SDK edition. `TXLiteAVSDK_Player` is integrated by default.

```xml
pod 'TXLiteAVSDK_Player'	        // Player Edition
```

Integrate SDK Professional Edition.

```
pod 'TXLiteAVSDK_Professional' 	// Professional Edition
```

If no edition is specified, the latest version of `TXLiteAVSDK_Player` will be installed by default.

### FAQs about integration

Run the `flutter doctor` command to check the runtime environment until "No issues found!" is displayed.

Run `flutter pub get` to ensure that all dependent components have been updated successfully.

## Applying for and Integrating Video Playback License

If you have the required license, you need to get the license URL and key in the [RT-Cube console](https://console.cloud.tencent.com/vcube).

[![image](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)

If you don't have the required license, you need to get it as instructed in [Video Playback License](https://cloud.tencent.com/document/product/881/74588).

To integrate a player, you need to [sign up for a Tencent Cloud account](https://cloud.tencent.com/login), apply for the video playback license, and then integrate the license as follows. We recommend you integrate it during application start.

If no license is integrated, exceptions may occur during playback.

```dart
String licenceURL = ""; // The obtained license URL
String licenceKey = ""; // The obtained license key
SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
```

## Using the VOD Player

The core class of the VOD player is `TXVodPlayerController`. For the detailed demo, see `DemoTXVodPlayer`.

```dart
import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';

class Test extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TestState();
}

class _TestState extends State<Test> {
  late TXVodPlayerController _controller;

  double _aspectRatio = 16.0 / 9.0;
  String _url =
          "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";

  @override
  void initState() {
    super.initState();
    String licenceUrl = ""; // The obtained license URL
    String licenseKey = ""; // The obtained license key
    SuperPlayerPlugin.setGlobalLicense(licenceUrl, licenseKey);
    _controller = TXVodPlayerController();
    initPlayer();
  }

  Future<void> initPlayer() async {
    await _controller.initialize();
    await _controller.startVodPlay(_url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            height: 220,
            color: Colors.black,
            child: AspectRatio(aspectRatio: _aspectRatio, child: TXPlayerVideo(controller: _controller)));
  }
}
```
## Using Superplayer

The core class of Superplayer is `SuperPlayerVideo`, and videos can be played back after it is created.

```dart
import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';

/// flutter superplayer demo
class DemoSuperplayer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DemoSuperplayerState();
}

class _DemoSuperplayerState extends State<DemoSuperplayer> {
  List<SuperPlayerModel> videoModels = [];
  bool _isFullScreen = false;
  SuperPlayerController _controller;

  @override
  void initState() {
    super.initState();
    String licenceUrl = "Enter the URL of the purchased license";
    String licenseKey = "Enter the license key";
    SuperPlayerPlugin.setGlobalLicense(licenceUrl, licenseKey);
    _controller = SuperPlayerController(context);
    FTXVodPlayConfig config = FTXVodPlayConfig();
    config.preferredResolution = 720 * 1280;
    _controller.setPlayConfig(config);
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
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Container(
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

  Widget getBody() {
    return Column(
      children: [_getPlayArea()],
    );
  }

  Widget _getPlayArea() {
    return SuperPlayerView(_controller);
  }

  Widget _getListArea() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: ListView.builder(
        itemCount: videoModels.length,
        itemBuilder: (context, i) => _buildVideoItem(videoModels[i]),
      ),
    );
  }

  Widget _buildVideoItem(SuperPlayerModel playModel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
            leading: Image.network(playModel.coverUrl),
            title: new Text(
              playModel.title,
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => playCurrentModel(playModel)),
        Divider()
      ],
    );
  }

  void playCurrentModel(SuperPlayerModel model) {
    _controller.playWithModelNeedLicence(model);
  }

  void initData() async {
    SuperPlayerModel model = SuperPlayerModel();
    model.videoURL = "http://1500005830.vod2.myqcloud.com/6c9a5118vodcq1500005830/48d0f1f9387702299774251236/gZyqjgaZmnwA.m4v";
    model.playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
    model.title = "Tencent Cloud Audio/Video";
    _controller.playWithModelNeedLicence(model);
  }
  
  @override
  void dispose() {
    // must invoke when page exit.
    _controller.releasePlayer();
    super.dispose();
  }
}
```

## Custom Development Guide 

The Player SDK for Flutter plugin encapsulates native player capabilities. We recommend you use the following methods for deep custom development:

- Perform custom development based on the VOD player SDK (the API class is `TXVodPlayerController`) or live player SDK (the API class is `TXLivePlayerController`). The project provides custom development demos in `DemoTXVodPlayer` and `DemoTXLivePlayer` in the `example` project.

- The Superplayer component `SuperPlayerController` encapsulates the Player SDK and provides simple UI interaction. The code is in the `example` directory. You can customize the Superplayer component as follows:

  Copy the Superplayer component code in `example/lib/superplayer` to your project for custom development.

## References

- [Player SDK](https://www.tencentcloud.com/zh/document/product/266/7836)

## Contact Us

- Communication & Feedback   
  Welcome to join our Telegram Group to communicate with our professional engineers! We are more than happy to hear from you~
  Click to join: [https://t.me/+EPk6TMZEZMM5OGY1](https://t.me/+EPk6TMZEZMM5OGY1)   
  Or scan the QR code   
  <img src="https://qcloudimg.tencent-cloud.cn/raw/79cbfd13877704ff6e17f30de09002dd.jpg" width="300px">    

