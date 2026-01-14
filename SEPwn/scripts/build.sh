#!/bin/bash
#
# SEPwn Build Script
# Builds the iOS jailbreak app for device or simulator
#

set -e

# Configuration
PROJECT_NAME="SEPwn"
SCHEME="SEPwn"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
IPA_PATH="$BUILD_DIR/$PROJECT_NAME.ipa"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    SEPwn Build Script                      ║"
    echo "║              iOS 26.1 Jailbreak for iPhone Air             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

print_step() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --device      Build for iOS device (default)"
    echo "  -s, --simulator   Build for iOS simulator"
    echo "  -r, --release     Build in Release configuration"
    echo "  -c, --clean       Clean before building"
    echo "  -a, --archive     Create archive and IPA"
    echo "  -h, --help        Show this help message"
    echo ""
}

# Default options
TARGET="device"
CONFIGURATION="Debug"
CLEAN=false
ARCHIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            TARGET="device"
            shift
            ;;
        -s|--simulator)
            TARGET="simulator"
            shift
            ;;
        -r|--release)
            CONFIGURATION="Release"
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -a|--archive)
            ARCHIVE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

print_banner

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_error "xcodebuild not found. Please install Xcode."
    exit 1
fi

print_step "Xcode version: $(xcodebuild -version | head -1)"

# Set SDK
if [ "$TARGET" = "device" ]; then
    SDK="iphoneos"
    print_step "Building for iOS device"
else
    SDK="iphonesimulator"
    print_step "Building for iOS simulator"
    print_warning "Simulator builds have limited functionality"
fi

print_step "Configuration: $CONFIGURATION"

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_step "Cleaning build..."
    xcodebuild -project "$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME" \
               -configuration "$CONFIGURATION" \
               clean
fi

# Build
print_step "Building $PROJECT_NAME..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -sdk "$SDK" \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           build

if [ $? -eq 0 ]; then
    print_step "Build successful!"
else
    print_error "Build failed!"
    exit 1
fi

# Archive if requested
if [ "$ARCHIVE" = true ] && [ "$TARGET" = "device" ]; then
    print_step "Creating archive..."
    xcodebuild -project "$PROJECT_NAME.xcodeproj" \
               -scheme "$SCHEME" \
               -configuration Release \
               -sdk iphoneos \
               -archivePath "$ARCHIVE_PATH" \
               archive
    
    print_step "Exporting IPA..."
    # Note: Requires export options plist for proper export
    print_warning "Manual IPA export may be required via Xcode"
fi

# Show output location
APP_PATH="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION-$SDK/$PROJECT_NAME.app"
if [ -d "$APP_PATH" ]; then
    print_step "App built at: $APP_PATH"
    print_step "App size: $(du -sh "$APP_PATH" | cut -f1)"
fi

echo ""
print_step "Build complete!"
echo ""
