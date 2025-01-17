## Tencent Cloud Player SDK Flutter Plugin

[Simplified Chinese](https://cloud.tencent.com/document/product/881/81252)| English

## Audience

Some content in this document pertains to exclusive capabilities of Tencent Cloud. Please activate the relevant services on [Tencent Cloud](https://cloud.tencent.com/) before use. Unregistered users can register for a [free trial](https://cloud.tencent.com/login).

## **Upgrade Notes**

Starting from version 10.1 of the Player SDK for mobile (Android & iOS & Flutter), the version is built using the same playback core as "Tencent Video," resulting in a comprehensive optimization and upgrade of video playback capabilities.

Additionally, from this version onward, authorization verification for the "video playback" functional module will be added. **If your app already has a live streaming license or a short video license, you can continue to use it normally after upgrading to version 10.1,** and will not be affected by this change. You can log in to the [Tencent Cloud Vcube Console](https://console.cloud.tencent.com/vcube) to check your current license authorization information.

If you have never obtained the aforementioned license authorization **and need to use the live playback or on-demand playback features in the new version SDK (10.1 and above), you will need to purchase a specified license for authorization.** For details, please refer to the [Authorization Instructions](https://cloud.tencent.com/document/product/881/74199#.E6.8E.88.E6.9D.83.E8.AF.B4.E6.98.8E); if you do not need to use the related features or have not upgraded to the latest version of the SDK, you will not be affected by this change.

## Project Directory Structure

This directory contains the Tencent Cloud Player SDK Flutter plugin and demo source code, mainly demonstrating how to call interfaces and the most basic functionalities.

```
├── android                        // Player plugin Android source code
├── ios                            // Player plugin iOS source code
├── lib                            // Player plugin Dart source code
├── docs                           // Help documentation
├── superplayer_widget             // Player component
└── example                        // Player-related demo code
    ├── android                    // Android demo source code
    ├── ios                        // iOS demo source code
    └── lib                        // Examples of on-demand playback, live playback, and player component usage
```

## Player Branch Explanation

The default pub dependency is the Professional version of the player. **If you need to depend on other versions,** you can directly rely on our open-source [GitHub repository](https://github.com/LiteAVSDK/Player_Flutter).

**Dependency method is as follows:**

```yaml
super_player:
  git:
    url: https://github.com/LiteAVSDK/Player_Flutter
    path: Flutter
    ref: Player_Premium 
# You can specify the required version branch, commit, and release version through ref
```

### Branch Explanation

The Flutter player depends on TXLiteAVSDK. This project provides 3 branches; please integrate according to your business needs:

[main](https://github.com/LiteAVSDK/Player_Flutter/tree/main): Depends on TXLiteAVSDK_Player SDK, the default branch.

[Professional](https://github.com/LiteAVSDK/Player_Flutter/tree/Professional): Depends on TXLiteAVSDK_Professional SDK. If your project has already integrated TXLiteAVSDK_Professional SDK, you need to integrate this branch.

[Player_Premium](https://github.com/LiteAVSDK/Player_Flutter/tree/Player_Premium): Depends on TXLiteAVSDK_Player_Premium SDK, which includes value-added features such as external subtitles and multiple audio tracks, supported from version 11.7 onwards.

## Introduction to Flutter Player

The Tencent Cloud Video Player SDK is one of the sub-product SDKs of the audio and video terminal SDK (Tencent Cloud Video). Leveraging Tencent Cloud's powerful backend capabilities and AI technology, it provides a robust platform for video on-demand and live streaming playback. When combined with Tencent Cloud's on-demand or live streaming services, users can quickly experience smooth and stable playback performance. It covers a wide range of application scenarios to meet diverse customer needs, allowing clients to focus easily on their business development while enjoying a new experience of ultra-fast and high-definition playback.

- [Integration Guide](https://www.tencentcloud.com/document/product/266/51192): The Tencent Cloud Video Player Flutter plugin is based on the on-demand and live streaming playback SDK, supporting both Android and iOS platforms.

This project provides both on-demand and live streaming playback, allowing you to build your own playback services based on the player:

- [On-Demand Playback](https://www.tencentcloud.com/document/product/266/51748): `TXVodPlayerController` encapsulates the interface of the on-demand player SDK for both Android and iOS platforms. You can develop on-demand playback services by integrating `TXVodPlayerController`. For detailed usage examples, refer to `DemoTXVodPlayer`.
- [Live Streaming Playback](https://www.tencentcloud.com/document/product/266/64320): `TXLivePlayerController` encapsulates the interface of the live streaming player SDK for both Android and iOS platforms. You can develop live streaming services by integrating `TXLivePlayerController`. For detailed usage examples, refer to `DemoTXLivePlayer`.
- [Player API Documentation](https://www.tencentcloud.com/document/product/266/51191): This includes API usage instructions for player configuration, on-demand playback, and live streaming playback.

To reduce integration costs, a player component (UI-enabled player) is provided in the example, allowing you to set up video playback services with just a few lines of code. You can apply the relevant code of the playback component to your project based on your needs and adjust the UI and interaction details as required.

- [Player Component](https://www.tencentcloud.com/document/product/266/51193): The `SuperPlayerController` player component encapsulates both on-demand and live streaming functionalities, making it easy for you to integrate quickly and simply. For detailed usage examples, refer to `DemoSuperplayer`.

## Deep Customization Development Guide

The Tencent Cloud Player SDK Flutter plugin encapsulates the capabilities of the native player. If you wish to conduct deep customization development, it is recommended to use the following methods:

- For on-demand playback, use the interface class `TXVodPlayerController`, or for live streaming playback, use the interface class `TXLivePlayerController` for customization development. The project provides demo examples for customization development, which can be referenced in the example project’s `DemoTXVodPlayer` and `DemoTXLivePlayer`.

- The player component `SuperPlayerController` encapsulates both on-demand and live streaming functionalities while providing simple UI interactions. Since this part of the code is in the example directory, if you have customization needs for the player component, you can do the following:

  Import the relevant code of the player component, located in the directory: `Flutter/superplayer_widget`, into your project for customization development.

## Documentation Links

- [Player SDK Official Website](https://www.tencentcloud.com/document/product/266/7836)