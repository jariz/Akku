echo "🔋 building a Akku release DMG... 🔋";
echo "(going to assume node.js is installed)"

./install_amimono_fork.sh

rm -R build/

pod install
npm install

xcodebuild -workspace Akku.xcworkspace -scheme Akku -configuration Release -derivedDataPath build | xcpretty
npx appdmg dmg-resources/release.json build/Akku.dmg
