# super_player
腾讯云播放器SDK的Flutter插件

支持直播与点播，定制化的原生播放器

### 使用:

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
  flutter_super_player:
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

iOS原生采用`pod`方式进行依赖，编辑`podfile`文件，指定你的播放器版本，默认是Player版，目前SuperPlayer只支持Player版和Professional版，且不能和TRTC或UGC等其他SDK共存。如果项目本来用了TRTC版则需要升级到Professional版才可以使用SuperPlayer

```xml
pod 'SuperPlayer/Player', '3.4.5'//Player版
```

Professional版集成

```
pod 'SuperPlayer/Professional', '3.4.5'//Professional版
```

如果不指定版本，默认会安装最新的`SuperPlayer`

### Flutter 中调用

```xml
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_player/super_player.dart';

class TestSuperPlayer extends StatefulWidget {
  @override
  _TestSuperPlayerState createState() => _TestSuperPlayerState();
}

class _TestSuperPlayerState extends State<TestSuperPlayer> {

  SuperPlayerViewConfig _playerConfig;
  SuperPlayerViewModel _playerModel;
  SuperPlayerPlatformViewController _playerController;
  String _url = "http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv";
  int _appId = 0;
  String _fileId = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerConfig = SuperPlayerViewConfig();
    _playerModel = SuperPlayerViewModel();
    _playerModel.videoURL = _url;
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            ackgroundColor: Colors.blueGrey,
            title: const Text('SuperPlayer'),
        ),
        body: Builder(
        builder: (context) =>
        SafeArea(
            child: Container(
            color: Colors.blueGrey,
            child: Column(
                children: [
                AspectRatio(
                    aspectRatio: 16.0/9.0,
                    child:SuperPlayerVideo(
                        onCreated: (SuperPlayerPlatformViewController vc) {
                            _playerController = vc;
                            await _playerController.setPlayConfig(_playerConfig);
                            await _playerController.playWithModel(_playerModel);// 开始播放
                        },
                    )
                ),
                ],
            ),
            ),
        )
        ),
    );
  }

```


## 目录结构说明

本目录包含 Flutter 版 播放器(Player) SDK 和 Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├── android                    // 播放器插件android源代码
├── ios                        // 播放器插件iOS源代码
├── lib                        // 播放器插件dart源代码
└── example                    // 超级播放器组件
    ├── android                // android的demo 源代码
    |   ├── SuperPlayerKit     // android的超级播放器组件
    ├── ios                    // iOS的demo 源代码

```

# SDK 的 API 文档

## 简介

SuperPlayer是腾讯云开源的一款播放器组件，简单几行代码即可拥有类似腾讯视频强大的播放功能。包括横竖屏切换、清晰度选择、手势、小窗等基础功能，还支持视频缓存，软硬解切换，倍速播放等特殊功能。相比系统播放器，支持格式更多，兼容性更好，功能更强大。同时还支持直播流（flv+rtmp）播放，具备首屏秒开、低延迟的优点，清晰度无缝切换、直播时移等高级能力。

本播放器完全免费开源，不对播放地址来源做限制，可放心使用。
本播放器基于SuperPlayer的一个Flutter插件，同时支持android和iOS两个平台。

## 阅读对象

本文档部分内容为腾讯云专属能力，使用前请开通 [腾讯云](https://cloud.tencent.com/) 相关服务，未注册用户可注册账号 [免费试用](https://cloud.tencent.com/document/product/378/17985)。

## 快速集成

`pubspec.yaml`中增加配置

```yaml
  super_player:
    git:
      url: https://github.com/tencentyun/SuperPlayer
      path: Flutter
```

然后更新依赖包

添加原生配置

### 安卓配置

安卓依赖原生播放器SDK，把目录下`example/android/superplayerkit`文件夹复制到你的工程目录下，在`setings.gradle` 插入 `include ':superplayerkit'`，当然，你也可以去官网搜索自己的合适版本进行导入。

### iOS配置

iOS原生采用`pod`方式进行依赖，编辑`podfile`文件，指定你的播放器版本
```xml
pod 'SuperPlayer/Player', '3.3.9'
```

如果不指定版本，默认会安装最新的`SuperPlayer`

## 使用播放器

播放器主类为 `SuperPlayerVideo`，创建后即可播放视频。

```xml
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerConfig = SuperPlayerViewConfig();
    _playerModel = SuperPlayerViewModel();
    _playerModel.videoURL = _url;
  }
```

```xml
@override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            ackgroundColor: Colors.blueGrey,
            title: const Text('SuperPlayer'),
        ),
        body: Builder(
            builder: (context) =>
                SafeArea(
                    child: Container(
                        color: Colors.blueGrey,
                        child: Column(
                            children: [
                                AspectRatio(
                                    aspectRatio: 16.0/9.0,
                                    child:SuperPlayerVideo(
                                        onCreated: (SuperPlayerPlatformViewController vc) {
                                            _playerController = vc;
                                            await _playerController.setPlayConfig(_playerConfig);
                                            await _playerController.playWithModel(_playerModel);// 开始播放
                                        },
                                    )
                                ),
                            ],
                        ),
                    ),
                )
        ),
    );
  }
