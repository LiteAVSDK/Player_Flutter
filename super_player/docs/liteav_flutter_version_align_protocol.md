# LiteAV SDK 版本对齐协议（super_player ↔ tencent_rtc_sdk / liteav_flutter）

## 1. 背景

super_player 与 tencent_rtc_sdk（liteav_flutter）均依赖底层腾讯 LiteAVSDK（TXLiteAVSDK）。当两个插件在同一宿主工程中集成时，底层 SDK 的**系列（sub_spec）与版本号必须一致**，否则会出现依赖冲突或符号冲突。

本协议定义一套**共同读取**的版本定义来源，使客户/CI 可以在编译环境中一次定义版本，两端自动对齐。

## 2. 编译环境变量（内部版本统一机制，最高优先级）

| 变量名 | 平台 | 格式 | 说明 |
|---|---|---|---|
| `LITEAV_SDK_VERSION` | Android（Gradle 读取） | 四段，如 `13.4.0.20481` | 底层 LiteAVSDK 版本号 |
| `LITEAV_SDK_VERSION` | iOS（CocoaPods 读取） | 三段，如 `13.4.21067` | 底层 LiteAVSDK 版本号 |
| `LITEAV_SDK_SUB_SPEC` | 双端通用 | `player` / `professional` / `premium` / `professional_premium` | 底层 LiteAVSDK 系列 |

> 变量名双端统一为 `LITEAV_SDK_VERSION`。Android 与 iOS 的构建是两个独立进程，分别注入各自格式的值即可，天然无冲突。
>
> **定位**：环境变量主要用于**内部版本统一**（内部 CI/发布、多插件对齐），客户无需关心。**客户侧的定义入口是 pubspec `liteav_flutter` 节点（见第 5 节）**。

## 3. 优先级链（两端一致）

```
环境变量  >  gradle.properties（仅 Android）  >  pubspec.yaml 插件节点  >  插件内置默认
```

- Android 侧 `gradle.properties` 可选属性：`liteavSdkVersion`（四段）、`liteavSdkSubSpec`。
- 版本号与系列**独立解析**：只注入其一，另一项回落。
- 各端做格式校验：值不符合本平台格式时打印告警并回落内置默认，不静默生效。

## 4. 当前落地状态

### super_player（已完成）

| 平台 | 文件 | 落地内容 |
|---|---|---|
| Android | `android/build.gradle` | `LITEAV_SDK_VERSION` / `LITEAV_SDK_SUB_SPEC` 环境变量 + `liteavSdkVersion` / `liteavSdkSubSpec` 属性；回落 pubspec `super_player.sub_spec` → 默认 `professional` / `13.4.0.20477` |
| iOS | `ios/super_player.podspec` | `LITEAV_SDK_VERSION` / `LITEAV_SDK_SUB_SPEC` 环境变量；回落 pubspec `super_player.sub_spec` → 默认 `professional` / `13.4.21067` |

- 无环境变量注入时行为与历史版本完全一致，零回归。
- 构建日志以 `[SuperPlayer]` 前缀输出解析结果，便于排查。

### tencent_rtc_sdk / liteav_flutter（待支持，由 liteav_flutter 团队落地）

- `flutter/sdk/android/build.gradle` 与 `flutter/sdk/ios/tencent_rtc_sdk.podspec` 按同一优先级链接入 `LITEAV_SDK_VERSION` / `LITEAV_SDK_SUB_SPEC`。
- 建议同时清理 CI 中通过 `sed` 替换源码版本号的逻辑，改用环境变量注入。
- **发布期对齐约定**：tencent_rtc_sdk 各版本的**内置默认底包版本号**，须与其所依赖 super_player 版本的默认底包版本号保持一致（否则客户不注入环境变量时仍会冲突）。双方发布 checklist 需包含此核对项。

## 5. 后续预留：pubspec `liteav_flutter` 节点

计划后续支持宿主 `pubspec.yaml` 中新增 `liteav_flutter` 节点（优先级高于 `super_player` 节点、低于环境变量）：

```yaml
liteav_flutter:
  sub_spec: 'professional'        # 可选；player / professional / premium / professional_premium
  android_version: '13.4.0.20481' # 可选；Android 四段号
  ios_version: '13.4.21067'       # 可选；iOS 三段号
```

- 落地顺序：tencent_rtc_sdk 先落地该节点（字段名以其实现为准），super_player 再对齐同名字段。
- 读取逻辑已抽成函数，接入仅需在回落链中插入一个来源。

## 6. 使用示例

### Android / iOS 构建环境注入（CI 推荐）

```bash
# Android 构建进程
export LITEAV_SDK_VERSION=13.4.0.20481
export LITEAV_SDK_SUB_SPEC=professional
flutter build apk

# iOS 构建进程
export LITEAV_SDK_VERSION=13.4.21067
export LITEAV_SDK_SUB_SPEC=professional
flutter build ios
```

### Android 宿主 gradle.properties（可选）

```properties
liteavSdkVersion=13.4.0.20481
liteavSdkSubSpec=professional
```
