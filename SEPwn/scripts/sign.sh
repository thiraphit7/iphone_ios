#!/bin/bash
#
# SEPwn Signing Script
# Signs the app with additional entitlements using ldid
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

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-app-bundle>"
    echo ""
    echo "Example:"
    echo "  $0 build/DerivedData/Build/Products/Release-iphoneos/SEPwn.app"
    exit 1
fi

APP_PATH="$1"
ENTITLEMENTS_PATH="SEPwn/Supporting Files/SEPwn.entitlements"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App bundle not found: $APP_PATH"
    exit 1
fi

# Verify entitlements exist
if [ ! -f "$ENTITLEMENTS_PATH" ]; then
    print_error "Entitlements file not found: $ENTITLEMENTS_PATH"
    exit 1
fi

print_step "Signing SEPwn with additional entitlements..."

# Check for ldid
if command -v ldid &> /dev/null; then
    print_step "Using ldid for signing..."
    
    # Sign main binary
    BINARY_PATH="$APP_PATH/SEPwn"
    if [ -f "$BINARY_PATH" ]; then
        ldid -S"$ENTITLEMENTS_PATH" "$BINARY_PATH"
        print_step "Signed: $BINARY_PATH"
    else
        print_error "Binary not found: $BINARY_PATH"
        exit 1
    fi
    
    print_step "Signing complete!"
    
elif command -v jtool2 &> /dev/null; then
    print_step "Using jtool2 for signing..."
    
    BINARY_PATH="$APP_PATH/SEPwn"
    if [ -f "$BINARY_PATH" ]; then
        jtool2 --sign --ent "$ENTITLEMENTS_PATH" "$BINARY_PATH"
        print_step "Signed: $BINARY_PATH"
    else
        print_error "Binary not found: $BINARY_PATH"
        exit 1
    fi
    
    print_step "Signing complete!"
    
else
    print_warning "Neither ldid nor jtool2 found."
    print_warning "Please install one of these tools:"
    echo ""
    echo "  # Install ldid via Homebrew"
    echo "  brew install ldid"
    echo ""
    echo "  # Or download jtool2"
    echo "  http://www.newosxbook.com/tools/jtool.html"
    echo ""
    exit 1
fi

# Verify entitlements
print_step "Verifying entitlements..."
if command -v ldid &> /dev/null; then
    ldid -e "$APP_PATH/SEPwn"
elif command -v codesign &> /dev/null; then
    codesign -d --entitlements - "$APP_PATH/SEPwn" 2>/dev/null || true
fi

echo ""
print_step "Done! App is ready for deployment."
echo ""
