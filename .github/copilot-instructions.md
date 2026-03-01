# Copilot Instructions for Ably Cocoa SDK

This repository contains the Ably iOS, tvOS and macOS SDK written in Objective-C and Swift.

## Prerequisites

- macOS with Xcode 16.3 or later
- Carthage: `brew install carthage`
- Ruby gems: `bundle install`

## Initial Setup

After cloning the repository, run:

```bash
make update
```

This command will:
- Update Git submodules (`make submodules`)
- Update Carthage dependencies (`make update_carthage_dependencies`)

## Development Commands

### Building and Testing

- **Run tests on iOS**: `make test_iOS`
- **Run tests on tvOS**: `make test_tvOS` 
- **Run tests on macOS**: `make test_macOS`
- **Build Carthage framework package**: `make carthage_package`
- **Validate CocoaPods spec**: `make pod_lint`

### Dependency Management

- **Update all dependencies**: `make update`
- **Update only Carthage dependencies**: `make update_carthage_dependencies`
- **Update Carthage for specific platforms**:
  - iOS only: `make update_carthage_dependencies_ios`
  - tvOS only: `make update_carthage_dependencies_tvos`
  - macOS only: `make update_carthage_dependencies_macos`
- **Clear Carthage caches**: `make carthage_clean`

### Fastlane Commands

Tests can also be run directly with Fastlane:

```bash
# Set environment (required)
export ABLY_ENV=sandbox

# Run platform-specific tests
bundle exec fastlane test_iOS18_4
bundle exec fastlane test_tvOS18_4
bundle exec fastlane test_macOS
```

## Project Structure

- **Source/**: SDK source code (Objective-C and Swift)
- **Test/**: Test suite
- **Examples/**: Example applications
- **Scripts/**: Build and utility scripts
- **Ably.xcodeproj**: Main Xcode project

## Important Notes

- The project uses Carthage for dependency management
- Tests require simulators to be available
- Environment variable `ABLY_ENV=sandbox` is required for running tests
- Changes to `Cartfile` should be reflected in `Ably.podspec`
- Use Xcode for interactive development and debugging

## Common Issues

- If you encounter build issues, try `make carthage_clean` followed by `make update`
- Ensure you have the correct Xcode version selected: `sudo xcode-select -s /Applications/Xcode_16.3.app`
- Reset simulators if tests fail: `xcrun simctl erase all`

For more detailed information, see [CONTRIBUTING.md](../CONTRIBUTING.md).