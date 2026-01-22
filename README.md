# WdkSwiftCore

Swift wrapper for Web3 Development Kit (WDK) using Bare worklets for secure wallet operations.

## Overview

WdkSwiftCore provides a Swift interface to the WDK (Web3 Development Kit) by running JavaScript worklets via BareKit. This enables secure, isolated execution of wallet operations including mnemonic generation, seed management, and blockchain interactions.

## Features

- 🔐 Secure mnemonic generation and encryption
- 🔑 BIP39-compliant seed phrase handling
- ⛓️ Multi-chain wallet support (EVM, Solana, etc.)
- 🔄 JSON-RPC 2.0 communication with worklets
- 📦 Custom worklet bundle support
- 🧪 Full test coverage with macOS bundles

## Installation

### 1. Add SwiftPM Dependency

Add WdkSwiftCore to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tetherto/wdk-swift-core", from: "1.0.0")
]
```

Or add via Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/tetherto/wdk-swift-core`
3. Select version and add to your target

### 2. Download iOS Frameworks

**Required for iOS apps:**

1. Go to [Releases](https://github.com/tetherto/wdk-swift-core/releases)
2. Download `prebuilds.zip` from the latest release
3. Unzip the archive
4. Add all `.xcframework` files to your Xcode project:
   - Drag frameworks into your project navigator
   - Select "Embed & Sign" in target's Frameworks settings

### 3. Download BareKit Framework

**Required for all platforms:**

1. Go to [bare-kit releases](https://github.com/holepunchto/bare-kit/releases)
2. Download `prebuilds.zip` from the latest release
3. Extract `BareKit.xcframework`
4. Add to your Xcode project with "Embed & Sign"

## Usage

### Basic Example

```swift
import WdkSwiftCore

// Initialize WDK
let wdk = WdkSwiftCore()

// Generate new wallet
let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
let mnemonic = try await wdk.getMnemonicFromEntropy(
    encryptedEntropy: entropy.encryptedEntropyBuffer,
    encryptionKey: entropy.encryptionKey
)

print("Mnemonic: \(mnemonic)")

// Initialize WDK with configuration
let config = """
{
  "wallets": [{
    "name": "ethereum",
    "type": "evm",
    "chainId": 1
  }]
}
"""

try await wdk.initializeWDK(
    encryptionKey: entropy.encryptionKey,
    encryptedSeed: entropy.encryptedSeedBuffer,
    config: config
)

// Get account address
let address = try await wdk.getAddress(network: "ethereum")
print("Address: \(address)")

// Get balance
let balance = try await wdk.getBalance(network: "ethereum")
print("Balance: \(balance)")
```

### Recover from Mnemonic

```swift
let wdk = WdkSwiftCore()

// Convert mnemonic to encrypted seed
let mnemonic = "your twelve word mnemonic phrase here..."
let seedData = try await wdk.getSeedAndEntropyFromMnemonic(mnemonic: mnemonic)

// Initialize with recovered seed
try await wdk.initializeWDK(
    encryptionKey: seedData.encryptionKey,
    encryptedSeed: seedData.encryptedSeedBuffer,
    config: config
)
```

### Custom Worklet Bundles

You can provide your own worklet bundle for custom functionality:

**Option 1: Add bundle to your app's main bundle**

1. Add your custom `.bundle` file to your Xcode project
2. Initialize with the bundle name:

```swift
let wdk = WdkSwiftCore(bundleName: "my-custom-worklet")
```

**Option 2: Provide explicit path**

```swift
let bundlePath = "/path/to/my-worklet.bundle"
let wdk = WdkSwiftCore(
    bundleName: "my-worklet",
    bundlePath: bundlePath
)
```

The bundle loading follows this priority:
1. Explicit `bundlePath` parameter (highest priority)
2. Auto-detect in `Bundle.main` (for custom bundles)
3. Fallback to package's included bundle

### Advanced Operations

```swift
// Call custom methods on accounts
let result = try await wdk.callMethod(
    methodName: "signTransaction",
    network: "ethereum",
    accountIndex: 0,
    args: #"{"to": "0x...", "value": "1000000000000000000"}"#,
    options: #"{"gasLimit": "21000"}"#
)

// Register additional wallets
let blockchains = try await wdk.registerWallet(config: additionalWalletConfig)

// Register protocols
try await wdk.registerProtocol(config: protocolConfig)

// Clean up when done
try await wdk.dispose()
```

## API Reference

### Initialization

```swift
init(bundleName: String = "wdk-worklet.mobile", bundlePath: String? = nil)
```

### Mnemonic & Seed Management

- `generateEntropyAndEncrypt(wordCount: Int) async throws -> EntropyResult`
- `getMnemonicFromEntropy(encryptedEntropy: String, encryptionKey: String) async throws -> String`
- `getSeedAndEntropyFromMnemonic(mnemonic: String) async throws -> SeedAndEntropyResult`

### WDK Operations

- `initializeWDK(encryptionKey: String, encryptedSeed: String, config: String) async throws`
- `callMethod(methodName: String, network: String, accountIndex: Int, args: String?, options: String?) async throws -> Any`
- `registerWallet(config: String) async throws -> [String]`
- `registerProtocol(config: String) async throws`
- `dispose() async throws`

### Convenience Methods

- `getAddress(network: String, accountIndex: Int = 0) async throws -> String`
- `getBalance(network: String, accountIndex: Int = 0) async throws -> String`

## Development

### Prerequisites

- Xcode 15+ with Swift 6.2+
- macOS 12+ (for testing)
- Node.js 20+
- npm

### Local Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/tetherto/wdk-swift-core.git
   cd wdk-swift-core
   ```

2. Setup BareKit framework for testing:
   ```bash
   ./Scripts/setup-barekit.sh
   ```

3. Generate macOS test bundle:
   ```bash
   ./Scripts/generate-macos-bundle.sh
   ```

4. Run tests:
   ```bash
   swift test
   ```

### Project Structure

```
wdk-swift-core/
├── Sources/WdkSwiftCore/        # Swift library code
│   ├── WdkSwiftCore.swift       # Main API
│   ├── WdkError.swift           # Error types
│   └── WdkTypes.swift           # Data types
├── Tests/WdkSwiftCoreTests/     # SPM tests (run on macOS)
├── WorkletSource/               # JavaScript worklet source (excluded from SPM)
│   └── pear-wrk-wdk-jsonrpc/    # WDK JSON-RPC worklet
├── Scripts/                     # Build and setup scripts
│   ├── generate-macos-bundle.sh # Generate macOS bundle for testing
│   ├── generate-ios-bundle.sh   # Generate iOS bundles for releases
│   └── setup-barekit.sh         # Download BareKit framework
└── .github/workflows/           # CI/CD pipelines
```

### Rebuilding Worklet Bundles

To modify the JavaScript worklet:

1. Navigate to worklet source:
   ```bash
   cd WorkletSource/pear-wrk-wdk-jsonrpc
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Make changes to source files in `src/`

4. Rebuild macOS bundle for testing:
   ```bash
   cd ../..
   ./Scripts/generate-macos-bundle.sh
   ```

5. Test your changes:
   ```bash
   swift test
   ```

6. For iOS bundles (usually done by CI):
   ```bash
   ./Scripts/generate-ios-bundle.sh
   ```

### Testing

Tests use macOS bundles generated locally via `generate-macos-bundle.sh`. iOS integration testing is done in the separate [wdk-starter-swift](https://github.com/tetherto/wdk-starter-swift) repository.

```bash
# Run all tests
swift test

# Run specific test
swift test --filter testGenerateEntropyAndEncrypt
```

## Release Process

1. Update version numbers and create a git tag
2. Create a GitHub release
3. CI automatically:
   - Builds iOS bundles and frameworks
   - Creates `prebuilds.zip`
   - Uploads as release asset
   - Lists included frameworks in release notes

Users download `prebuilds.zip` from the release page and add frameworks to their Xcode projects.

## Architecture

WdkSwiftCore uses a worklet-based architecture for security and isolation:

```
┌─────────────────────┐
│   iOS/macOS App     │
│                     │
│  ┌──────────────┐   │
│  │ WdkSwiftCore │   │
│  └──────┬───────┘   │
│         │ IPC       │
│  ┌──────▼───────┐   │
│  │   BareKit    │   │
│  │   Worklet    │   │
│  └──────────────┘   │
│         │           │
│  ┌──────▼───────┐   │
│  │ WDK JS Core  │   │
│  └──────────────┘   │
└─────────────────────┘
```

- **WdkSwiftCore**: Swift API layer with async/await interface
- **IPC Layer**: JSON-RPC 2.0 with length-prefixed framing
- **BareKit Worklet**: Isolated JavaScript runtime
- **WDK Core**: JavaScript wallet implementation

## Error Handling

```swift
do {
    let result = try await wdk.getAddress(network: "ethereum")
    print(result)
} catch WDKError.bundleNotFound(let message) {
    print("Bundle error: \(message)")
} catch WDKError.rpcError(let code, let message) {
    print("RPC error [\(code)]: \(message)")
} catch WDKError.ipcError(let message) {
    print("IPC error: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

For major changes, please open an issue first to discuss what you'd like to change.

## License

Apache-2.0

## Links

- [WDK Documentation](https://github.com/tetherto/wdk)
- [BareKit](https://github.com/holepunchto/bare-kit)
- [Example iOS App](https://github.com/tetherto/wdk-starter-swift)

## Support

- Issues: [GitHub Issues](https://github.com/tetherto/wdk-swift-core/issues)
- Discussions: [GitHub Discussions](https://github.com/tetherto/wdk-swift-core/discussions)
