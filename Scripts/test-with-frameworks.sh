#!/bin/bash
set -e

echo "🧪 Running WdkSwiftCore tests with all frameworks linked..."

cd "$(dirname "$0")/.."

# Link all bare-* frameworks
swift test \
  -Xcc -F -Xcc Frameworks \
  -Xcc -F -Xcc Tests/Resources/macos/Frameworks \
  -Xlinker -F -Xlinker Frameworks \
  -Xlinker -F -Xlinker Tests/Resources/macos/Frameworks \
  -Xlinker -rpath -Xlinker @executable_path \
  -Xlinker -rpath -Xlinker @loader_path \
  -Xlinker -framework -Xlinker bare-buffer.3.4.2 \
  -Xlinker -framework -Xlinker bare-crypto.1.13.0 \
  -Xlinker -framework -Xlinker bare-dns.2.1.4 \
  -Xlinker -framework -Xlinker bare-fs.4.5.2 \
  -Xlinker -framework -Xlinker bare-hrtime.2.1.1 \
  -Xlinker -framework -Xlinker bare-inspect.3.1.4 \
  -Xlinker -framework -Xlinker bare-os.3.6.2 \
  -Xlinker -framework -Xlinker bare-performance.1.3.0 \
  -Xlinker -framework -Xlinker bare-pipe.4.1.2 \
  -Xlinker -framework -Xlinker bare-signals.4.2.0 \
  -Xlinker -framework -Xlinker bare-tcp.2.2.2 \
  -Xlinker -framework -Xlinker bare-tls.2.1.7 \
  -Xlinker -framework -Xlinker bare-tty.5.0.3 \
  -Xlinker -framework -Xlinker bare-type.1.1.0 \
  -Xlinker -framework -Xlinker bare-url.2.3.2 \
  -Xlinker -framework -Xlinker bare-zlib.1.3.1 \
  -Xlinker -framework -Xlinker sodium-native.5.0.10 \
  "$@"
