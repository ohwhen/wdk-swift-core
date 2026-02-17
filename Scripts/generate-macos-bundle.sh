#!/bin/bash
set -e

echo "🔨 Generating macOS bundle for testing..."

cd WorkletSource/pear-wrk-wdk-jsonrpc

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Generate macOS bundle and addons using npm scripts
echo "🎯 Building macOS bundle and addons..."
npm run build:all:macos

# Create output directory
mkdir -p ../../Tests/Resources/macos

# Copy generated bundle
echo "📋 Copying bundle..."
cp generated/wdk-worklet.macos.bundle ../../Tests/Resources/macos/

# Convert ESM modules to CJS for JSC compatibility
echo "🔄 Converting ESM→CJS for JSC..."
node ../../Scripts/convert-bundle-esm-to-cjs.js ../../Tests/Resources/macos/wdk-worklet.macos.bundle --in-place

# Copy generated frameworks
echo "📋 Copying frameworks..."
mkdir -p ../../Tests/Resources/macos/Frameworks
cp -r mac-addons/*.framework ../../Tests/Resources/macos/Frameworks/

# Add @loader_path/.. rpath to addon frameworks so sibling frameworks
# can find each other, then re-sign (install_name_tool invalidates adhoc signatures)
echo "🔗 Fixing rpaths and re-signing addon frameworks..."
for fw in ../../Tests/Resources/macos/Frameworks/bare-*.framework ../../Tests/Resources/macos/Frameworks/sodium-*.framework; do
  name="$(basename "${fw%.framework}")"
  binary="$fw/$name"
  if [ -f "$binary" ]; then
    install_name_tool -add_rpath '@loader_path/..' "$binary" 2>/dev/null || true
    codesign -s - --force "$binary" 2>/dev/null
  fi
done

echo "✅ macOS bundle generated successfully!"
echo "📍 Location: Tests/Resources/macos/"
