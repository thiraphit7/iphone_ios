# SEPwn - iOS 26.1 Jailbreak

## Overview

SEPwn is a proof-of-concept jailbreak for iOS 26.1 (Build 23B85) targeting the iPhone Air (iPhone18,4) with Apple A19 Pro SoC.

**WARNING: This is a security research tool intended for authorized penetration testing only.**

## Target Information

| Property | Value |
|----------|-------|
| iOS Version | 26.1 |
| Build | 23B85 |
| Device | iPhone Air (iPhone18,4) |
| SoC | Apple A19 Pro (t8150) |
| Architecture | ARM64e with PAC |
| Kernel | Darwin 25.1.0 (xnu-12377.42.6~55) |

## Features

- **Kernel Information Leak**: Bypasses KASLR to discover kernel base address
- **Kernel Read/Write**: Establishes arbitrary kernel memory access
- **PAC Bypass**: Defeats Pointer Authentication on ARM64e
- **Privilege Escalation**: Elevates to root with sandbox escape
- **Post-Exploitation**: Patches kernel security features

## Project Structure

```
SEPwn/
├── Headers/
│   ├── common.h              # Common definitions and macros
│   ├── kernel_offsets.h      # Kernel structure offsets
│   ├── kernel_rw.h           # Kernel R/W primitives
│   ├── pac_bypass.h          # PAC bypass functions
│   ├── exploit_utils.h       # Exploit utilities
│   ├── jailbreak.h           # Main jailbreak API
│   ├── AppDelegate.h         # iOS App Delegate
│   └── ViewController.h      # Main View Controller
├── Sources/
│   ├── main.m                # App entry point
│   ├── AppDelegate.m         # App Delegate implementation
│   ├── ViewController.m      # UI implementation
│   ├── jailbreak_ios26.c     # Main jailbreak chain
│   ├── kernel_rw_primitives.c # Kernel R/W implementation
│   ├── kernel_info_leak.c    # Information leak exploit
│   ├── pac_bypass.c          # PAC bypass implementation
│   ├── sep_iokit_fuzzer.c    # IOKit fuzzer for SEP
│   ├── exploit_utils.c       # Utility functions
│   └── kernel_offsets.c      # Offset management
├── Resources/
│   ├── Assets.xcassets/      # App icons and colors
│   ├── Main.storyboard       # Main UI
│   └── LaunchScreen.storyboard
├── Supporting Files/
│   ├── Info.plist            # App configuration
│   └── SEPwn.entitlements    # Required entitlements
└── README.md
```

## Build Requirements

- **Xcode 15.0+** (with iOS 26 SDK)
- **macOS Sonoma 14.0+** or later
- **Apple Developer Account** (for device deployment)
- **iOS 26.1 device** (iPhone Air recommended)

## Building

### Using Xcode

1. Open `SEPwn.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Connect your iOS device
4. Select your device as the build target
5. Build and run (⌘R)

### Using Command Line

```bash
# Build for device
xcodebuild -project SEPwn.xcodeproj \
           -scheme SEPwn \
           -configuration Release \
           -sdk iphoneos \
           build

# Build for simulator (limited functionality)
xcodebuild -project SEPwn.xcodeproj \
           -scheme SEPwn \
           -configuration Debug \
           -sdk iphonesimulator \
           build
```

## Signing

### Development Signing

For development testing, use your Apple Developer account:

1. Open Xcode project settings
2. Select "SEPwn" target
3. Go to "Signing & Capabilities"
4. Enable "Automatically manage signing"
5. Select your development team

### Post-Signing with ldid

Some entitlements require post-signing:

```bash
# After building, sign with additional entitlements
ldid -S"SEPwn/Supporting Files/SEPwn.entitlements" SEPwn.app/SEPwn
```

### TrollStore Installation

For devices with TrollStore:

1. Build the IPA file
2. Transfer to device
3. Open with TrollStore to install

## Usage

1. **Launch the app** on your iOS 26.1 device
2. **Tap "Jailbreak"** to begin the exploit chain
3. **Wait** for each stage to complete
4. **Success!** Your device is now jailbroken

## Exploit Chain

The jailbreak proceeds through these stages:

1. **Initialization** - Set up exploit environment
2. **Information Leak** - Leak kernel base address via SEP IOKit
3. **Kernel R/W** - Establish kernel memory access
4. **PAC Bypass** - Defeat pointer authentication
5. **Privilege Escalation** - Gain root and escape sandbox
6. **Kernel Patching** - Disable security features
7. **Post-Exploitation** - Install persistence

## Kernel Offsets

The kernel offsets in `kernel_offsets.h` are placeholders and must be updated based on actual kernelcache analysis. Use tools like:

- **jtool2**: `jtool2 --analyze kernelcache`
- **Ghidra**: Import as Mach-O arm64e
- **IDA Pro**: Load as ARM64 Little Endian

## Security Considerations

- This tool is for **authorized security research only**
- Do not use on devices you do not own or have permission to test
- The exploit may cause device instability
- Always backup your device before testing

## Troubleshooting

### Build Errors

- Ensure Xcode 15+ is installed
- Check that iOS 26 SDK is available
- Verify signing configuration

### Runtime Errors

- Check device compatibility (iPhone Air only)
- Verify iOS version (26.1 Build 23B85)
- Review console logs for specific errors

### Exploit Failures

- Kernel offsets may need adjustment
- Try multiple attempts (race conditions)
- Check for iOS updates that may patch vulnerabilities

## Credits

- Kernelcache analysis based on iOS 26.1 (23B85)
- IOKit attack surface research from Phrack #72
- PAC bypass techniques from public security research

## Disclaimer

This software is provided for educational and authorized security research purposes only. The authors are not responsible for any misuse or damage caused by this software. Use at your own risk.

## License

This project is released for security research purposes. See LICENSE file for details.
