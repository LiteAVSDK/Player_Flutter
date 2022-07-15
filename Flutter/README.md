## 腾讯云播放器SDK Flutter插件

简体中文| [English](./README-EN.md)

## 工程目录结构说明

本目录包含腾讯云播放器SDK Flutter 插件 和 Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├── android                        // 播放器插件android源代码
├── ios                            // 播放器插件iOS源代码
├── lib                            // 播放器插件dart源代码
├── docs                           // 帮助文档
└── example                        // 播放器相关demo代码
    ├── android                    // android的demo源代码
    ├── ios                        // iOS的demo源代码
    └── lib                        // 点播播放、直播播放、播放器组件使用例子
```

## 项目简介

腾讯云视立方·播放器 SDK 是音视频终端 SDK（腾讯云视立方）的子产品 SDK 之一，基于腾讯云强大的后台能力与 AI 技术，提供视频点播和直播播放能力的强大播放载体。结合腾讯云点播或云直播使用，可以快速体验流畅稳定的播放性能。充分覆盖多类应用场景，满足客户多样需求，让客户轻松聚焦于业务发展本身，畅享极速高清播放新体验。

此项目提供了点播播放和直播播放，您可以基于播放器搭建自己的播放业务：

- [点播播放](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%82%B9%E6%92%AD%E6%92%AD%E6%94%BE.md)：`TXVodPlayerController`对Android和iOS两个平台的点播播放器SDK进行接口封装， 你可以通过集成`TXVodPlayerController`进行点播播放业务开发。详细使用例子可以参考`DemoTXVodPlayer`。

- [直播播放](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%9B%B4%E6%92%AD%E6%92%AD%E6%94%BE.md)：`TXLivePlayerController`对Android和iOS两个平台的直播播放器SDK进行接口封装， 你可以通过集成`TXLivePlayerController`进行直播播放业务开发。详细使用例子可以参考`DemoTXLivePlayer`。

为了减少接入成本， 在example里提供了播放器组件（带UI的播放器），基于播放器组件简单的几行代码就可以搭建视频播放业务。您可以根据自己项目的需求， 把播放组件的相关代码应用到项目中去，根据需求进行调整UI和交互细节。

- [播放器组件](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E6%92%AD%E6%94%BE%E5%99%A8%E7%BB%84%E4%BB%B6.md)：`SuperPlayerController` 播放器组件，对点播和直播进行了二次封装，可以方便你快速简单集成。目前是Beta版本，功能还在完善中。详细使用例子可以参考`DemoSuperplayer`。

## 阅读对象

本文档部分内容为腾讯云专属能力，使用前请开通 [腾讯云](https://cloud.tencent.com/) 相关服务，未注册用户可注册账号 [免费试用](https://cloud.tencent.com/login)。

## **升级说明**

播放器 SDK 移动端10.1（Android & iOS & Flutter）开始 版本采用“腾讯视频”同款播放内核打造，视频播放能力获得全面优化升级。

同时从该版本开始将增加对“视频播放”功能模块的授权校验，**如果您的APP已经拥有直播推流 License 或者短视频 License 授权，当您升级至10.1 版本后仍可以继续正常使用，**不受到此次变更影响，您可以登录 [腾讯云视立方控制台](https://console.cloud.tencent.com/vcube) 查看您当前的 License 授权信息。

如果您在此之前从未获得过上述License授权**，且需要使用新版本SDK（10.1及其更高版本）中的直播播放或点播播放功能，则需购买指定 License 获得授权**，详情参见[授权说明](https://cloud.tencent.com/document/product/881/74199#.E6.8E.88.E6.9D.83.E8.AF.B4.E6.98.8E)；若您无需使用相关功能或未升级至最新版本SDK，将不受到此次变更的影响。

## 快速集成

### `pubspec.yaml`配置

**推荐flutter sdk 版本 3.0.0 及以上**

集成LiteAVSDK_Player版本，默认情况下也是集成此版本。在`pubspec.yaml`中增加配置

```yaml
super_player:
  git:
    url: https://github.com/LiteAVSDK/Player_Flutter
    path: Flutter
```

如果要集成LiteAVSDK_Professional版本，则`pubspec.yaml`中配置改为

```yaml
super_player:
  git:
    url: https://github.com/LiteAVSDK/Player_Flutter
    path: Flutter
    ref: Professional
```

然后更新依赖包

```yaml
flutter packages get
```

### 添加原生配置

#### 安卓配置

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

#### iOS配置

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
pod 'TXLiteAVSDK_Player'	        //Player版
```

Professional版SDK集成

```
pod 'TXLiteAVSDK_Professional' 	//Professional版
```

如果不指定版本，默认会安装最新的`TXLiteAVSDK_Player`最新版本

### 集成过程中常见问题

执行`flutter doctor`命令检查运行环境，直到出现”No issues found!“。

执行`flutter pub get`确保所有依赖的组件都已更新成功。

## 申请视频播放能力License和集成

