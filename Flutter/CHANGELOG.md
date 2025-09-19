
#### Version: 12.8.0 2025.09.19

##### Features：

- set Android TXLiteAVSDK to 12.8.0.19279
- set iOS TXLiteAVSDK to 12.8.19666
- Fix known issue


#### Version: 12.7.4 2025.09.09

##### Features：

- Fix the issue of restoration failure on some Android devices with PIP


#### Version: 12.7.3 2025.09.03

##### Features：

- Fix the issue of invalid renderMode.


#### Version: 12.7.2 2025.08.29

##### Features：

- VOD supports the autoRotate configuration.
- set Android TXLiteAVSDK to 12.7.0.19083
- set iOS TXLiteAVSDK to 12.7.19324
- Fix known issue


#### Version: 12.7.1 2025.08.13

##### Features：

- Fix the issue where the Android screen has severe jagged edges in some cases.
- Fix the issue where rendering failure errors occur when Android stops playback.
- Fix the issue where Picture-in-Picture (PiP) restoration on Android sends an extra exit event.
- Fix known issue

#### Version: 12.7.0 2025.08.04

##### Features：

- set Android TXLiteAVSDK to 12.7.0.19072
- set iOS TXLiteAVSDK to 12.7.19272
- Fix the issue of abnormal display when restoring picture-in-picture
- fix known issue


#### Version: 12.6.2 2025.07.31

##### Features：

- set Android TXLiteAVSDK to 12.6.0.18891
- set iOS TXLiteAVSDK to 12.6.18894
- Fix the issue where the first frame is not displayed during pre-playback
- Fix the issue where clearing the last frame is ineffective
- fix known issue


#### Version: 12.6.1 2025.06.20

##### Features：

- fix known issue


#### Version: 12.6.0 2025.06.20

##### Features：

- set Android TXLiteAVSDK_Professional to 12.6.0.17772，tag：release_pro_v12.6.0
- set iOS TXLiteAVSDK_Professional to 12.6.18866， tag：release_pro_v12.6.0

#### Version: 12.5.1 2025.06.18

##### Features：

- set Android TXLiteAVSDK_Professional to 12.5.0.17576，tag：release_pro_v12.5.1
- set iOS TXLiteAVSDK_Professional to 12.5.18393， tag：release_pro_v12.5.1
- The `SuperPlayerPlugin` has added the `setDrmProvisionEnv` method for switching the DRM playback environment.
- Fixed an issue where the video screen could not be restored when returning to the foreground from the background while using SurfaceView on the Android side.
- Fix the issue where the UI component's fullscreen operation behaves unexpectedly on some older Android devices.

#### Version: 12.5.0 2025.05.08

##### Features：

- set Android TXLiteAVSDK_Professional to 12.5.0.17567，tag：release_pro_v12.5.0
- set iOS TXLiteAVSDK_Professional to 12.5.18359， tag：release_pro_v12.5.0
- Added the `setRenderMode` method to the player, allowing configuration of the tiling mode for video rendering.
- Fixed an issue on Android where the player screen would turn black after pausing, moving to the background, and then returning to the foreground.
- Optimized the delay of the first frame rendering in the Flutter player compared to event triggers.
- Improved the screen orientation switching logic of the `super_player_widget` component by unifying texture sharing between portrait and landscape modes, enhancing the user experience during orientation changes.
- On iOS, Picture-in-Picture (PiP) for live streaming will automatically switch to a layer-based playback mode for iOS 15.0 and above. [Inspired by live streaming practices, this uses `contentSource` to implement custom PiP rendering, avoiding playback glitches caused by PiP window resizing.]
- Added a simple license polling mechanism on the demo side to prevent playback failures due to prolonged network disconnections during the first launch.
- Fixed a memory leak issue in the Android Picture-in-Picture service under certain conditions.
- Resolved the issue where Android Picture-in-Picture resizing animations displayed a semi-transparent black shadow effect.
- On iOS, after calling `stopPlay`, the `startTime` is no longer cleared, aligning the behavior with the Android implementation.


