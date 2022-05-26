## 腾讯云播放器SDK Flutter插件

## 工程目录结构说明

本目录包含腾讯云播放器SDK Flutter 插件 和 Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├── android                    // 播放器插件android源代码
├── ios                        // 播放器插件iOS源代码
├── lib                        // 播放器插件dart源代码
├── docs                       // 帮助文档
└── example                    // 超级播放器组件
    ├── android                // android的demo 源代码
    ├── ios                    // iOS的demo 源代码
    ├── lib                    // 点播播放器、直播播放器、超播放器使用例子
```

## 简介

腾讯云视立方·播放器 SDK 是音视频终端 SDK（腾讯云视立方）的子产品 SDK 之一，基于腾讯云强大的后台能力与 AI 技术，提供视频点播和直播播放能力的强大播放载体。结合腾讯云点播或云直播使用，可以快速体验流畅稳定的播放性能。充分覆盖多类应用场景，满足客户多样需求，让客户轻松聚焦于业务发展本身，畅享极速高清播放新体验。

此项目提供了：

点播播放器SDK：`TXVodPlayerController`对Android和iOS两个平台的点播播放器SDK进行接口封装， 你可以通过集成`TXVodPlayerController`进行点播播放业务开发。

直播播放器SDK：`TXLivePlayerController`对Android和iOS两个平台的直播播放器SDK进行接口封装， 你可以通过集成`TXLivePlayerController`进行直播播放业务开发。

超级播放器组件：`SuperPlayerController` 超级播放器组件，对点播和直播SDK进行了二次封装，可以方便你快速简单集成。目前是Beta版本，功能还在完善中。

## **升级说明**

播放器 SDK 移动端10.1（Android & iOS & Flutter）开始 版本采用“腾讯视频”同款播放内核打造，视频播放能力获得全面优化升级。

同时从该版本开始将增加对“视频播放”功能模块的授权校验，**如果您的APP已经拥有直播推流 License 或者短视频 License 授权，当您升级至10.1 版本后仍可以继续正常使用，**不受到此次变更影响，您可以登录 [腾讯云视立方控制台](https://console.cloud.tencent.com/vcube) 查看您当前的 License 授权信息。

如果您在此之前从未获得过上述License授权**，且需要使用新版本SDK（10.1及其更高版本）中的直播播放或点播播放功能，则需购买指定 License 获得授权**，详情参见授权说明；若您无需使用相关功能或未升级至最新版本SDK，将不受到此次变更的影响。

## 阅读对象

本文档部分内容为腾讯云专属能力，使用前请开通 [腾讯云](https://cloud.tencent.com/) 相关服务，未注册用户可注册账号 [免费试用](https://cloud.tencent.com/login)。

## 快速集成

`pubspec.yaml`中增加配置

```yaml
super_player:
  git:
    url: https://github.com/tencentyun/SuperPlayer
    path: Flutter
```

然后更新依赖包

```yaml
flutter packages get
```

如果使用Professional版本，则`pubspec.yaml`中配置改为

```yaml
super_player:
  git:
    url: https://github.com/tencentyun/SuperPlayer
    path: Flutter
    ref: Professional
```

添加原生配置

### 安卓配置

在Android的`AndroidManifest.xml`中增加如下配置

```xml
<!--网络权限-->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<!--点播播放器悬浮窗权限-->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<!--存储-->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS配置

在iOS的`Info.plist`中增加如下配置

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

iOS原生采用`pod`方式进行依赖，编辑`podfile`文件，指定你的播放器SDK版本，默认是集成的是Player 版SDK，

```xml
pod 'TXLiteAVSDK_Player'		//Player版
```

Professional版SDK集成

```
pod 'TXLiteAVSDK_Professional' 	//Professional版
```

如果不指定版本，默认会安装最新的`TXLiteAVSDK_Player`最新版本

### 集成过程中常见问题

执行`flutter doctor`命令检查运行环境，知道出现”No issues found!“。

执行`flutter pub get`确保所有依赖的组件都已更新成功。

## 使用超级播放器组件

### 步骤1：申请视频播放能力License和集成

若您已获得相关License授权，需在[腾讯云视立方控制台](https://console.cloud.tencent.com/vcube) 获取License URL和License Key；

[![image](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)

若您暂未获得License授权，需先参考[视频播放License](https://cloud.tencent.com/document/product/881)获取相关授权

集成播放器前，需要[注册腾讯云账户](https://cloud.tencent.com/login)，注册成功后申请视频播放能力License， 然后通过下面方式集成，建议在应用启动时进行。

如果没有集成license，播放过程中可能会出现异常。

```dart
String licenceURL = ""; // 获取到的 licence url
String licenceKey = ""; // 获取到的 licence key
SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
```

### 步骤2：超级播放器使用

超级播放器核心类`SuperPlayerVideo`，创建后即可播放视频。

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
    String licenceUrl = "填入您购买的 license 的 url";
    String licenseKey = "填入您购买的 license 的 key";
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
    _controller.playWithModel(model);
  }

  void initData() async {
    SuperPlayerModel model = SuperPlayerModel();
    model.videoURL = "http://1500005830.vod2.myqcloud.com/6c9a5118vodcq1500005830/48d0f1f9387702299774251236/gZyqjgaZmnwA.m4v";
    model.playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
    model.title = "腾讯云音视频";
    _controller.playWithModel(model);
  }
}
```

### FileId 播放
设置清晰度除了填写 url 外，更简单的使用方式是采用 fileId 播放。fileId 一般是在视频上传后，由服务器返回：
1. 客户端视频发布后，服务器会返回 fileId 到客户端。
2. 服务端视频上传，在 [确认上传](https://cloud.tencent.com/document/product/266/9757) 的通知中包含对应的 fileId。


如果文件已存在腾讯云，则可以进入 [媒资管理](https://console.cloud.tencent.com/vod/media) ，找到对应的文件。点开后在右侧视频详情中，可以看到 appId 和 fileId。


播放 fileId 的代码如下：

```dart
SuperPlayerModel model = SuperPlayerModel();
model.appId = 1500005830;  //替换成您的appId
model.videoId = new SuperPlayerVideoId();
model.videoId.fileId = "8602268011437356984";    //替换成您的fileId
model.title = "云点播";
model.playAction = SuperPlayerModel.PLAY_ACTION_AUTO_PLAY;
_controller.playWithModel(model);
```

视频在上传后，后台会自动转码（所有转码格式请参考 [转码模板](https://console.cloud.tencent.com/vod/video-process/template)）。转码完成后，播放器会自动显示多个清晰度。

## 深度定制开发指引 

腾讯云播放器SDK Flutter插件对原生播放器能力进行了封装， 如果您要进行深度定制开发，建议采用如下方法：

- 基于点播播放器SDK，接口类为`TXVodPlayerController` 或直播播放器SDK，接口类为`TXLivePlayerController`，进行定制开发，项目中提供了定制开发Demo，可参考example工程里的`DemoTXVodPlayer`和`DemoTXLivePlayer`。

- 超级播放器组件`SuperPlayerController` 对播放器SDK进行了封装，同时提供了简单的UI交互， 由于此部分代码在lib层， 所以无法进行修改。如果您有对超级播放器组件定制化的需求，您可以进行如下操作：

  Fork [Player_Flutter](https://github.com/LiteAVSDK/Player_Flutter) 到私人的github，然后进行定制化开发，最后集成到您的项目中。

  或者把超级播放器组件相关的代码，代码目录：`lib/Core/superplayer`，复制到您的项目中，进行定制化开发。

## 文档链接

- [播放器SDK官网](https://cloud.tencent.com/document/product/881)

