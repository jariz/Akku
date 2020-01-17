#!/usr/bin/env sh

set -e

echo "🔋 building a Akku release DMG... 🔋"
echo "(going to assume node.js is installed)"
sudo ./install_amimono_fork.sh;
rm -rf build/
pod install
npm install
xcodebuild -workspace Akku.xcworkspace -scheme Akku -configuration Release -derivedDataPath build | xcpretty
npx appdmg dmg-resources/release.json build/Akku.dmg
