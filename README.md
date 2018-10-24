# SwiftPrivilegedHelper

This is an example application to demonstrate how to use a privileged helper tool with authentication in Swift 4.2.

**NOTE: Privilege escalation is not supported in sandboxed applications.**

Please undestand the code and improve and customize it to suit your needs and your application.

## Updated for Swift 4.2

I have rewritten the whole project for Swift 4.2 and improved the example in many places:

* **Automatic Code Signing**  
 Now the project uses automatic code signing, you no longer have to manually edit the code signing information in the app or helper plists.
 
* **Connection Validation**  
 Now the helper validates that the calling application is signed using the same signing certificate as the calling application to avoid a simple attack vector for helper tools. 

# Index

* [Requirements](https://github.com/erikberglund/SwiftPrivilegedHelper#requirements)
* [Setup](https://github.com/erikberglund/SwiftPrivilegedHelper#setup)
* [Application](https://github.com/erikberglund/SwiftPrivilegedHelper#application)
* [References](https://github.com/erikberglund/SwiftPrivilegedHelper#references)

# Requirements

* **Tool and language versions**  
 This project was created and only tested using Xcode Version 10.0 (10A255) and Swift 4.2.

* **Developer Certificate**  
 To use a privileged helper tool the application and helper has to be signed by a valid deverloper certificate.

* **SMJobBlessUtil**  
 The python tool for verifying signing of applications using SMJobBless included in the [SMJobBless](https://developer.apple.com/library/content/samplecode/SMJobBless/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010071-Intro-DontLinkElementID_2) example project is extremely useful for troubleshooting signing issues.  
 
 Dowload it here: [SMJobBlessUtil.py](https://developer.apple.com/library/content/samplecode/SMJobBless/Listings/SMJobBlessUtil_py.html)
 
 Use it like this: `./SMJobBlessUtil.py check /path/to/MyApplication.app`

# Setup

To test the project, you need to update it to use your own signing certificate.

### Select signing team
1. Select the project in the navigator.
2. For **both** the application and helper targets:
3. Change the signing Team to your Team.
 
### Signing Troubleshooting

Use [SMJobBlessUtil.py](https://developer.apple.com/library/content/samplecode/SMJobBless/Listings/SMJobBlessUtil_py.html) and correct all issues reported until it doesn't show any output.

### Note: Changing BundleIdentifier

The project uses a [bash script](https://github.com/erikberglund/SwiftPrivilegedHelper/blob/master/SwiftPrivilegedHelperApplication/Scripts/CodeSignUpdate.sh) to automatically update the needed code signing requirements for your current certificate so that they will be correct both during normal builds and archiving. 

This script has hardcoded bundle identifiers for the app and the helper, so if you change the bundle identifiers for any of these you have to update the script accordingly.

# Application

The helper is installed by using [SMJobBless](https://developer.apple.com/reference/servicemanagement/1431078-smjobbless?language=swift).

When installed, you can enter a directory path in the text field at the top and select to run the `/bin/ls` command (with the entered path as argument) using the helper tool with or without requiring authorization.

The application caches the authorization reference which means that you only have to authorize that action once until you press the "Destroy Cached Authorization" or restart the application.

This behaviour can easily be changed to either require authrization every time, after x seconds or never.

# Adding or removing code in the helper

If you modify or add/remove code that's used in the helper tool you **MUST** update the helper bundle version so when run the next time the application will recognize the helper has to be updated. Or else your new code will never be run.

# References

Links to documentation on the authorization system on macOS.

* [Authorization Services Programming Guide](https://developer.apple.com/library/content/documentation/Security/Conceptual/authorization_concepts/01introduction/introduction.html#//apple_ref/doc/uid/TP30000995-CH204-TP1)
* [Technical Note TN2095 - Authorization for Everyone](https://developer.apple.com/library/content/technotes/tn2095/_index.html)
