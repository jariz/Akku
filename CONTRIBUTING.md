# Contributing to Akku.

This is the contribution guide to Akku.

## My device does not work!

Your device is not picked up by Akku and it reports that no battery state was found.

First, some background: Akku currently has to parse the full raw bluetooth communication with your device.  
Because Akku is not a full fledged bluetooth stack, it might get things wrong here and there.  

**Simply put**: the more hardware we get to test it with, the better it becomes.  
If it failed to work for you then congratulations, you get to make it better! 😜

Before opening [your issue](https://github.com/jariz/Akku/issues/new), we'll need detailed data.  
We recommend using [wetransfer](https://wetransfer.com/) for adding the files you will attach to your issue.

### Attaching a packet dump.
We'll firstly need a packet dump of your headset's connection request to your device:
- Stop any audio playback to your device.  
  > This will muddle your packetlog otherwise.
- Optional: restart your mac.  
  > This is to ensure that no sound data included in your packet dump could possibly become public, as the kernel buffers a 5-10 minute window of all bluetooth communcation into the memory.  
  > **Simply put:** if you had a skype call with someone before this, might be wise to restart.  
If you were just listening to music, it is not that important.
- (Re)connect your device (sounds stupid, but do not skip this!)
- Go to the `Terminal` app and execute the following command:  
  ```bash
  sudo /System/Library/Frameworks/IOBluetooth.framework/Versions/A/Resources/BluetoothReporter --dumpPacketLog /var/log/upload_me.pklg \
    && open --reveal /var/log/upload_me.pklg
  ```
- Upload the file that shows up in finder
- Additionally - _and preferably_ -  you can check if the packetlog contains the correct data we are looking for:
  - Install [Wireshark](https://www.wireshark.org/download.html)
  - Open the `upload_me.pklg` file.
  - Type `btrfcomm.address` in the 'Apply a display filter' field (& hit enter)
  - If it doesn't show any results below the filter field, it means wireshark can't find any useful data in the file (and neither will we).
  Try again and refollow the previous steps.

### Attaching Akku log files.
1. Press CMD+SHIFT+G in Finder
2. Enter `/Library/Logs/AkkuHelper.log`
3. Upload the file
4. Repeat 1-3 for `~/Library/Logs/Akku.log` as well.
    
### Optional: attaching crash logs.  
  > Crashes will be reported to the Akku team automatically, but attaching the crash reports can help pin down a specific crash type to an issue.
  - If any `/Library/Logs/DiagnosticReports/io.jari.AkkuHelper_*.crash` files exist, attach them.
  - If any `~/Library/Logs/DiagnosticReports/io.jari.Akku_*.crash` files exist, attach them.

  
## How to develop on Akku

_Coming soon._