```

运行代码，可以看到视频在手机上播放，并且界面上大部分功能都处于可用状态。


![](https://camo.githubusercontent.com/b7914c8710c34ce2d71f2cd4f75c665a6bb169921159a40c6a9d677dcd28fb7f/68747470733a2f2f6d61696e2e71636c6f7564696d672e636f6d2f7261772f31323863343565646663373762333139343735383638633231636165633264652e706e67)

## 多清晰度

上面的示例代码只有一种清晰度，如果要添加多个清晰度，也非常简单。以直播为例，打开 [直播控制台](https://console.cloud.tencent.com/live/livemanage)，找到需要播放的直播流，进入详情。

![](https://camo.githubusercontent.com/1669e96d7e634b747d63f959a016a7e447bf501b20cbcf39b0b4fec0a661e20d/68747470733a2f2f6d61696e2e71636c6f7564696d672e636f6d2f7261772f65336565343736356232356139616461383964656133343162396362356366642e706e67)


这里有不同清晰度、不同格式的播放地址。推荐使用 FLV 地址播放，代码如下

```xml
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerConfig = SuperPlayerViewConfig();
    _playerModel = SuperPlayerViewModel();
    SuperPlayerUrl url1 = SuperPlayerUrl();
    url1.title = "超清";
    url1.url = "http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4.flv";

    SuperPlayerUrl url2 = SuperPlayerUrl();
    url2.title = "超清";
    url2.url = "http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4.flv";

    SuperPlayerUrl url3 = SuperPlayerUrl();
    url3.title = "超清";
    url3.url = "http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4.flv";

    _playerModel.multiVideoURLs = [url1, url2, url3];
    _playerModel.videoURL = url1.url;// 设置默认播放的清晰度
  }
```

```xml
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('SuperPlayer'),
      ),
      body: Builder(
        builder: (context) =>
        SafeArea(
          child: Container(
            color: Colors.blueGrey,
            child: Column(
              children: [
                AspectRatio(
                    aspectRatio: 16.0/9.0,
                    child:SuperPlayerVideo(
                      onCreated: (SuperPlayerPlatformViewController vc) async {
                        _playerController = vc;
                        await _playerController.setPlayConfig(_playerConfig);
                        await _playerController.playWithModel(_playerModel);// 开始播放
                      },
                    )
                ),
              ],
            ),
          ),
        )
      ),
    );
  }

```

在播放器中即可看到这几个清晰度，单击即可立即切换。

<img src="https://main.qcloudimg.com/raw/8cb10273fe2b6df81b36ddb79d0f4890.jpeg" width="670"/>

## 时移播放

播放器开启时移非常简单，您只需要在播放前配置好 appId。

```xml
SuperPlayerViewModel playModel = SuperPlayerViewModel();
playModel.appId = 1252463788;// 这里换成您的 appID
```

> appId 在【腾讯云控制台】>【[账号信息](https://console.cloud.tencent.com/developer)】中查看。

播放的直播流就能在下面看到进度条。往后拖动即可回到指定位置，单击【返回直播】可观看最新直播流。

<img src="https://main.qcloudimg.com/raw/a3a4a18819aed49b919384b782a13957.jpeg" width="670"/>

>时移功能处于公测申请阶段，如您需要可 [提交工单](https://console.cloud.tencent.com/workorder) 申请使用。

## FileId 播放
设置清晰度除了填写 url 外，更简单的使用方式是采用 fileId 播放。fileId 一般是在视频上传后，由服务器返回：
1. 客户端视频发布后，服务器会返回 fileId 到客户端。
2. 服务端视频上传，在 [确认上传](https://cloud.tencent.com/document/product/266/9757) 的通知中包含对应的 fileId。


如果文件已存在腾讯云，则可以进入 [媒资管理](https://console.cloud.tencent.com/vod/media) ，找到对应的文件。点开后在右侧视频详情中，可以看到 appId 和 fileId。


播放 fileId 的代码如下：

```xml
SuperPlayerViewModel playModel = SuperPlayerViewModel();
playModel.appId = 1252463788;// 这里换成您的 appID
SuperPlayerVideoId videoId = SuperPlayerVideoId();
videoId.fileId = "4564972819219071679";
playModel.videoId = videoId;

_playerController.playWithModel(playModel);
```

视频在上传后，后台会自动转码（所有转码格式请参考 [转码模板](https://console.cloud.tencent.com/vod/video-process/template)）。转码完成后，播放器会自动显示多个清晰度。