#### Version: 12.4.2 2025.04.30

##### Features：

- Fix an issue where releasing the player would close the global Picture-in-Picture mode.



#### Version: 12.4.1 2025.04.02

##### Features：

- Remove the method of binding texture via the controller of TXPlayerVideo


#### Version: 12.4.0 2025.03.31

##### Features：

- set Android TXLiteAVSDK_Professional to 12.4.0.17372，tag：release_pro_v12.4.0
- set iOS TXLiteAVSDK_Professional to 12.4.17856， tag：release_pro_v12.4.0
- The Android picture-in-picture button icon can be hidden by passing an empty string.
- The binding method of the player texture for the controller parameter of TXPlayerVideo is no longer recommended. It is recommended to use the onRenderViewCreated method instead.
- Fix the issue where the window size and aspect ratio of the picture do not match when Android live streaming enters picture-in-picture mode.
- Fix the problem that after the player component enters full screen, the player listener is still on the portrait page.
- Fix the issue that when Android enters picture-in-picture mode, there is a semi-transparent black status bar at the top of some models during the transition animation.


#### Version: 12.3.1 2025.03.18

##### Features：

- set Android TXLiteAVSDK_Professional to 12.3.0.17122，tag：release_pro_v12.3.1
- TXPlayerVideo has added a new onRenderViewCreatedListener callback. After obtaining the viewId of TXPlayerVideo, you can set the viewId to the player when needed.
- Fix an issue that the picture-in-picture on iOS does not display correctly in the window in some cases.
- Fix an issue that the aspect ratio of the picture-in-picture window is incorrect on Android.
- Fix an issue that there is no picture after the player component returns from full screen.
- Fix an issue that long-term video playback causes memory overflow on iOS.
- Fix an issue that high-security-level DRM videos cannot be played on iOS.

### Version: 12.3.0 2025.01.21

#### Features：
- set Android TXLiteAVSDK_Professional to 12.3.0.17115，tag：release_pro_v12.3.0
- set iOS TXLiteAVSDK_Professional to 12.3.16995， tag：release_pro_v12.3.0


#### Version: 12.2.2 2024.12.30

##### Features：

- Fix the issue where Android crashes when restoring from PIP.


#### Version: 12.2.1 2024.12.27

##### Features：

- set Android TXLiteAVSDK_Professional to 12.2.0.15072，tag：release_pro_v12.2.1
- set iOS TXLiteAVSDK_Professional to 12.2.16956， tag：release_pro_v12.2.1
- Fix the issue that picture-in-picture cannot be launched on some Android systems.
- Fix the issue of abnormal use after cold startup on some Android systems.
- Fix the issue that there is no subtitle callback without setting config on iOS.
- Fix the issue that there is no callback in some cases of downloading and pre-downloading.
- Add DRM playback API.
- Fix other known issues.


#### Version: 12.2.0 2024.12.04

##### Features：

- set Android TXLiteAVSDK_Professional to 12.2.0.15065，tag：release_pro_v12.2.0
- set iOS TXLiteAVSDK_Professional to 12.2.16945， tag：release_pro_v12.2.0
- Pre-download supports httpHeader
- Supports encrypted playback of MP4
- Added support for HEVC playback downgrade
- Fix other known issues.


#### Version: 12.1.0 2024.11.20

##### Features：

- set Android TXLiteAVSDK_Professional to 12.1.0.14886，tag：release_pro_v12.1.0
- set iOS TXLiteAVSDK_Professional to 12.1.16597， tag：release_pro_v12.1.0
- Fix the issue of reversed logic in the live streaming mute method.
- iOS adds support for Picture-in-Picture for live streaming, which requires premium permission to use.
- Fix other known issues.


#### Version: 12.0.1 2024.09.14

##### Features：

