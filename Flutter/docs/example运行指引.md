## 环境准备

- Flutter 3.0 及以上版本。
- Android 端开发：
    - Android Studio 3.5及以上版本。
    - App 要求 Android 4.1及以上版本设备。
    - SDK 最低要求 19 以上
- iOS 端开发：
    - Xcode 11.0及以上版本。
    - osx 系统版本要求 10.11 及以上版本
    - 请确保您的项目已设置有效的开发者签名。
    - IOS 系统最低要求取决于您的flutter环境
    

## example下载

可在 [example项目地址](https://github.com/LiteAVSDK/Player_Flutter) ，通过git或者源码下载的方式，将项目下载到本地。

### 项目运行

使用编译器打开项目，可以使用以下命令来获取flutter依赖包

```yaml
flutter packages get
```

### 集成视频播放 License
若您已获得相关 License 授权，需在 [腾讯云视立方控制台](https://console.cloud.tencent.com/vcube)  获取 License URL 和 License Key：
![](https://qcloudimg.tencent-cloud.cn/raw/9b4532dea04364dbff3e67773aab8c95.png)
若您暂未获得 License 授权，需先参见 [视频播放License](https://cloud.tencent.com/document/product/881/74588) 获取相关授权。

集成播放器前，需要 [注册腾讯云账户](https://cloud.tencent.com/login) ，注册成功后申请视频播放能力 License， 然后通过下面方式集成，建议在应用启动时进行。

如果没有集成 License，播放过程中可能会出现异常。
```dart
String licenceURL = ""; // 获取到的 licence url
String licenceKey = ""; // 获取到的 licence key
SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
```

### 项目运行

相关环境配置准备好之后，可以使用编译器自带的运行能力，将项目打包运行到对应设备上。
也可以使用如下命令运行：

```shell
flutter run
```

然后根据命令提示进行操作。

### 运行常见问题

- 如果在编译运行过程中，flutter无法运行起来，可以使用如下命令，根据提示检查自己的环境配置：

```shell
flutter doctor
```

- 如果在IOS设备运行，提示找不到接口、方法等错误提示，可以在IOS项目目录下，使用以下命令更新依赖:

```shell
rm -rf Pods
rm -rf Podfile.lock
pod update
```

- 仅支持Android和iOS平台。另外：iOS端暂不支持在模拟器上运行播放视频，您需要iPhone真机运行。


