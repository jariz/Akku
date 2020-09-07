<img src="https://jari.lol/8OQmLnyKru.png" width="305" align="right" />  

# ​ ![](https://jari.lol/rR76J5YsnU.png)  Akku  

The missing macOS bluetooth headset battery indicator app.

[![Build Status](https://travis-ci.org/jariz/Akku.svg?branch=master)](https://travis-ci.org/jariz/Akku)
[![GitHub pre-release](https://img.shields.io/github/release-pre/jariz/akku?label=beta)](https://github.com/jariz/Akku/releases/latest)
[![GitHub release](https://img.shields.io/github/release/jariz/akku?label=stable)](https://github.com/jariz/Akku/releases/latest)

## What does it do?
- Displays headset battery status, which can't be viewed on macOS at all (only for Apple accessories).
- (Optionally) notifies you when headset battery gets low.
- Menu bar icon.

## Download

### DMG

Get the [latest .DMG here.](https://github.com/jariz/Akku/releases/latest)

### brew cask

Coming soon once app goes stable.

## Compatibility  
It will work with any headset that conforms to the [Apple bluetooth spec](https://developer.apple.com/hardwaredrivers/BluetoothDesignGuidelines.pdf)\*

**Translation**:  
If your Android device can read it's battery status, it will very likely work.  
If your iPhone device can read your headset's battery status, it will work.  

----
\* = You read that correctly, Apple did not bother to implement their own specifications on the Mac.

## FAQ

### My device doesn't work!  

Whilst we're still in beta, it might be possible that Akku reports that it can't find any battery status for your device.  
Before opening an issue, check the following:

- If you have a iPhone/Android device, please confirm that it shows you the battery status.  
If not, chances are high that your device simply doesn't support battery statuses.  
- If you just installed Akku, reconnect at least once.  
- If your phone can read the status, but Akku can't, please follow [this guide](https://github.com/jariz/Akku/blob/master/CONTRIBUTING.md#my-device-does-not-work) that tells you what data you need to provide in order for us to fix the issue.

### I don't want Akku in my menubar all the time!
Use [Bartender](https://www.macbartender.com/) to hide it, and configure it to only show Akku on changes.
I recommend the following config:
<img src="https://jari.lol/u0fBwJJpHf.png" width="469" />

### Will this app be in the App Store?

No. [Like most of my apps](https://noti.center), it uses pretty unorthodox API's that will very likely not work in the app sandbox and/or be approved by Apple.  
However, Akku contains a automatic updater that will keep it up to date, and additionally, you can manually check by clicking 'Check for updates' from it's menu.

### How does it work?

**The simple explanation:**   
You give it root, and it will monitor all bluetooth communication that goes through the system to intercept battery indicator commands.  

**The hard explanation**:  
You give it root, and it will install a helper application.  
The helper proceeds to communicate to the app through [XPC](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html)  
Once the helper is activated, it will communicate with the `IOBluetoothHCIController` driver through [IOKit](https://developer.apple.com/documentation/iokit)  
It will map a region of memory from the kernel to Akku, and scan through the raw bluetooth data.  
Akku can currently decode HCI events, L2CAP packets and RFCOMM packets (RFCOMM is build upon L2CAP).  
Once it has exhausted said bluetooth data, it will poll and instruct the system to dump any new data to Akku's mapped memory every 5 seconds.  
The only communication that goes back to the non-privileged process is the normalized battery indication signals.  
Both Akku and it's helper verify their signatures to ensure no unauthorized access is made.  
Both are codesigned with a valid Apple developer cert.

## Inspirations / Shoutouts

- Jeff Reiner // [@mirshko](https://twitter.com/mirshko)  
Icon Design, moral support 😍    
- [SwiftPrivilegedHelper](https://github.com/erikberglund/SwiftPrivilegedHelper/)  
Great starting point to implement helper installation & XPC communication, thanks [@ekkrik](https://twitter.com/ekkrik)!  
- [cocoapods-amimono](https://github.com/UnsafePointer/cocoapods-amimono)  
Needed to embed the pods into the helper itself, which is not really something cocoapods is designed to do.  
Luckily amimono was there, despite needing a few more patches to make it do what I wanted.  
- Android's [BluetoothHeadset.java](http://androidxref.com/9.0.0_r3/xref/frameworks/base/core/java/android/bluetooth/BluetoothHeadset.java)  
Gives some good information on the vendor specific AT commands that Android accepts.  
- [Wireshark](https://www.wireshark.org/)    
Wouldn't have gotten anywhere with figuring out the raw bluetooth data without wireshark.  