- set Android TXLiteAVSDK_Professional to 12.0.0.14689，tag：release_pro_v12.0.1
- set iOS TXLiteAVSDK_Professional to 12.1.16597， tag：release_pro_v12.0.1
- Fix the issue where textures are not refreshed in some cases
- Fix the issue where updating Picture-in-Picture produces errors when Picture-in-Picture ends in some cases
- Modify the plugin callback Flutter side message architecture
- During SDK initialization, all modules are changed to lazy loading
- The demo and player components no longer need to force set the language; if not set, it defaults to English


#### Version: 12.0.0 2024.08.21

##### Features：

- set Android TXLiteAVSDK_Professional to 12.0.0.14681，tag：release_pro_v12.0.0
- set iOS TXLiteAVSDK_Professional to 12.0.16292， tag：release_pro_v12.0.0
- Live streaming replaces the new kernel.
- As the new kernel has been replaced, the live streaming live config currently only retains the properties of maxAutoAdjustCacheTime, minAutoAdjustCacheTime, connectRetryCount, and connectRetryInterval, with the rest of the parameters marked as deprecated.
- New interfaces have been added to live streaming: enableReceiveSeiMessage, showDebugView, setProperty, getSupportedBitrate, and setCacheParams.
- When playing live streaming, there is no longer a need to pass the playType parameter, which has been deprecated.
- The live streaming and on-demand demo pages have added logic to wait for the license to load successfully before playing.
- Other known issues have been fixed.


#### Version: 11.9.1 2024.06.05

##### Features：

- fix playback failed when in pip after recover from lock screen
- TXVodPlayerController has introduced a new setStringOption interface for configuring extensions.
- The Flutter side's operation of the player can now affect the UI updates for playing and pausing in the picture-in-picture window.
- Fixed potential memory leak issues.
- Optimized the logic of superPlayer Widget
- Fixed other known issues.


#### Version: 11.9.0 2024.06.05

##### Features：

- set Android TXLiteAVSDK_Professional to 11.9.0.14445，tag：release_pro_v11.9.0
- set iOS TXLiteAVSDK_Professional to 11.9.15963， tag：release_pro_v11.9.0
- Android compatible with high version Gradle
- The location of the superPlayerWidget has changed, integrating superPlayer will no longer include the source code of the superPlayerWidget
- Android picture-in-picture feature logic optimization, compatible with more models


#### Version: 11.8.1 2024.05.22

##### Features：

- set Android TXLiteAVSDK_Professional to 11.8.0.14188，tag：release_pro_v11.8.1
- set iOS TXLiteAVSDK_Professional to 11.8.15687， tag：release_pro_v11.8.1


#### Version: 11.8.0 2024.05.06

##### Features：

- set Android TXLiteAVSDK_Professional to 11.8.0.14176，tag：release_pro_v11.8.0
- set iOS TXLiteAVSDK_Professional to 11.8.15669， tag：release_pro_v11.8.0


#### Version: 11.7.0 2024.04.02

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.7.0.13946，tag：release_pro_v11.7.0
- set iOS TXLiteAVSDK_Professional to 11.7.15343， tag：release_pro_v11.7.0
- Add setSDKListener in SuperPlayerPlugin
- fix known issues


#### Version: 11.6.1 2024.01.29

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.6.0.13641，tag：release_pro_v11.6.1
- set iOS TXLiteAVSDK_Professional to 11.6.15041， tag：release_pro_v11.6.1
- superPlayerWidget add renderMode config
- superPlayerWidget add stopPlay method
- vod/live dispose method can await now
- fix known issues


#### Version: 11.6.0 2024.01.11

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.6.0.13613，tag：release_pro_v11.6.0
- set iOS TXLiteAVSDK_Professional to 11.6.15007， tag：release_pro_v11.6.0
- Adapt the Flutter player to the new version of the Flutter SDK
- fix player and player's widget known issues


#### Version: 11.4.1 2023.12.20

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.4.0.13270，tag：release_pro_v11.4.1
- set iOS TXLiteAVSDK_Professional to 11.4.14552， tag：release_pro_v11.4.1
- add fileId pre-download capability
- fix known issues


