#!/bin/sh
# Xcode Cloud : installe Flutter (version figee = celle utilisee en local), recupere les paquets et genere les Pods
# (Generated.xcconfig et Pods/ ne sont pas commites).
set -ex

cd "$CI_PRIMARY_REPOSITORY_PATH"

git clone https://github.com/flutter/flutter.git --depth 1 -b 3.38.3 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter precache --ios
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

cd ios
pod install
