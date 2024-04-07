## Player SDK for Flutter Plugin

English| [简体中文](./README.md)

## Directory Structure

This directory contains the demo source code of the Player SDK for Flutter plugin, which shows you how to call the APIs to implement basic features.

```
├── android                        // Demo source code of the Player for Android plugin
├── ios                            // Demo source code of the Player for iOS plugin
├── lib                            // Demo source code of the Player for Dart plugin
├── docs                           // Help documentation
├── superplayer_widget             // Superplayer component
└── example                        // Demo code related to player
    ├── android                    // Demo source code for Android
    ├── ios                        // Demo source code for iOS
    └── lib                        // Code samples for VOD and live players as well as Superplayer
```

## Branch Description

The Flutter player relies on the TXLiteAVSDK. This project provides 3 branches for integration based on business needs:

[main](https://github.com/LiteAVSDK/Player_Flutter/tree/main): relies on the TXLiteAVSDK_Player SDK, which is the default branch.

[Professional](https://github.com/LiteAVSDK/Player_Flutter/tree/Professional): relies on the TXLiteAVSDK_Professional SDK. If the TXLiteAVSDK_Professional SDK has already been integrated into the project, this branch needs to be integrated.

[Player_Premium](https://github.com/LiteAVSDK/Player_Flutter/tree/Player_Premium): relies on the TXLiteAVSDK_Player_Premium SDK, which includes value-added features such as external subtitles and multiple audio tracks, and is supported starting from version 11.7.

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

