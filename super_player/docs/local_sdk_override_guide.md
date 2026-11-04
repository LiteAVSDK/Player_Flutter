# super_player 插件 — 替换原生 SDK 为本地依赖

## Android

编辑宿主工程 `android/app/build.gradle`，在 `plugins` 块后添加：

```groovy
configurations.all {
    exclude group: 'com.tencent.liteav', module: 'LiteAVSDK_Player_Premium'
    exclude group: 'com.tencent.liteav', module: 'LiteAVSDK_Player'
    exclude group: 'com.tencent.liteav', module: 'LiteAVSDK_Professional'
    exclude group: 'com.tencent.liteav', module: 'LiteAVSDK_Professional_Player_Premium'
}

dependencies {
    implementation files('/your/path/to/LiteAVSDK_Player_Premium_x.x.x.xxxxx.aar')
}
```

> 将路径替换为您本地 AAR 文件的绝对路径。

## iOS

### 1. 放置本地 SDK

将附带的 `LocalSDK/` 目录整体复制到宿主工程的 `ios/` 下，然后将您的 xcframework 文件也放入该目录中。

### 2. 修改 Podfile

在 `flutter_install_all_ios_pods` 之后添加一行：

```ruby
pod 'TXLiteAVSDK_Player_Premium', '12.9.20085', :podspec => 'LocalSDK/TXLiteAVSDK_Player_Premium.podspec'
```

> ⚠️ 版本号 `12.9.20085` 必须携带，用于覆盖插件中该版本的远程依赖。

### 3. 安装

```bash
cd ios && pod install --repo-update
```
