#!/usr/bin/env bash

buildLog() {
    echo `date +"%Y-%m-%d %H:%M:%S"`" build process: $1"
}

inputVersion=$1
export VERSION_NAME="11.9.1"
if [ -n "$inputVersion" ]; then
  VERSION_NAME=$inputVersion
fi
buildLog "start config Version=${VERSION_NAME}"
buildLog "currentPathIs:$(pwd)"
buildLog "start config flutter lib pubspec version"
sed -i "" "s/version:.*$/version: $VERSION_NAME/" ../pubspec.yaml
buildLog "config success on flutter lib pubspec version"
buildLog "start config flutter lib code version"
sed -i "" "s/PLAYER_VERSION = \"[0-9.]*\"/PLAYER_VERSION = \"$VERSION_NAME\"/" ../lib/Core/common/common_config.dart
buildLog "config success on flutter lib code version"
buildLog "start config flutter superplayer_widget pubspec version"
sed -i "" "s/version:.*$/version: $VERSION_NAME/" ../superplayer_widget/pubspec.yaml
buildLog "config success on superplayer_widget pubspec version"
buildLog "start config plugin android version"
sed -i "" "s/playerVersion = \"[0-9.]*\"/playerVersion = \"$VERSION_NAME\"/" ../android/config.gradle
buildLog "config success on plugin android version"
buildLog "start config plugin ios version"
sed -i "" "s/s.version = '[0-9.]*'/s.version = '$VERSION_NAME'/" ../ios/super_player.podspec
buildLog "config success on plugin ios version"
buildLog "config Version=${VERSION_NAME} done"