#### Version: 11.4.0 2023.08.30

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.4.0.13189，tag：release_pro_v11.4.0
- set iOS TXLiteAVSDK_Professional to 11.4.14445， tag：release_pro_v11.4.0


#### Version: 11.3.0 2023.07.07

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.3.0.13171，tag：release_pro_v11.3.0
- set iOS TXLiteAVSDK_Professional to 11.3.14327， tag：release_pro_v11.3.0


#### Version: 11.2.0 2023.06.05

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.2.0.13154，tag：release_pro_v11.2.0
- set iOS TXLiteAVSDK_Professional to 11.2.14217， tag：release_pro_v11.2.0


#### Version: 11.1.1 2023.05.08

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.1.0.13141，tag：release_pro_v11.1.1
- set iOS TXLiteAVSDK_Professional to 11.1.14143， tag：release_pro_v11.1.1


#### Version: 11.1.0 2023.04.10

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.1.0.13111，tag：release_pro_v11.1.0
- set iOS TXLiteAVSDK_Professional to 11.1.14125， tag：release_pro_v11.1.0


#### Version: 11.0.0 2023.03.20

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 11.0.0.13129，tag：release_pro_v11.0.0
- set iOS TXLiteAVSDK_Professional to 11.0.14032， tag：release_pro_v11.0.0


#### Version: 10.9.1  2023.02.24

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.9.0.13102，tag：release_pro_v10.9.1
- set iOS TXLiteAVSDK_Professional to 10.9.13161， tag：release_pro_v10.9.1


#### Version: 10.9.0  2023.01.03

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.9.0.13092，tag：release_pro_v10.9.0
- set iOS TXLiteAVSDK_Professional to 10.9.13148， tag：release_pro_v10.9.0


#### Version: 10.8.0_stable  2022.12.01

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.8.0.13065，tag：release_pro_v10.8.0_stable
- set iOS TXLiteAVSDK_Professional to 10.8.12025， tag：release_pro_v10.8.0_stable


#### Version: 10.8.0  2022.12.01

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.8.0.13052，tag：release_pro_v10.8.0
- set iOS TXLiteAVSDK_Professional to 10.8.12015， tag：release_pro_v10.8.0


#### Version: 1.0.7  2022.10.27

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.7.0.13053，tag：release_pro_v1.0.7
- set iOS TXLiteAVSDK_Professional to 10.7.11936， tag：release_pro_v1.0.7


#### Version: 1.0.6  2022.09.19

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.6.0.11182，tag：release_pro_v1.0.6
- set iOS TXLiteAVSDK_Professional to 10.6.11822， tag：release_pro_v1.0.6


#### Version: 1.0.5  2022.09.02
##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.5.0.11177，tag：release_pro_v1.0.5
- set iOS TXLiteAVSDK_Professional to 10.5.11726， tag：release_pro_v1.0.5


#### Version: 1.0.4  2022.08.16

##### 版本特性：

- set Android TXLiteAVSDK_Professional to 10.4.0.11168，tag：release_pro_v1.0.4
- set iOS TXLiteAVSDK_Professional to 10.4.11619， tag：release_pro_v1.0.4


#### Version: 1.0.3  2022.07.13

##### 版本特性：

- iOS端新增画中画（PIP) 功能
- set Android TXLiteAVSDK_Professional to 10.3.0.11144，tag：release_player_v1.0.3
- set iOS TXLiteAVSDK_Professional to 10.3.11513， tag：release_pro_v1.0.3


#### Version: 1.0.2  2022.07.05

##### 版本特性：

- Android 端新增画中画（PIP) 功能
- 播放器组件（superplayer）用Dart重写，方便自定义集成
- 修复通过appId 、fileId和 psign 播放失败问题

- set Android TXLiteAVSDK_Professional to 10.2.0.11131，tag：release_player_v1.0.2
- set iOS TXLiteAVSDK_Professional to 10.2.11418， tag：release_pro_v1.0.2


