echo "🔋 building a Akku release DMG... 🔋";
echo "(going to assume node.js is installed)"

rm -R build/
pod install
xcodebuild -workspace Akku.xcworkspace -scheme Akku -configuration Release -derivedDataPath build | xcpretty
npx appdmg dmg-resources/release.json build/Akku.dmg
