import Testing
import Foundation
@testable import WdkSwiftCore

/// Test suite for WdkSwiftCore functionality
/// These tests require a macOS bundle to be generated first using:
/// ./Scripts/generate-macos-bundle.sh

// MARK: - Basic Tests

@Test("Basic test without BareKit")
func testBasic() {
    let x = 1 + 1
    #expect(x == 2)
}

// MARK: - Worklet Lifecycle Tests

@Test("Worklet starts successfully")
func testWorkletStarts() async throws {
    let wdk = WdkSwiftCore() // Uses platform-specific default
    
    // This will trigger worklet start internally
    let result = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    // Verify we got valid results
    #expect(!result.encryptionKey.isEmpty)
    #expect(!result.encryptedSeedBuffer.isEmpty)
    #expect(!result.encryptedEntropyBuffer.isEmpty)
}

@Test("Custom bundle path works")
func testCustomBundlePath() async throws {
    #if os(macOS)
    let testPath = FileManager.default.currentDirectoryPath 
        + "/Tests/Resources/macos/wdk-worklet.macos.bundle"
    #else
    let testPath = FileManager.default.currentDirectoryPath 
        + "/Tests/Resources/ios/wdk-worklet.mobile.bundle"
    #endif
    
    let wdk = WdkSwiftCore(bundlePath: testPath)
    
    let result = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    #expect(!result.encryptionKey.isEmpty)
}

@Test("Bundle not found throws error")
func testBundleNotFound() async {
    let wdk = WdkSwiftCore(bundleName: "nonexistent-bundle")
    
    do {
        _ = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
        Issue.record("Should have thrown bundleNotFound error")
    } catch WDKError.bundleNotFound(let message) {
        #expect(message.contains("nonexistent-bundle"))
    } catch {
        Issue.record("Wrong error type: \(error)")
    }
}

// MARK: - Mnemonic Generation Tests

@Test("Generate 12-word entropy")
func testGenerateEntropy12Words() async throws {
    let wdk = WdkSwiftCore()
    
    let result = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    #expect(!result.encryptionKey.isEmpty)
    #expect(!result.encryptedSeedBuffer.isEmpty)
    #expect(!result.encryptedEntropyBuffer.isEmpty)
    
    // Verify keys are base64 encoded (should not throw)
    #expect(Data(base64Encoded: result.encryptionKey) != nil)
    #expect(Data(base64Encoded: result.encryptedSeedBuffer) != nil)
}

@Test("Generate 24-word entropy")
func testGenerateEntropy24Words() async throws {
    let wdk = WdkSwiftCore()
    
    let result = try await wdk.generateEntropyAndEncrypt(wordCount: 24)
    
    #expect(!result.encryptionKey.isEmpty)
    #expect(!result.encryptedSeedBuffer.isEmpty)
    #expect(!result.encryptedEntropyBuffer.isEmpty)
}

@Test("Get mnemonic from encrypted entropy")
func testGetMnemonicFromEntropy() async throws {
    let wdk = WdkSwiftCore()
    
    // First generate entropy
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    // Then retrieve mnemonic
    let mnemonic = try await wdk.getMnemonicFromEntropy(
        encryptedEntropy: entropy.encryptedEntropyBuffer,
        encryptionKey: entropy.encryptionKey
    )
    
    // Verify mnemonic format (should be 12 words separated by spaces)
    let words = mnemonic.split(separator: " ")
    #expect(words.count == 12)
    
    // Each word should be lowercase and non-empty
    for word in words {
        #expect(!word.isEmpty)
        #expect(word.lowercased() == word)
    }
}

// MARK: - Mnemonic Recovery Tests

@Test("Recover seed from mnemonic")
func testRecoverSeedFromMnemonic() async throws {
    let wdk = WdkSwiftCore()
    
    // Generate and get mnemonic
    let originalEntropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    let mnemonic = try await wdk.getMnemonicFromEntropy(
        encryptedEntropy: originalEntropy.encryptedEntropyBuffer,
        encryptionKey: originalEntropy.encryptionKey
    )
    
    // Recover from mnemonic
    let recovered = try await wdk.getSeedAndEntropyFromMnemonic(mnemonic: mnemonic)
    
    #expect(!recovered.encryptionKey.isEmpty)
    #expect(!recovered.encryptedSeedBuffer.isEmpty)
    #expect(!recovered.encryptedEntropyBuffer.isEmpty)
    
    // Note: encryption keys will be different due to random generation,
    // but the underlying seed should produce the same addresses
}

@Test("Round-trip mnemonic conversion")
func testRoundTripMnemonic() async throws {
    let wdk = WdkSwiftCore()
    
    // Generate original
    let entropy1 = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    let mnemonic1 = try await wdk.getMnemonicFromEntropy(
        encryptedEntropy: entropy1.encryptedEntropyBuffer,
        encryptionKey: entropy1.encryptionKey
    )
    
    // Convert back
    let entropy2 = try await wdk.getSeedAndEntropyFromMnemonic(mnemonic: mnemonic1)
    let mnemonic2 = try await wdk.getMnemonicFromEntropy(
        encryptedEntropy: entropy2.encryptedEntropyBuffer,
        encryptionKey: entropy2.encryptionKey
    )
    
    // Mnemonics should match
    #expect(mnemonic1 == mnemonic2)
}

// MARK: - WDK Initialization Tests

