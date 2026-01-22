#!/bin/bash
set -e

echo "🧪 Running WdkSwiftCore tests..."

# Get absolute paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORKS_DIR="$ROOT_DIR/Frameworks"
TEST_FRAMEWORKS_DIR="$ROOT_DIR/Tests/Resources/macos/Frameworks"
TEST_RESOURCES_DIR="$ROOT_DIR/Tests/Resources/macos"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/debug"
TEST_BUNDLE_DIR="$BUILD_DIR/wdk-swift-corePackageTests.xctest/Contents/MacOS"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Copy frameworks to build directory first
echo "📦 Copying frameworks for build..."
if [ -d "$FRAMEWORKS_DIR" ]; then
    cp -R "$FRAMEWORKS_DIR"/* "$BUILD_DIR/" 2>/dev/null || true
fi

if [ -d "$TEST_FRAMEWORKS_DIR" ]; then
    cp -R "$TEST_FRAMEWORKS_DIR"/* "$BUILD_DIR/" 2>/dev/null || true
fi

# Build first to create test bundle
echo "🔨 Building tests..."
swift build --build-tests \
    -Xcc -F -Xcc "$TEST_FRAMEWORKS_DIR" \
    -Xlinker -F -Xlinker "$TEST_FRAMEWORKS_DIR" \
    -Xlinker -rpath -Xlinker "@executable_path"

# Copy frameworks to additional locations where BareKit might look
echo "📦 Copying frameworks to all possible locations..."

# 1. Build directory
if [ -d "$FRAMEWORKS_DIR" ]; then
    cp -R "$FRAMEWORKS_DIR"/* "$BUILD_DIR/" 2>/dev/null || true
fi

if [ -d "$TEST_FRAMEWORKS_DIR" ]; then
    cp -R "$TEST_FRAMEWORKS_DIR"/* "$BUILD_DIR/" 2>/dev/null || true
    
    # 2. Next to test binary
    if [ -d "$TEST_BUNDLE_DIR" ]; then
        cp -R "$TEST_FRAMEWORKS_DIR"/* "$TEST_BUNDLE_DIR/" 2>/dev/null || true
    fi
    
    # 3. Test resources directory
    cp -R "$TEST_FRAMEWORKS_DIR"/* "$TEST_RESOURCES_DIR/" 2>/dev/null || true
fi

# Set framework search paths for runtime
export DYLD_FRAMEWORK_PATH="$TEST_BUNDLE_DIR:$BUILD_DIR:$TEST_RESOURCES_DIR:$TEST_FRAMEWORKS_DIR:$FRAMEWORKS_DIR"
export DYLD_LIBRARY_PATH="$TEST_BUNDLE_DIR:$BUILD_DIR:$TEST_RESOURCES_DIR:$TEST_FRAMEWORKS_DIR:$FRAMEWORKS_DIR"
export DYLD_FALLBACK_FRAMEWORK_PATH="$TEST_BUNDLE_DIR:$BUILD_DIR:$TEST_RESOURCES_DIR:$TEST_FRAMEWORKS_DIR:$FRAMEWORKS_DIR"

echo "🏃 Running tests..."
echo "   Framework paths set:"
echo "   - $FRAMEWORKS_DIR"
echo "   - $TEST_FRAMEWORKS_DIR"
echo "   - $BUILD_DIR"

# Run tests with framework paths - capture all output
swift test \
    -Xcc -F -Xcc "$TEST_FRAMEWORKS_DIR" \
    -Xlinker -F -Xlinker "$TEST_FRAMEWORKS_DIR" \
    -Xlinker -rpath -Xlinker "$TEST_FRAMEWORKS_DIR"
