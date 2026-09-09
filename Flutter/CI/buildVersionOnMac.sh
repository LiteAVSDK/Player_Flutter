#!/usr/bin/env bash

set -euo pipefail

buildLog() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") build process: $1"
}

# usage: buildVersionOnMac.sh <pluginVersion> [androidSdkVersion] [iosSdkVersion]
inputVersion=$1
androidSdkVersion=$2
iosSdkVersion=$3

if [ -z "$inputVersion" ]; then
    buildLog "error: plugin version is required"
    exit 1
fi

VERSION_NAME=$inputVersion
buildLog "start config Version=${VERSION_NAME}"
buildLog "currentPathIs:$(pwd)"

buildLog "start config flutter lib pubspec version"
sed -i "" "s/version:.*$/version: $VERSION_NAME/" ../pubspec.yaml
buildLog "config success on flutter lib pubspec version"

buildLog "start config flutter lib code version"
sed -i "" "s/PLAYER_VERSION = \"[0-9.]*\"/PLAYER_VERSION = \"$VERSION_NAME\"/" ../lib/Core/common/common_config.dart
buildLog "config success on flutter lib code version"

buildLog "start config plugin android version"
sed -i "" "s/playerVersion = \"[0-9.]*\"/playerVersion = \"$VERSION_NAME\"/" ../android/config.gradle
buildLog "config success on plugin android version"

if [ -n "$androidSdkVersion" ]; then
    buildLog "start config plugin android LiteAVSDK version"
    sed -i "" "s/playerSDKVersion = \"[0-9.]*\"/playerSDKVersion = \"$androidSdkVersion\"/" ../android/config.gradle
    buildLog "config success on plugin android LiteAVSDK version"
fi

buildLog "start config plugin ios version"
sed -i "" "s/s.version = '[0-9.]*'/s.version = '$VERSION_NAME'/" ../ios/super_player.podspec
buildLog "config success on plugin ios version"

if [ -n "$iosSdkVersion" ]; then
    buildLog "start config plugin ios LiteAVSDK version"
    sed -i "" -E "s/ENV\['LITEAV_SDK_VERSION'\] \|\| '[0-9.]+'/ENV['LITEAV_SDK_VERSION'] || '$iosSdkVersion'/" ../ios/super_player.podspec
    sed -i "" -E "s/^([[:space:]]*)sdk_version = '[0-9.]+'/\1sdk_version = '$iosSdkVersion'/" ../ios/super_player.podspec
    buildLog "config success on plugin ios LiteAVSDK version"
fi

buildLog "start config playerWidget pubspec version"
sed -i "" "s/version:.*$/version: $VERSION_NAME/" ../../FlutterWidget/superplayer_widget/pubspec.yaml
buildLog "config success on playerWidget pubspec version"

buildLog "start config playerWidget config version"
sed -i "" "s/PLAYER_WIDGET_VERSION = \"[0-9.]*\"/PLAYER_WIDGET_VERSION = \"$VERSION_NAME\"/" ../../FlutterWidget/superplayer_widget/lib/common/player_constants.dart
buildLog "config success on playerWidget config version"

buildLog "config Version=${VERSION_NAME} done"
