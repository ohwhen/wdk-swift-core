#!/bin/bash
set -e

echo "🔨 Generating iOS bundles and frameworks..."

cd WorkletSource/pear-wrk-wdk-jsonrpc

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Run the existing build scripts
echo "🎯 Building iOS addons..."
npm run build:addons

echo "📦 Building iOS bundle..."
npm run build:bundle

# Create output directory structure
OUTPUT_DIR="../../prebuilds/ios"
mkdir -p "$OUTPUT_DIR"

# Copy generated files
echo "📋 Copying bundle..."
cp generated/wdk-worklet.mobile.bundle "$OUTPUT_DIR/"

# Convert ESM modules to CJS for JSC compatibility
echo "🔄 Converting ESM→CJS for JSC..."
node ../../Scripts/convert-bundle-esm-to-cjs.js "$OUTPUT_DIR/wdk-worklet.mobile.bundle" --in-place

echo "📋 Copying frameworks..."
cp -r ios-addons/*.xcframework "$OUTPUT_DIR/"

echo "✅ iOS bundle and frameworks generated!"
echo "📍 Location: prebuilds/ios/"
echo ""
echo "To create release archive:"
echo "  cd prebuilds/ios && zip -r ../../prebuilds.zip ."
