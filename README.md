# SEPwn - iOS 26.1 Jailbreak

[![Build SEPwn iOS App](https://github.com/thiraphit7/iphone_ios/actions/workflows/build-ios.yml/badge.svg)](https://github.com/thiraphit7/iphone_ios/actions/workflows/build-ios.yml)

A proof-of-concept jailbreak for iOS 26.1 targeting the iPhone Air with Apple A19 Pro SoC.

> **⚠️ WARNING:** This is a security research tool intended for authorized penetration testing only.

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

- **Kernel Information Leak** - Bypasses KASLR to discover kernel base address
- **Kernel Read/Write** - Establishes arbitrary kernel memory access
- **PAC Bypass** - Defeats Pointer Authentication on ARM64e
- **Privilege Escalation** - Elevates to root with sandbox escape
- **Post-Exploitation** - Patches kernel security features

## Project Structure

```
├── SEPwn/
│   ├── Headers/           # Header files
│   ├── Sources/           # Source code
│   ├── Resources/         # Storyboards & Assets
│   ├── Supporting Files/  # Info.plist & Entitlements
│   ├── scripts/           # Build scripts
│   └── README.md
├── SEPwn.xcodeproj/       # Xcode project
├── .github/workflows/     # GitHub Actions
└── README.md
```

## Build Requirements

- **Xcode 15.0+** (with iOS 26 SDK)
- **macOS Sonoma 14.0+** or later
- **Apple Developer Account** (for device deployment)

## Building

### Using Xcode

1. Clone this repository
2. Open `SEPwn.xcodeproj` in Xcode
3. Select your development team
4. Build and run (⌘R)

### Using GitHub Actions

The project includes automated CI/CD:

1. Push to `main` branch triggers build
2. Download artifacts from Actions tab
3. IPA is created automatically (unsigned)

### Manual Build

```bash
# Clone repository
git clone https://github.com/thiraphit7/iphone_ios.git
cd iphone_ios

# Build for device
xcodebuild -project SEPwn.xcodeproj \
           -scheme SEPwn \
           -configuration Release \
           -sdk iphoneos \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           build
```

## Installation

### Option 1: TrollStore
1. Download the unsigned IPA from Releases
2. Open with TrollStore
3. Install

### Option 2: Sideloading
1. Download the unsigned IPA
2. Sign with your certificate (AltStore, Sideloadly)
3. Install on device

### Option 3: Development
1. Build in Xcode with your developer account
2. Run directly on device

## Usage

1. Launch SEPwn on your iOS 26.1 device
2. Tap "Jailbreak" to begin
3. Wait for all stages to complete
4. Your device is now jailbroken

## Exploit Chain

| Stage | Description |
|-------|-------------|
| 1 | Initialization |
| 2 | Information Leak (KASLR bypass) |
| 3 | Kernel Read/Write |
| 4 | PAC Bypass |
| 5 | Privilege Escalation |
| 6 | Kernel Patching |
| 7 | Post-Exploitation |

## Security Considerations

- This tool is for **authorized security research only**
- Do not use on devices you do not own
- The exploit may cause device instability
- Always backup before testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Disclaimer

This software is provided for educational and authorized security research purposes only. The authors are not responsible for any misuse or damage caused by this software. Use at your own risk.
