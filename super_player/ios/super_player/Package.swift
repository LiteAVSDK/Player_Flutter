// swift-tools-version: 5.9
import PackageDescription
import Foundation

// 系列选择优先级：
//   1. 环境变量 SUPER_PLAYER_SUB_SPEC / LITEAV_SDK_SUB_SPEC
//   2. 宿主工程 pubspec.yaml 的 super_player.sub_spec
//   3. 默认 professional（与 CocoaPods 行为一致）
//
// 说明：manifest 求值时的工作目录是宿主工程的 ios/ 目录，由此向上可定位宿主
// pubspec.yaml；SwiftPM 清单沙箱允许读取该文件。
let env = ProcessInfo.processInfo.environment
let fm = FileManager.default

let allowedSubSpecs: Set<String> = ["player", "professional", "premium", "professional_premium"]

/// 从 YAML 文本中解析顶层 `super_player:` 块下的 `sub_spec` 值。
func parseSubSpec(fromYAML content: String) -> String? {
    var inBlock = false
    for rawLine in content.components(separatedBy: .newlines) {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
        let indent = rawLine.prefix(while: { $0 == " " }).count

        if indent == 0 {
            inBlock = trimmed.hasPrefix("super_player:")
            continue
        }
        guard inBlock, trimmed.hasPrefix("sub_spec:") else { continue }

        let value = trimmed
            .dropFirst("sub_spec:".count)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    return nil
}

/// 候选宿主 pubspec.yaml 路径。
///
/// 两个锚点缺一不可：
///   1. manifest 文件路径 `#filePath`：Xcode GUI 下是符号链接路径
///      `<host>/ios/Flutter/ephemeral/Packages/.packages/<插件>/Package.swift`，
///      向上即可定位宿主根目录（Xcode GUI 下 CWD=/、所有 Flutter env 均为 nil）。
///   2. 工作目录：`flutter build/run` 下 CWD 为 `<host>/ios`。
func hostPubspecCandidates() -> [String] {
    var result: [String] = []

    func walkUp(from start: String) {
        var dir = URL(fileURLWithPath: start)
        for _ in 0..<12 {
            result.append(dir.appendingPathComponent("pubspec.yaml").path)
            let parent = dir.deletingLastPathComponent()
            if parent == dir { break }
            dir = parent
        }
    }

    // 锚点 1：从 manifest 文件路径向上（覆盖 Xcode GUI Run）
    walkUp(from: URL(fileURLWithPath: #filePath).deletingLastPathComponent().path)
    // 锚点 2：从工作目录向上（覆盖 flutter build/run）
    walkUp(from: fm.currentDirectoryPath)
    // 兜底
    if let pwd = env["PWD"] { walkUp(from: pwd) }
    if let appPath = env["FLUTTER_APPLICATION_PATH"] {
        result.append(URL(fileURLWithPath: appPath).appendingPathComponent("pubspec.yaml").path)
    }
    return result
}

func subSpecFromHostPubspec() -> String? {
    for path in hostPubspecCandidates() {
        guard fm.fileExists(atPath: path),
              let content = try? String(contentsOfFile: path, encoding: .utf8),
              let value = parseSubSpec(fromYAML: content)
        else { continue }
        // 命中含 super_player.sub_spec 的 pubspec 即采用；非法值回落默认。
        return allowedSubSpecs.contains(value) ? value : "professional"
    }
    return nil
}

/// 感知宿主工程是否集成了 tencent_rtc_sdk（trtc_flutter / liteav_flutter）。
/// 与 CocoaPods 侧逻辑一致：优先查 pubspec.lock，其次查 pubspec.yaml 的依赖声明。
func integratedWithRTC() -> Bool {
    for pubspecPath in hostPubspecCandidates() {
        let dir = URL(fileURLWithPath: pubspecPath).deletingLastPathComponent()
        let lockPath = dir.appendingPathComponent("pubspec.lock").path
        if fm.fileExists(atPath: lockPath),
           let content = try? String(contentsOfFile: lockPath, encoding: .utf8),
           content.contains("tencent_rtc_sdk:") {
            return true
        }
        if fm.fileExists(atPath: pubspecPath),
           let content = try? String(contentsOfFile: pubspecPath, encoding: .utf8),
           content.contains("tencent_rtc_sdk:") {
            return true
        }
    }
    return false
}

let rtcIntegrated = integratedWithRTC()

let envSubSpec = env["SUPER_PLAYER_SUB_SPEC"] ?? env["LITEAV_SDK_SUB_SPEC"]
// 集成 tencent_rtc_sdk 时：系列固定 professional（跟随 rtc_sdk 的底层系列），
// 不走环境变量 / pubspec 的系列配置；版本由 SwiftPM 约束交集跟随。
let subSpec = rtcIntegrated
    ? "professional"
    : ((envSubSpec.flatMap { allowedSubSpecs.contains($0) ? $0 : nil })
        ?? subSpecFromHostPubspec()
        ?? "professional")

// 系列 -> 底层 liteav SPM 包（URL / 包名 / product 名 / 默认版本 / 依赖方式）。
// professional 用 tag（需与 trtc_flutter 做约束交集）；其余系列仅 super_player 使用，
// 且各仓库 tag 发布节奏不同步，用 revision 锁定 main 分支的具体 commit，
// 避免旧版本插件漂移到新 SDK。
struct LiteavPkg {
    let url: String
    let name: String
    let product: String
    let defaultVersion: String
    let revision: String?   // 非 nil：用 revision 锁定 commit；nil：用 from: tag
}

let liteav: LiteavPkg
switch subSpec {
case "player":
    liteav = LiteavPkg(
        url: "https://github.com/Tencent-RTC/Player_SwiftPM.git",
        name: "Player_SwiftPM",
        product: "Player_SwiftPM",
        defaultVersion: "13.6.21648",
        revision: "9ee2f1a2772289b7e91f5f9ef7f4c999450d5fb4")
case "premium":
    liteav = LiteavPkg(
        url: "https://github.com/Tencent-RTC/Player_Premium_SwiftPM.git",
        name: "Player_Premium_SwiftPM",
        product: "Player_Premium_SwiftPM",
        defaultVersion: "13.6.21648",
        revision: "f8eecc15d6bfd4f3392af952900b7b77bbb081cd")
case "professional_premium":
    liteav = LiteavPkg(
        url: "https://github.com/Tencent-RTC/Professional_Player_Premium_SwiftPM.git",
        name: "Professional_Player_Premium_SwiftPM",
        product: "Professional_Player_Premium_SwiftPM",
        defaultVersion: "13.6.21648",
        revision: "d77061aea6a7355af1fc92a7cbad5768c8e67c2f")
default: // professional
    liteav = LiteavPkg(
        url: "https://github.com/Tencent-RTC/Professional_SwiftPM.git",
        name: "Professional_SwiftPM",
        product: "Professional_SwiftPM",
        defaultVersion: "13.6.21648",
        revision: nil)
}

// 版本：
//   - 集成 tencent_rtc_sdk 时：固定 professional 的 13.6 起跳（from: 范围），
//     由 SwiftPM 约束交集跟随 rtc_sdk 的精确版本。
//   - 否则：LITEAV_SDK_VERSION 可覆盖，回落系列默认版本。
let sdkVersionString = rtcIntegrated
    ? "13.6.21648"
    : (env["LITEAV_SDK_VERSION"] ?? liteav.defaultVersion)
let sdkVersion = Version(sdkVersionString) ?? Version(13, 6, 21648)

// professional 用 tag（from:，参与 trtc_flutter 约束交集）；
// 其余系列用 revision 锁定 main 分支的具体 commit。
let liteavDependency: Package.Dependency
if let rev = liteav.revision {
    liteavDependency = .package(url: liteav.url, revision: rev)
} else {
    liteavDependency = .package(url: liteav.url, from: sdkVersion)
}

let package = Package(
    name: "super_player",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "super-player", targets: ["super_player"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        liteavDependency
    ],
    targets: [
        .target(
            name: "super_player",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: liteav.product, package: liteav.name),
                .target(name: "FTXPiPKit"),
            ],
            path: "Sources/super_player",
            resources: [
                .copy("TXResource")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/super_player")
            ]
        ),
        .binaryTarget(
            name: "FTXPiPKit",
            path: "FTXPiPKit.xcframework"
        )
    ]
)
