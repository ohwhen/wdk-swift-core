#!/usr/bin/env node

const { execSync } = require('child_process')
const path = require('path')

// Parse command line arguments
const args = process.argv.slice(2)
const platformArg = args.find(arg => arg.startsWith('--platform='))
const platform = platformArg ? platformArg.split('=')[1] : 'ios'

// Validate platform
if (!['ios', 'macos'].includes(platform)) {
  console.error('❌ Invalid platform. Use --platform=ios or --platform=macos')
  process.exit(1)
}

// List of bare modules that need to be linked
const bareModules = [
  'bare-fs',
  'bare-inspect',
  'bare-type',
  'sodium-native',
  'bare-url',
  'bare-hrtime',
  'bare-tty',
  'bare-signals',
  'bare-os',
  'bare-performance',
  'bare-zlib',
  'bare-pipe',
  'bare-tls',
  'bare-tcp',
  'bare-dns',
  'bare-crypto'
]

// Platform-specific configuration
const platformConfig = {
  ios: {
    hosts: ['ios-arm64', 'ios-arm64-simulator', 'ios-x64-simulator'],
    outDir: 'ios-addons',
    displayName: 'iOS'
  },
  macos: {
    hosts: ['darwin-arm64'],
    outDir: 'mac-addons',
    displayName: 'macOS'
  }
}

const config = platformConfig[platform]
const { hosts, outDir, displayName } = config

console.log(`🔗 Linking Bare addons for ${displayName}...\n`)

for (const module of bareModules) {
  const modulePath = path.join('node_modules', module)
  
  try {
    console.log(`  Linking ${module}...`)
    
    const hostsArgs = hosts.map(h => `--host ${h}`).join(' ')
    const command = `npx bare-link ${hostsArgs} --out ${outDir} ${modulePath}`
    
    execSync(command, { 
      stdio: 'inherit',
      cwd: process.cwd()
    })
    
    console.log(`  ✅ ${module} linked successfully\n`)
  } catch (error) {
    console.error(`  ❌ Failed to link ${module}:`, error.message)
    process.exit(1)
  }
}

console.log(`✨ All Bare addons linked successfully for ${displayName}!`)
console.log(`📍 Location: ${outDir}/`)
