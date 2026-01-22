#!/bin/bash
set -e

BAREKIT_VERSION=${1:-"latest"}
FRAMEWORKS_DIR="Frameworks"

echo "🔧 Setting up BareKit.xcframework for testing..."

mkdir -p "$FRAMEWORKS_DIR"

# Get latest release URL if version is "latest"
if [ "$BAREKIT_VERSION" = "latest" ]; then
    echo "📡 Fetching latest BareKit release..."
    RELEASE_URL=$(curl -s https://api.github.com/repos/holepunchto/bare-kit/releases/latest \
        | grep "browser_download_url.*prebuilds.zip" \
        | cut -d '"' -f 4)
    
    if [ -z "$RELEASE_URL" ]; then
        echo "❌ Could not find prebuilds.zip in latest release"
        echo "   Please check https://github.com/holepunchto/bare-kit/releases"
        exit 1
    fi
else
    RELEASE_URL="https://github.com/holepunchto/bare-kit/releases/download/$BAREKIT_VERSION/prebuilds.zip"
fi

echo "⬇️  Downloading BareKit prebuilds from:"
echo "   $RELEASE_URL"
curl -L "$RELEASE_URL" -o barekit-prebuilds.zip

echo "📦 Extracting BareKit.xcframework..."
unzip -q barekit-prebuilds.zip -d "$FRAMEWORKS_DIR/temp"

# Find and move BareKit.xcframework to root of Frameworks/
echo "📂 Locating BareKit.xcframework..."
BAREKIT_PATH=$(find "$FRAMEWORKS_DIR/temp" -name "BareKit.xcframework" -type d | head -n 1)

if [ -z "$BAREKIT_PATH" ]; then
    echo "❌ BareKit.xcframework not found in prebuilds.zip"
    rm -rf "$FRAMEWORKS_DIR/temp"
    rm barekit-prebuilds.zip
    exit 1
fi

# Move to Frameworks/
mv "$BAREKIT_PATH" "$FRAMEWORKS_DIR/"

# Clean up
rm barekit-prebuilds.zip
rm -rf "$FRAMEWORKS_DIR/temp"

echo "✅ BareKit.xcframework ready!"
echo "📍 Location: $FRAMEWORKS_DIR/BareKit.xcframework"
