
#### Version: 12.6.0 2025.06.20

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.6.0.17772，tag：release_premium_v12.6.0
- set iOS TXLiteAVSDK_Player_Premium to 12.6.18866， tag：release_premium_v12.6.0

#### Version: 12.5.1 2025.06.18

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.5.0.17576，tag：release_premium_v12.5.1
- set iOS TXLiteAVSDK_Player_Premium to 12.5.18393， tag：release_premium_v12.5.1
- The `SuperPlayerPlugin` has added the `setDrmProvisionEnv` method for switching the DRM playback environment.
- Fixed an issue where the video screen could not be restored when returning to the foreground from the background while using SurfaceView on the Android side.
- Fix the issue where the UI component's fullscreen operation behaves unexpectedly on some older Android devices.

#### Version: 12.5.0 2025.05.08

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.5.0.17567，tag：release_premium_v12.5.0
- set iOS TXLiteAVSDK_Player_Premium to 12.5.18359， tag：release_premium_v12.5.0
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

- set Android TXLiteAVSDK_Player_Premium to 12.4.0.17372，tag：release_premium_v12.4.0
- set iOS TXLiteAVSDK_Player_Premium to 12.4.17856， tag：release_premium_v12.4.0
- The Android picture-in-picture button icon can be hidden by passing an empty string.
- The binding method of the player texture for the controller parameter of TXPlayerVideo is no longer recommended. It is recommended to use the onRenderViewCreated method instead.
- Fix the issue where the window size and aspect ratio of the picture do not match when Android live streaming enters picture-in-picture mode.
- Fix the problem that after the player component enters full screen, the player listener is still on the portrait page.
- Fix the issue that when Android enters picture-in-picture mode, there is a semi-transparent black status bar at the top of some models during the transition animation.


#### Version: 12.3.1 2025.03.18

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.3.0.17122，tag：release_premium_v12.3.1
- TXPlayerVideo has added a new onRenderViewCreatedListener callback. After obtaining the viewId of TXPlayerVideo, you can set the viewId to the player when needed.
- Fix an issue that the picture-in-picture on iOS does not display correctly in the window in some cases.
- Fix an issue that the aspect ratio of the picture-in-picture window is incorrect on Android.
- Fix an issue that there is no picture after the player component returns from full screen.
- Fix an issue that long-term video playback causes memory overflow on iOS.
- Fix an issue that high-security-level DRM videos cannot be played on iOS.

#### Version: 12.3.0 2025.01.21

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.3.0.17115，tag：release_premium_v12.3.0
- set iOS TXLiteAVSDK_Player_Premium to 12.3.16995， tag：release_premium_v12.3.0


#### Version: 12.2.2 2024.12.30

##### Features：

- Fix the issue where Android crashes when restoring from PIP.


#### Version: 12.2.1 2024.12.27

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.2.0.15072，tag：release_premium_v12.2.1
- set iOS TXLiteAVSDK_Player_Premium to 12.2.16956， tag：release_premium_v12.2.1
- Fix the issue that picture-in-picture cannot be launched on some Android systems.
- Fix the issue of abnormal use after cold startup on some Android systems.
- Fix the issue that there is no subtitle callback without setting config on iOS.
- Fix the issue that there is no callback in some cases of downloading and pre-downloading.
- Add DRM playback API.
- Fix other known issues.


#### Version: 12.2.0 2024.12.04

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.2.0.15065，tag：release_premium_v12.2.0
- set iOS TXLiteAVSDK_Player_Premium to 12.2.16945， tag：release_premium_v12.2.0
- Pre-download supports httpHeader
- Supports encrypted playback of MP4
- Added support for HEVC playback downgrade
- Fix other known issues.


#### Version: 12.1.0 2024.11.20

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.1.0.14886，tag：release_premium_v12.1.0
- set iOS TXLiteAVSDK_Player_Premium to 12.1.16597， tag：release_premium_v12.1.0
- Fix the issue of reversed logic in the live streaming mute method.
- iOS adds support for Picture-in-Picture for live streaming, which requires premium permission to use.
- Fix other known issues.


#### Version: 12.0.1 2024.09.14

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 12.0.0.14689，tag：release_premium_v12.0.1
- set iOS TXLiteAVSDK_Player_Premium to 12.1.16597， tag：release_premium_v12.0.1
- Fix the issue where textures are not refreshed in some cases
- Fix the issue where updating Picture-in-Picture produces errors when Picture-in-Picture ends in some cases
- Modify the plugin callback Flutter side message architecture
- During SDK initialization, all modules are changed to lazy loading
- The demo and player components no longer need to force set the language; if not set, it defaults to English


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

- set Android TXLiteAVSDK_Player_Premium to 11.9.0.14445，tag：release_premium_v11.9.0
- set iOS TXLiteAVSDK_Player_Premium to 11.9.15963， tag：release_premium_v11.9.0
- Android compatible with high version Gradle
- The location of the superPlayerWidget has changed, integrating superPlayer will no longer include the source code of the superPlayerWidget
- Android picture-in-picture feature logic optimization, compatible with more models


#### Version: 11.8.1 2024.05.22

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 11.8.0.14188，tag：release_premium_v11.8.1
- set iOS TXLiteAVSDK_Player_Premium to 11.8.15687， tag：release_premium_v11.8.1


#### Version: 11.8.0 2024.05.06

##### Features：

- set Android TXLiteAVSDK_Player_Premium to 11.8.0.14176，tag：release_premium_v11.8.0
- set iOS TXLiteAVSDK_Player_Premium to 11.8.15669， tag：release_premium_v11.8.0