若您已获得相关License授权，需在[腾讯云视立方控制台](https://console.cloud.tencent.com/vcube) 获取License URL和License Key；

[![image](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)](https://user-images.githubusercontent.com/88317062/169646279-929248e3-8ded-4b9e-8b04-2b6e462054a0.png)

若您暂未获得License授权，需先参考[视频播放License](https://cloud.tencent.com/document/product/881/74588)获取相关授权

集成播放器前，需要[注册腾讯云账户](https://cloud.tencent.com/login)，注册成功后申请视频播放能力License， 然后通过下面方式集成，建议在应用启动时进行。

如果没有集成license，播放过程中可能会出现异常。

```dart
String licenceURL = ""; // 获取到的 licence url
String licenceKey = ""; // 获取到的 licence key
SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
```

## 点播播放使用

点播播放核心类`TXVodPlayerController`，详细Demo可参考`DemoTXVodPlayer`。

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
    String licenceUrl = ""; // 获取到的 licence url
    String licenseKey = ""; // 获取到的 licence key
    SuperPlayerPlugin.setGlobalLicense(licenceUrl, licenseKey);
    _controller = TXVodPlayerController();
    initPlayer();
  }

  Future<void> initPlayer() async {
    await _controller.initialize();
    await _controller.setConfig(FTXVodPlayConfig());
    await _controller.startPlay(_url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Container(
                    height: 220,
                    color: Colors.black,
                    child: AspectRatio(aspectRatio: _aspectRatio, child: TXPlayerVideo(controller: _controller))));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```
## 播放器组件使用

播放器组件核心类`SuperPlayerVideo`，创建后即可播放视频。

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

  @override
  void dispose() {
    // must invoke when page exit.
    _controller.releasePlayer();
    super.dispose();
  }
}
```

## 视频下载能力的使用

### 预下载

视频预下载能力依赖于`TXVodDownloadController`,使用其可对视频进行预下载和监听

**接口**

- 预下载视频

```dart
int taskId = await TXVodDownloadController.instance.startPreLoad(_url, 20, 720*1080,
        onCompleteListener:(int taskId,String url) {
          print('taskID=${taskId} ,url=${url}');
        }, onErrorListener: (int taskId, String url, int code, String msg) {
          print('taskID=${taskId} ,url=${url}, code=${code} , msg=${msg}');
        } );
```

- 停止预下载

```dart
TXVodDownloadController.instance.stopPreLoad(taskId);
```

taskId从启动预下载的接口获得

### 视频下载

视频下载能力依赖于`TXVodDownloadController`,使用其可对视频进行下载和监听

**接口**

- 下载视频

```dart
TXVodDownloadMedialnfo downloadMedialnfo = TXVodDownloadMedialnfo();
TXVodDownloadDataSource dataSource = TXVodDownloadDataSource();
dataSource.appId = appId;
dataSource.fileId = fileId;
dataSource.pSign = pSign;
downloadMedialnfo.dataSource = dataSource;
TXVodDownloadController.instance.startDonwload(downloadMedialnfo);
```

也可以使用url下载。

```dart
TXVodDownloadMedialnfo downloadMedialnfo = TXVodDownloadMedialnfo();
downloadMedialnfo.url = videoUrl;
TXVodDownloadController.instance.startDonwload(downloadMedialnfo);
```

视频url下载不支持嵌套m3u8和mp4下载。
下载也可以指定username，用来区分不同用户的下载，不传递的话，默认为default

```dart
downloadMedialnfo.userName = username;
```

- 停止下载

```dart
TXVodDownloadController.instance.stopDownload(downloadMedialnfo);
```

- 设置下载请求头

针对部分视频下载的时候，需要设置额外的请求头

```dart
TXVodDownloadController.instance.setDownloadHeaders(headers);
```

- 获得视频的下载信息

该接口可以获得下载中或者已经下载视频的下载信息，可以获得视频的当前缓存地址

```dart
TXVodDownloadController.instance.getDownloadInfo(downloadMedialnfo);
```

- 获得所有视频的下载信息

```dart
TXVodDownloadController.instance.getDownloadList();
```

- 设置视频下载监听

该接口设置的视频下载监听为全局监听，所有视频的下载进度都会在该方法中回调，重复调用的话会前后覆盖

```dart
TXVodDownloadController.instance.setDownloadObserver((event, info) {
// donwload state $event ,donwload info $info
}, (errorCode, errorMsg, info) {
// donwload error code $errorCode,error msg $errorMsg
});
```

- 视频下载事件

| 参数名 | 值   | 描述               |
| ------ | ------ | ------------------ |
| NO_ERROR | 301 | 视频下载开始 |
| EVENT_DOWNLOAD_PROGRESS | 302 | 视频下载中，进度回调 |
| EVENT_DOWNLOAD_STOP | 303 | 视频下载停止 |
| EVENT_DOWNLOAD_FINISH | 304 | 视频下载完成 |
| EVENT_DOWNLOAD_ERROR | 305 | 视频下载错误 |


## 深度定制开发指引 

腾讯云播放器SDK Flutter插件对原生播放器能力进行了封装， 如果您要进行深度定制开发，建议采用如下方法：

- 基于点播播放，接口类为`TXVodPlayerController` 或直播播放，接口类为`TXLivePlayerController`，进行定制开发，项目中提供了定制开发Demo，可参考example工程里的`DemoTXVodPlayer`和`DemoTXLivePlayer`。

- 播放器组件`SuperPlayerController` 对点播和直播进行了封装，同时提供了简单的UI交互， 由于此部分代码在example目录。如果您有对播放器组件定制化的需求，您可以进行如下操作：

  把播放器组件相关的代码，代码目录：`exmple/lib/superplayer`，复制到您的项目中，进行定制化开发。

## 文档链接

- [播放器SDK官网](https://cloud.tencent.com/document/product/881)
