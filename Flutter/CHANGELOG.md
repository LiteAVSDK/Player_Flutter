##### 分支描述：

main 分支：Android & iOS 端集成TXLiteAVSDK_Player lastest版本

Professional 分支：Android & iOS 端集成TXLiteAVSDK_Professional lastest版本

Player_Premium 分支：Android & iOS 端集成TXLiteAVSDK_Player_Premium lastest版本


#### Version: 11.8.0 2024.05.06

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 11.8.0.14176，tag：release_premium_v11.8.0
- set iOS TXLiteAVSDK_Player_Premium to 11.8.15669， tag：release_premium_v11.8.0

#### Version: 11.8.1 2024.05.22

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 11.8.0.14188，tag：release_premium_v11.8.1
- set iOS TXLiteAVSDK_Player_Premium to 11.8.15687， tag：release_premium_v11.8.1

#### Version: 11.9.0 2024.06.05

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 11.9.0.14445，tag：release_premium_v11.9.0
- set iOS TXLiteAVSDK_Player_Premium to 11.9.15963， tag：release_premium_v11.9.0
- Android compatible with high version Gradle
- The location of the superPlayerWidget has changed, integrating superPlayer will no longer include the source code of the superPlayerWidget
- Android picture-in-picture feature logic optimization, compatible with more models

#### Version: 11.9.1 2024.06.05

##### Features：

- fix playback failed when in pip after recover from lock screen
- TXVodPlayerController has introduced a new setStringOption interface for configuring extensions.
- The Flutter side's operation of the player can now affect the UI updates for playing and pausing in the picture-in-picture window.
- Fixed potential memory leak issues.
- Optimized the logic of superPlayer Widget 
- Fixed other known issues.

#### Version: 12.0.0 2024.08.21

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.0.0.14681，tag：release_premium_v12.0.0
- set iOS TXLiteAVSDK_Player_Premium to 12.0.16292， tag：release_premium_v12.0.0
- Live streaming replaces the new kernel.
- As the new kernel has been replaced, the live streaming live config currently only retains the properties of maxAutoAdjustCacheTime, minAutoAdjustCacheTime, connectRetryCount, and connectRetryInterval, with the rest of the parameters marked as deprecated.
- New interfaces have been added to live streaming: enableReceiveSeiMessage, showDebugView, setProperty, getSupportedBitrate, and setCacheParams.
- When playing live streaming, there is no longer a need to pass the playType parameter, which has been deprecated.
- The live streaming and on-demand demo pages have added logic to wait for the license to load successfully before playing.
- Other known issues have been fixed.