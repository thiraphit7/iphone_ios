#!/bin/bash
#
# SEPwn IPA Creation Script
# Creates an IPA file from the built app bundle
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-app-bundle> [output-ipa-path]"
    echo ""
    echo "Example:"
    echo "  $0 build/DerivedData/Build/Products/Release-iphoneos/SEPwn.app"
    echo "  $0 SEPwn.app SEPwn_v1.0.0.ipa"
    exit 1
fi

APP_PATH="$1"
IPA_NAME="${2:-SEPwn.ipa}"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App bundle not found: $APP_PATH"
    exit 1
fi

print_step "Creating IPA from: $APP_PATH"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PAYLOAD_DIR="$TEMP_DIR/Payload"

print_step "Creating Payload directory..."
mkdir -p "$PAYLOAD_DIR"

print_step "Copying app bundle..."
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

print_step "Creating IPA archive..."
cd "$TEMP_DIR"
zip -r -q "$IPA_NAME" Payload

# Move to original directory
cd - > /dev/null
mv "$TEMP_DIR/$IPA_NAME" "./$IPA_NAME"

# Cleanup
rm -rf "$TEMP_DIR"

# Show result
IPA_SIZE=$(du -h "./$IPA_NAME" | cut -f1)
print_step "IPA created: $IPA_NAME ($IPA_SIZE)"

echo ""
print_step "Installation options:"
echo "  1. Use TrollStore to install"
echo "  2. Use AltStore/Sideloadly"
echo "  3. Use Apple Configurator 2"
echo ""
