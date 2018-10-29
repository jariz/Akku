# Akku

Akku is a tiny monitoring app for headset bluetooth devices.
It will work with any headset that conforms to the [Apple bluetooth spec](https://developer.apple.com/hardwaredrivers/BluetoothDesignGuidelines.pdf)\* (translation: if it works on your iPhone, it will work with Akku)

## Inspirations / Shoutouts

- Jeff Reiner // @mirshko  
Icon design  
- `IOBluetooth.framework/Resources/BluetoothReporter`  
Most of the lowlevel stuff was figured out by reverse engineering this tool. (tiny shoutout to the trial version of the [hopper disassembler](https://www.hopperapp.com/))  
- [SwiftPrivilegedHelper](https://github.com/erikberglund/SwiftPrivilegedHelper/)  
Great starting point to implement helper installation & XPC communication, thanks @erikberglund!  
- Android's [BluetoothHeadset.java](http://androidxref.com/9.0.0_r3/xref/frameworks/base/core/java/android/bluetooth/BluetoothHeadset.java)  
Gives some good information on the vendor specific AT commands that Android accepts.  
- [Wireshark](https://www.wireshark.org/)    
If I could donate to this project, I would.  
Wouldn't have gotten anywhere with figuring out the raw bluetooth data without wireshark.  


----
\* = You read that correctly, Apple did not bother to implement their own specifications on the Mac.

