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

# Copy generated frameworks
echo "📋 Copying frameworks..."
mkdir -p ../../Tests/Resources/macos/Frameworks
cp -r mac-addons/*.framework ../../Tests/Resources/macos/Frameworks/

echo "✅ macOS bundle generated successfully!"
echo "📍 Location: Tests/Resources/macos/"