@Test("Initialize WDK with basic config")
func testInitializeWDK() async throws {
    let wdk = WdkSwiftCore()
    
    // Generate seed
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    // Basic Ethereum config
    let config = """
    {
      "wallets": [{
        "name": "ethereum",
        "type": "evm",
        "chainId": 1
      }]
    }
    """
    
    // Initialize should not throw
    try await wdk.initializeWDK(
        encryptionKey: entropy.encryptionKey,
        encryptedSeed: entropy.encryptedSeedBuffer,
        config: config
    )
    
    // If we get here, initialization succeeded
    #expect(true)
}

@Test("Initialize WDK with multiple wallets")
func testInitializeMultipleWallets() async throws {
    let wdk = WdkSwiftCore()
    
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    let config = """
    {
      "wallets": [
        {
          "name": "ethereum",
          "type": "evm",
          "chainId": 1
        },
        {
          "name": "polygon",
          "type": "evm",
          "chainId": 137
        }
      ]
    }
    """
    
    try await wdk.initializeWDK(
        encryptionKey: entropy.encryptionKey,
        encryptedSeed: entropy.encryptedSeedBuffer,
        config: config
    )
    
    #expect(true)
}

// MARK: - Address Derivation Tests

@Test("Get Ethereum address")
func testGetEthereumAddress() async throws {
    let wdk = WdkSwiftCore()
    
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
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
    
    let address = try await wdk.getAddress(network: "ethereum")
    
    // Ethereum addresses start with 0x and are 42 characters long
    #expect(address.hasPrefix("0x"))
    #expect(address.count == 42)
}

@Test("Get address for different account indices")
func testGetAddressMultipleIndices() async throws {
    let wdk = WdkSwiftCore()
    
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
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
    
    let address0 = try await wdk.getAddress(network: "ethereum", accountIndex: 0)
    let address1 = try await wdk.getAddress(network: "ethereum", accountIndex: 1)
    
    // Different indices should produce different addresses
    #expect(address0 != address1)
    #expect(address0.hasPrefix("0x"))
    #expect(address1.hasPrefix("0x"))
}

@Test("Deterministic address derivation")
func testDeterministicAddresses() async throws {
    // Same mnemonic should always produce the same addresses
    let testMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    
    let wdk1 = WdkSwiftCore()
    let entropy1 = try await wdk1.getSeedAndEntropyFromMnemonic(mnemonic: testMnemonic)
    
    let config = """
    {
      "wallets": [{
        "name": "ethereum",
        "type": "evm",
        "chainId": 1
      }]
    }
    """
    
    try await wdk1.initializeWDK(
        encryptionKey: entropy1.encryptionKey,
        encryptedSeed: entropy1.encryptedSeedBuffer,
        config: config
    )
    
    let address1 = try await wdk1.getAddress(network: "ethereum")
    
    // Create second instance with same mnemonic
    let wdk2 = WdkSwiftCore()
    let entropy2 = try await wdk2.getSeedAndEntropyFromMnemonic(mnemonic: testMnemonic)
    
    try await wdk2.initializeWDK(
        encryptionKey: entropy2.encryptionKey,
        encryptedSeed: entropy2.encryptedSeedBuffer,
        config: config
    )
    
    let address2 = try await wdk2.getAddress(network: "ethereum")
    
    // Same mnemonic should produce same address
    #expect(address1 == address2)
}

// MARK: - Balance Query Tests (may fail without network access)

@Test("Get balance returns string format")
func testGetBalanceFormat() async throws {
    let wdk = WdkSwiftCore()
    
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
    let config = """
    {
      "wallets": [{
        "name": "ethereum",
        "type": "evm",
        "chainId": 1,
        "rpcUrl": "https://eth.llamarpc.com"
      }]
    }
    """
    
    try await wdk.initializeWDK(
        encryptionKey: entropy.encryptionKey,
        encryptedSeed: entropy.encryptedSeedBuffer,
        config: config
    )
    
    do {
        let balance = try await wdk.getBalance(network: "ethereum")
        
        // Balance should be a numeric string (even if "0")
        #expect(!balance.isEmpty)
        
        // Should be parseable as a number or "0"
        #expect(balance == "0" || Double(balance) != nil || balance.contains("e"))
    } catch {
        // Network errors are acceptable in tests
        print("Note: Balance query failed (expected without network): \(error)")
    }
}

// MARK: - Error Handling Tests

@Test("Invalid word count throws error")
func testInvalidWordCount() async {
    let wdk = WdkSwiftCore()
    
    do {
        _ = try await wdk.generateEntropyAndEncrypt(wordCount: 15) // Invalid
        Issue.record("Should have thrown an error for invalid word count")
    } catch WDKError.rpcError {
        // Expected error
        #expect(true)
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Test("Invalid mnemonic throws error")
func testInvalidMnemonic() async {
    let wdk = WdkSwiftCore()
    
    do {
        _ = try await wdk.getSeedAndEntropyFromMnemonic(mnemonic: "invalid mnemonic phrase")
        Issue.record("Should have thrown an error for invalid mnemonic")
    } catch WDKError.rpcError {
        // Expected error
        #expect(true)
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

// MARK: - Cleanup Tests

@Test("Dispose cleans up resources")
func testDispose() async throws {
    let wdk = WdkSwiftCore()
    
    let entropy = try await wdk.generateEntropyAndEncrypt(wordCount: 12)
    
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
    
    // Dispose should not throw
    try await wdk.dispose()
    
    #expect(true)
}
