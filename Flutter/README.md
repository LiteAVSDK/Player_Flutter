## 腾讯云播放器SDK Flutter插件

简体中文| [English](./README-EN.md)

## 阅读对象

本文档部分内容为腾讯云专属能力，使用前请开通 [腾讯云](https://cloud.tencent.com/) 相关服务，未注册用户可注册账号 [免费试用](https://cloud.tencent.com/login)。

## **升级说明**

播放器 SDK 移动端10.1（Android & iOS & Flutter）开始 版本采用“腾讯视频”同款播放内核打造，视频播放能力获得全面优化升级。

同时从该版本开始将增加对“视频播放”功能模块的授权校验，**如果您的APP已经拥有直播推流 License 或者短视频 License 授权，当您升级至10.1 版本后仍可以继续正常使用，**不受到此次变更影响，您可以登录 [腾讯云视立方控制台](https://console.cloud.tencent.com/vcube) 查看您当前的 License 授权信息。

如果您在此之前从未获得过上述License授权**，且需要使用新版本SDK（10.1及其更高版本）中的直播播放或点播播放功能，则需购买指定 License 获得授权**，详情参见[授权说明](https://cloud.tencent.com/document/product/881/74199#.E6.8E.88.E6.9D.83.E8.AF.B4.E6.98.8E)；若您无需使用相关功能或未升级至最新版本SDK，将不受到此次变更的影响。

## 工程目录结构说明

本目录包含腾讯云播放器SDK Flutter 插件 和 Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├── android                        // 播放器插件android源代码
├── ios                            // 播放器插件iOS源代码
├── lib                            // 播放器插件dart源代码
├── docs                           // 帮助文档
├── superplayer_widget             // 播放器组件
└── example                        // 播放器相关demo代码
    ├── android                    // android的demo源代码
    ├── ios                        // iOS的demo源代码
    └── lib                        // 点播播放、直播播放、播放器组件使用例子
```

## Flutter播放器简介

腾讯云视立方·播放器 SDK 是音视频终端 SDK（腾讯云视立方）的子产品 SDK 之一，基于腾讯云强大的后台能力与 AI 技术，提供视频点播和直播播放能力的强大播放载体。结合腾讯云点播或云直播使用，可以快速体验流畅稳定的播放性能。充分覆盖多类应用场景，满足客户多样需求，让客户轻松聚焦于业务发展本身，畅享极速高清播放新体验。

- [集成指引](./docs/集成指引.md)：腾讯云视立方 Flutter 播放器是基于点播和直播播放SDK的一个 Flutter 插件，同时支持 Android 和 iOS 两个平台。

此项目提供了点播播放和直播播放，您可以基于播放器搭建自己的播放业务：

- [点播播放](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%82%B9%E6%92%AD%E6%92%AD%E6%94%BE.md)：`TXVodPlayerController`对Android和iOS两个平台的点播播放器SDK进行接口封装， 你可以通过集成`TXVodPlayerController`进行点播播放业务开发。详细使用例子可以参考`DemoTXVodPlayer`。
- [直播播放](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E7%9B%B4%E6%92%AD%E6%92%AD%E6%94%BE.md)：`TXLivePlayerController`对Android和iOS两个平台的直播播放器SDK进行接口封装， 你可以通过集成`TXLivePlayerController`进行直播播放业务开发。详细使用例子可以参考`DemoTXLivePlayer`。
- [播放器API文档](./docs/API文档.md)：包含播放器配置、点播播放和直播播放等API使用说明。

为了减少接入成本， 在example里提供了播放器组件（带UI的播放器），基于播放器组件简单的几行代码就可以搭建视频播放业务。您可以根据自己项目的需求， 把播放组件的相关代码应用到项目中去，根据需求进行调整UI和交互细节。

- [播放器组件](https://github.com/LiteAVSDK/Player_Flutter/blob/main/Flutter/docs/%E6%92%AD%E6%94%BE%E5%99%A8%E7%BB%84%E4%BB%B6.md)：`SuperPlayerController` 播放器组件，对点播和直播进行了二次封装，可以方便你快速简单集成。目前是Beta版本，功能还在完善中。详细使用例子可以参考`DemoSuperplayer`。


## 深度定制开发指引 

腾讯云播放器SDK Flutter插件对原生播放器能力进行了封装， 如果您要进行深度定制开发，建议采用如下方法：

- 基于点播播放，接口类为`TXVodPlayerController` 或直播播放，接口类为`TXLivePlayerController`，进行定制开发，项目中提供了定制开发Demo，可参考example工程里的`DemoTXVodPlayer`和`DemoTXLivePlayer`。

- 播放器组件`SuperPlayerController` 对点播和直播进行了封装，同时提供了简单的UI交互， 由于此部分代码在example目录。如果您有对播放器组件定制化的需求，您可以进行如下操作：

  把播放器组件相关的代码，代码目录：`Flutter/superplayer_widget`，导入到您的项目中，进行定制化开发。

## 文档链接

- [播放器SDK官网](https://cloud.tencent.com/document/product/881)
