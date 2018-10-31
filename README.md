# Akku

Akku is a tiny monitoring app for headset bluetooth devices.

## Compatibility  
It will work with any headset that conforms to the [Apple bluetooth spec](https://developer.apple.com/hardwaredrivers/BluetoothDesignGuidelines.pdf)\* or the [XEvent spec](https://developer.plantronics.com/article/plugging-plantronics-headset-sensor-events-android)  

**Translation**:  
If your Android device can read it's battery status, it will very likely work.  
If your iPhone device can read your headset's battery status, Akku will be guaranteedly be able to do so as well.  

## How does it work?

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

- Jeff Reiner // @mirshko  
Icon design    
- [SwiftPrivilegedHelper](https://github.com/erikberglund/SwiftPrivilegedHelper/)  
Great starting point to implement helper installation & XPC communication, thanks @erikberglund!  
- Android's [BluetoothHeadset.java](http://androidxref.com/9.0.0_r3/xref/frameworks/base/core/java/android/bluetooth/BluetoothHeadset.java)  
Gives some good information on the vendor specific AT commands that Android accepts.  
- [Wireshark](https://www.wireshark.org/)    
If I could donate to this project, I would.  
Wouldn't have gotten anywhere with figuring out the raw bluetooth data without wireshark.  


----
\* = You read that correctly, Apple did not bother to implement their own specifications on the Mac.

