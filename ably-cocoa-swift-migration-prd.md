# Ably Cocoa Swift Migration - Product Requirements Document

## Overview

This document outlines the requirements and approach for migrating the Ably Cocoa SDK from Objective-C to Swift, maintaining full API compatibility while leveraging Swift's type safety and modern language features.

## Background

The current Ably Cocoa SDK consists of approximately 100+ Objective-C implementation files (.m) with corresponding header files (.h), representing a mature, production-ready codebase that handles real-time messaging, REST API interactions, push notifications, and complex connection management.

### Current Architecture Analysis

**Core Components:**
- **Foundation Extensions**: 15+ utility categories (NSString, NSDate, NSDictionary, etc.)
- **Core Types**: Complex enum definitions, state machines, callback typedefs (579-line ARTTypes.h)
- **Authentication**: Token-based auth with callback patterns
- **Networking**: HTTP client with fallback hosts, custom SSL handling
- **Messaging**: Message encoding/decoding with multiple formats (JSON, MsgPack, Delta Codec)
- **Real-time**: WebSocket transport with connection state management
- **Channels**: REST and Realtime channel implementations with presence
- **Push Notifications**: iOS-specific push registration and device management
- **Client Classes**: ARTRest and ARTRealtime main entry points

**External Dependencies:**
- SocketRocket (WebSocket implementation)
- msgpack-objective-c (Binary encoding)
- delta-codec-cocoa (Message compression)
- ably-cocoa-plugin-support (Plugin architecture)

## Migration Strategy

### Approach: Mechanical Carbon-Copy Translation

**Rationale:**
- **Low Risk**: Preserve existing battle-tested logic and behavior
- **Fast Execution**: Direct syntax translation vs architectural redesign
- **High Confidence**: Existing test suite validates correctness
- **Reviewability**: Clear 1:1 mapping between old and new code

### Implementation Approach: Alphabetical Migration

**Rationale for Alphabetical Order:**
- **Simplified Planning**: Eliminates complex dependency analysis and ordering decisions
- **Predictable Progress**: Clear, linear progression through the codebase
- **Reduced Risk**: No dependency-related blocking issues or ordering mistakes
- **Easy Tracking**: Simple to monitor progress and identify remaining work

### Complete Migration Table

The following table shows all 115 `.m` files to be migrated in alphabetical order, along with their associated header files and resulting Swift file names:

| .m File | Associated .h Files | Resulting .swift File |
|---------|-------------------|---------------------|
| ARTAnnotation.m | ARTAnnotation.h, ARTAnnotation+Private.h | ARTAnnotation.swift |
| ARTAttachRequestParams.m | ARTAttachRequestParams.h | ARTAttachRequestParams.swift |
| ARTAttachRetryState.m | ARTAttachRetryState.h | ARTAttachRetryState.swift |
| ARTAuth.m | ARTAuth.h, ARTAuth+Private.h | ARTAuth.swift |
| ARTAuthDetails.m | ARTAuthDetails.h | ARTAuthDetails.swift |
| ARTAuthOptions.m | ARTAuthOptions.h, ARTAuthOptions+Private.h | ARTAuthOptions.swift |
| ARTBackoffRetryDelayCalculator.m | ARTBackoffRetryDelayCalculator.h | ARTBackoffRetryDelayCalculator.swift |
| ARTBaseMessage.m | ARTBaseMessage.h, ARTBaseMessage+Private.h | ARTBaseMessage.swift |
| ARTChannel.m | ARTChannel.h, ARTChannel+Private.h | ARTChannel.swift |
| ARTChannelOptions.m | ARTChannelOptions.h, ARTChannelOptions+Private.h | ARTChannelOptions.swift |
| ARTChannelProtocol.m | ARTChannelProtocol.h | ARTChannelProtocol.swift |
| ARTChannelStateChangeParams.m | ARTChannelStateChangeParams.h | ARTChannelStateChangeParams.swift |
| ARTChannels.m | ARTChannels.h, ARTChannels+Private.h | ARTChannels.swift |
| ARTClientInformation.m | ARTClientInformation.h, ARTClientInformation+Private.h | ARTClientInformation.swift |
| ARTClientOptions.m | ARTClientOptions.h, ARTClientOptions+Private.h | ARTClientOptions.swift |
| ARTConnectRetryState.m | ARTConnectRetryState.h | ARTConnectRetryState.swift |
| ARTConnection.m | ARTConnection.h, ARTConnection+Private.h | ARTConnection.swift |
| ARTConnectionDetails.m | ARTConnectionDetails.h, ARTConnectionDetails+Private.h | ARTConnectionDetails.swift |
| ARTConnectionStateChangeParams.m | ARTConnectionStateChangeParams.h | ARTConnectionStateChangeParams.swift |
| ARTConstants.m | ARTConstants.h | ARTConstants.swift |
| ARTContinuousClock.m | ARTContinuousClock.h | ARTContinuousClock.swift |
| ARTCrypto.m | ARTCrypto.h, ARTCrypto+Private.h | ARTCrypto.swift |
| ARTDataEncoder.m | ARTDataEncoder.h | ARTDataEncoder.swift |
| ARTDataQuery.m | ARTDataQuery.h, ARTDataQuery+Private.h | ARTDataQuery.swift |
| ARTDefault.m | ARTDefault.h, ARTDefault+Private.h | ARTDefault.swift |
| ARTDeviceDetails.m | ARTDeviceDetails.h, ARTDeviceDetails+Private.h | ARTDeviceDetails.swift |
| ARTDeviceIdentityTokenDetails.m | ARTDeviceIdentityTokenDetails.h, ARTDeviceIdentityTokenDetails+Private.h | ARTDeviceIdentityTokenDetails.swift |
| ARTDevicePushDetails.m | ARTDevicePushDetails.h, ARTDevicePushDetails+Private.h | ARTDevicePushDetails.swift |
| ARTErrorChecker.m | ARTErrorChecker.h | ARTErrorChecker.swift |
| ARTEventEmitter.m | ARTEventEmitter.h, ARTEventEmitter+Private.h | ARTEventEmitter.swift |
| ARTFallback.m | ARTFallback.h, ARTFallback+Private.h | ARTFallback.swift |
| ARTFallbackHosts.m | ARTFallbackHosts.h | ARTFallbackHosts.swift |
| ARTFormEncode.m | ARTFormEncode.h | ARTFormEncode.swift |
| ARTGCD.m | ARTGCD.h | ARTGCD.swift |
| ARTHTTPPaginatedResponse.m | ARTHTTPPaginatedResponse.h, ARTHTTPPaginatedResponse+Private.h | ARTHTTPPaginatedResponse.swift |
| ARTHttp.m | ARTHttp.h, ARTHttp+Private.h | ARTHttp.swift |
| ARTInternalLog.m | ARTInternalLog.h, ARTInternalLog+Testing.h | ARTInternalLog.swift |
| ARTInternalLogCore.m | ARTInternalLogCore.h, ARTInternalLogCore+Testing.h | ARTInternalLogCore.swift |
| ARTJitterCoefficientGenerator.m | ARTJitterCoefficientGenerator.h | ARTJitterCoefficientGenerator.swift |
| ARTJsonEncoder.m | ARTJsonEncoder.h | ARTJsonEncoder.swift |
| ARTJsonLikeEncoder.m | ARTJsonLikeEncoder.h | ARTJsonLikeEncoder.swift |
| ARTLocalDevice.m | ARTLocalDevice.h, ARTLocalDevice+Private.h | ARTLocalDevice.swift |
| ARTLocalDeviceStorage.m | ARTLocalDeviceStorage.h | ARTLocalDeviceStorage.swift |
| ARTLog.m | ARTLog.h, ARTLog+Private.h | ARTLog.swift |
| ARTLogAdapter.m | ARTLogAdapter.h, ARTLogAdapter+Testing.h | ARTLogAdapter.swift |
| ARTMessage.m | ARTMessage.h | ARTMessage.swift |
| ARTMessageOperation.m | ARTMessageOperation.h, ARTMessageOperation+Private.h | ARTMessageOperation.swift |
| ARTMsgPackEncoder.m | ARTMsgPackEncoder.h | ARTMsgPackEncoder.swift |
| ARTOSReachability.m | ARTOSReachability.h | ARTOSReachability.swift |
| ARTPaginatedResult.m | ARTPaginatedResult.h, ARTPaginatedResult+Private.h, ARTPaginatedResult+Subclass.h | ARTPaginatedResult.swift |
| ARTPendingMessage.m | ARTPendingMessage.h | ARTPendingMessage.swift |
| ARTPluginAPI.m | ARTPluginAPI.h | ARTPluginAPI.swift |
| ARTPluginDecodingContext.m | ARTPluginDecodingContext.h | ARTPluginDecodingContext.swift |
| ARTPresence.m | ARTPresence.h, ARTPresence+Private.h | ARTPresence.swift |
| ARTPresenceMessage.m | ARTPresenceMessage.h, ARTPresenceMessage+Private.h | ARTPresenceMessage.swift |
| ARTProtocolMessage.m | ARTProtocolMessage.h, ARTProtocolMessage+Private.h | ARTProtocolMessage.swift |
| ARTPublicRealtimeChannelUnderlyingObjects.m | ARTPublicRealtimeChannelUnderlyingObjects.h | ARTPublicRealtimeChannelUnderlyingObjects.swift |
| ARTPush.m | ARTPush.h, ARTPush+Private.h | ARTPush.swift |
| ARTPushActivationEvent.m | ARTPushActivationEvent.h | ARTPushActivationEvent.swift |
| ARTPushActivationState.m | ARTPushActivationState.h | ARTPushActivationState.swift |
| ARTPushActivationStateMachine.m | ARTPushActivationStateMachine.h, ARTPushActivationStateMachine+Private.h | ARTPushActivationStateMachine.swift |
| ARTPushAdmin.m | ARTPushAdmin.h, ARTPushAdmin+Private.h | ARTPushAdmin.swift |
| ARTPushChannel.m | ARTPushChannel.h, ARTPushChannel+Private.h | ARTPushChannel.swift |
| ARTPushChannelSubscription.m | ARTPushChannelSubscription.h | ARTPushChannelSubscription.swift |
| ARTPushChannelSubscriptions.m | ARTPushChannelSubscriptions.h, ARTPushChannelSubscriptions+Private.h | ARTPushChannelSubscriptions.swift |
| ARTPushDeviceRegistrations.m | ARTPushDeviceRegistrations.h, ARTPushDeviceRegistrations+Private.h | ARTPushDeviceRegistrations.swift |
| ARTQueuedDealloc.m | ARTQueuedDealloc.h | ARTQueuedDealloc.swift |
| ARTQueuedMessage.m | ARTQueuedMessage.h | ARTQueuedMessage.swift |
| ARTRealtime.m | ARTRealtime.h, ARTRealtime+Private.h, ARTRealtime+WrapperSDKProxy.h | ARTRealtime.swift |
| ARTRealtimeAnnotations.m | ARTRealtimeAnnotations.h, ARTRealtimeAnnotations+Private.h | ARTRealtimeAnnotations.swift |
| ARTRealtimeChannel.m | ARTRealtimeChannel.h, ARTRealtimeChannel+Private.h | ARTRealtimeChannel.swift |
| ARTRealtimeChannelOptions.m | ARTRealtimeChannelOptions.h | ARTRealtimeChannelOptions.swift |
| ARTRealtimeChannels.m | ARTRealtimeChannels.h, ARTRealtimeChannels+Private.h | ARTRealtimeChannels.swift |
| ARTRealtimePresence.m | ARTRealtimePresence.h, ARTRealtimePresence+Private.h | ARTRealtimePresence.swift |
| ARTRealtimeTransport.m | ARTRealtimeTransport.h | ARTRealtimeTransport.swift |
| ARTRealtimeTransportFactory.m | ARTRealtimeTransportFactory.h | ARTRealtimeTransportFactory.swift |
| ARTRest.m | ARTRest.h, ARTRest+Private.h | ARTRest.swift |
| ARTRestChannel.m | ARTRestChannel.h, ARTRestChannel+Private.h | ARTRestChannel.swift |
| ARTRestChannels.m | ARTRestChannels.h, ARTRestChannels+Private.h | ARTRestChannels.swift |
| ARTRestPresence.m | ARTRestPresence.h, ARTRestPresence+Private.h | ARTRestPresence.swift |
| ARTRetrySequence.m | ARTRetrySequence.h | ARTRetrySequence.swift |
| ARTStats.m | ARTStats.h | ARTStats.swift |
| ARTStatus.m | ARTStatus.h | ARTStatus.swift |
| ARTStringifiable.m | ARTStringifiable.h, ARTStringifiable+Private.h | ARTStringifiable.swift |
| ARTTestClientOptions.m | ARTTestClientOptions.h | ARTTestClientOptions.swift |
| ARTTokenDetails.m | ARTTokenDetails.h | ARTTokenDetails.swift |
| ARTTokenParams.m | ARTTokenParams.h, ARTTokenParams+Private.h | ARTTokenParams.swift |
| ARTTokenRequest.m | ARTTokenRequest.h | ARTTokenRequest.swift |
| ARTTypes.m | ARTTypes.h, ARTTypes+Private.h | ARTTypes.swift |
| ARTURLSessionServerTrust.m | ARTURLSessionServerTrust.h | ARTURLSessionServerTrust.swift |
| ARTWebSocketFactory.m | ARTWebSocketFactory.h | ARTWebSocketFactory.swift |
| ARTWebSocketTransport.m | ARTWebSocketTransport.h, ARTWebSocketTransport+Private.h | ARTWebSocketTransport.swift |
| ARTWrapperSDKProxyOptions.m | ARTWrapperSDKProxyOptions.h | ARTWrapperSDKProxyOptions.swift |
| ARTWrapperSDKProxyPush.m | ARTWrapperSDKProxyPush.h, ARTWrapperSDKProxyPush+Private.h | ARTWrapperSDKProxyPush.swift |
| ARTWrapperSDKProxyPushAdmin.m | ARTWrapperSDKProxyPushAdmin.h, ARTWrapperSDKProxyPushAdmin+Private.h | ARTWrapperSDKProxyPushAdmin.swift |
| ARTWrapperSDKProxyPushChannel.m | ARTWrapperSDKProxyPushChannel.h, ARTWrapperSDKProxyPushChannel+Private.h | ARTWrapperSDKProxyPushChannel.swift |
| ARTWrapperSDKProxyPushChannelSubscriptions.m | ARTWrapperSDKProxyPushChannelSubscriptions.h, ARTWrapperSDKProxyPushChannelSubscriptions+Private.h | ARTWrapperSDKProxyPushChannelSubscriptions.swift |
| ARTWrapperSDKProxyPushDeviceRegistrations.m | ARTWrapperSDKProxyPushDeviceRegistrations.h, ARTWrapperSDKProxyPushDeviceRegistrations+Private.h | ARTWrapperSDKProxyPushDeviceRegistrations.swift |
| ARTWrapperSDKProxyRealtime.m | ARTWrapperSDKProxyRealtime.h, ARTWrapperSDKProxyRealtime+Private.h | ARTWrapperSDKProxyRealtime.swift |
| ARTWrapperSDKProxyRealtimeAnnotations.m | ARTWrapperSDKProxyRealtimeAnnotations.h, ARTWrapperSDKProxyRealtimeAnnotations+Private.h | ARTWrapperSDKProxyRealtimeAnnotations.swift |
| ARTWrapperSDKProxyRealtimeChannel.m | ARTWrapperSDKProxyRealtimeChannel.h, ARTWrapperSDKProxyRealtimeChannel+Private.h | ARTWrapperSDKProxyRealtimeChannel.swift |
| ARTWrapperSDKProxyRealtimeChannels.m | ARTWrapperSDKProxyRealtimeChannels.h, ARTWrapperSDKProxyRealtimeChannels+Private.h | ARTWrapperSDKProxyRealtimeChannels.swift |
| ARTWrapperSDKProxyRealtimePresence.m | ARTWrapperSDKProxyRealtimePresence.h, ARTWrapperSDKProxyRealtimePresence+Private.h | ARTWrapperSDKProxyRealtimePresence.swift |
| NSArray+ARTFunctional.m | NSArray+ARTFunctional.h | NSArray+ARTFunctional.swift |
| NSDate+ARTUtil.m | NSDate+ARTUtil.h | NSDate+ARTUtil.swift |
| NSDictionary+ARTDictionaryUtil.m | NSDictionary+ARTDictionaryUtil.h | NSDictionary+ARTDictionaryUtil.swift |
| NSError+ARTUtils.m | NSError+ARTUtils.h | NSError+ARTUtils.swift |
| NSHTTPURLResponse+ARTPaginated.m | NSHTTPURLResponse+ARTPaginated.h | NSHTTPURLResponse+ARTPaginated.swift |
| NSString+ARTUtil.m | NSString+ARTUtil.h | NSString+ARTUtil.swift |
| NSURL+ARTUtils.m | NSURL+ARTUtils.h | NSURL+ARTUtils.swift |
| NSURLQueryItem+Stringifiable.m | NSURLQueryItem+Stringifiable.h | NSURLQueryItem+Stringifiable.swift |
| NSURLRequest+ARTPaginated.m | NSURLRequest+ARTPaginated.h | NSURLRequest+ARTPaginated.swift |
| NSURLRequest+ARTPush.m | NSURLRequest+ARTPush.h | NSURLRequest+ARTPush.swift |
| NSURLRequest+ARTRest.m | NSURLRequest+ARTRest.h | NSURLRequest+ARTRest.swift |
| NSURLRequest+ARTUtils.m | NSURLRequest+ARTUtils.h | NSURLRequest+ARTUtils.swift |

### Implementation Phases

With alphabetical ordering, the migration can be approached in manageable batches of 10-15 files each:

**Batch 1: ARTAnnotation - ARTChannels (13 files)**
**Batch 2: ARTClientInformation - ARTDefault (11 files)**  
**Batch 3: ARTDeviceDetails - ARTInternalLogCore (12 files)**
**Batch 4: ARTJitterCoefficientGenerator - ARTPluginDecodingContext (14 files)**
**Batch 5: ARTPresence - ARTRealtimeChannelOptions (15 files)**
**Batch 6: ARTRealtimeChannels - ARTWrapperSDKProxyOptions (10 files)**
**Batch 7: ARTWrapperSDKProxy* files (15 files)**
**Batch 8: Foundation Extensions (NS* files) (12 files)**
**Batch 9: Build System & Testing**

**Batch Completion Criteria:**
1. All files in batch migrated to Swift
2. `swift build` runs without compilation errors
3. Warnings handled according to error handling rules
4. Progress tracking files updated
5. Placeholder types created/updated as needed

**Swift Adaptations Example:**
```objective-c
// Objective-C
typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    // ...
};

// Swift
public enum ARTRealtimeConnectionState: UInt, Sendable {
    case initialized = 0
    case connecting = 1
    case connected = 2
    // ...
}
```

**Callback Pattern Translation:**
```objective-c
// Objective-C
typedef void (^ARTTokenDetailsCallback)(ARTTokenDetails *_Nullable result, NSError *_Nullable error);

// Swift  
public typealias ARTTokenDetailsCallback = (ARTTokenDetails?, Error?) -> Void
```

## Technical Requirements

### API Compatibility

**Must Preserve:**
- All class names and method signatures
- All callback-based async patterns
- All enum values and constants
- Platform-specific conditional compilation
- **No Objective-C Interoperability Required**: Swift implementation does not need `@objc` annotations since it won't be called from Objective-C

### Current Objective-C Test Files Analysis
The following Objective-C tests need to be converted to Swift:
- **`ARTArchiveTests.m`**: Tests NSKeyedArchiver/Unarchiver functionality for push activation states
- **`ARTInternalLogTests.m`**: Tests internal logging mechanisms
- **`CryptoTest.m`**: Tests AES encryption/decryption with varying data lengths
- **`ObjcppTest.mm`**: Mixed Objective-C++ test (likely can be pure Swift)

### Swift Migration Requirements

The following technical patterns MUST be implemented during migration to ensure proper Swift functionality:

#### 1. Exception Handling
```objective-c
// Current Objective-C pattern
@throw [NSException exceptionWithName:@"InvalidArgument" reason:@"..." userInfo:nil];
```

Swift replacement:

```swift
fatalError("InvalidArgument: ...")
```

#### 2. Error Handling Pattern
```objective-c
// Objective-C NSError** pattern
- (id)methodWithError:(NSError **)error {
    // implementation
}
```

Swift replacement:

```swift
// Swift throws pattern
func method() throws -> SomeType {
    // implementation
}
```

#### 2. Atomic Properties
```objective-c
// Current usage (found in ARTGCD.m)
@property (atomic, copy, nullable) dispatch_block_t block;
```

Swift equivalent:

```swift
// Lock that implements the equivalent of Objective-C `atomic` for the `block` property
private let _blockLock = NSLock()
private var _block: DispatchWorkItem?
var block: DispatchWorkItem? {
    get { _blockLock.withLock { _block } }
    set { _blockLock.withLock { _block = newValue } }
}
```

#### 3. Logging Macros Migration

Current extensive usage of logging macros throughout codebase:

```objective-c
ARTLogError(logger, @"Error message: %@", error);
ARTLogWarn(logger, @"Warning: %@", message);
ARTLogInfo(logger, @"Info: %@", info);
ARTLogDebug(logger, @"Debug: %@", debug);
ARTLogVerbose(logger, @"Verbose: %@", verbose);
```

We will implement these Objective-C macros as Swift functions, injecting the `#fileID` and `#line` values using default arguments:

```swift
func ARTLogError(_ logger: ARTInternalLog, _ message: String, fileID: String = #fileID, line: Int = #line)
    logger.log(level: .error, file: fileID, line: line, message: message)
}
```

At the call site, instead of using varargs, we will use Swift string interpolation to pass a single message string to the logger.

#### 4. Nullability Analysis Required
- **Header Interfaces**: Some may have incorrect nullability annotations
- **Local Variables**: Need to determine proper optionals for local vars
- **Generic Collections**: Need to resolve generic type arguments for dictionaries/arrays

#### 5. Foundation Type Migration

Objective-C:

```objective-c
NSString *name;
NSMutableDictionary *dict;
NSDate *timestamp;
```

```swift
var name: String
var dict: [String: Any] // as an example — in reality, use whichever generic arguments are appropriate
var timestamp: Date
```

### Access Control Mapping

**Current Objective-C Structure:**
- **`Sources/Ably/include/`**: Public headers forming the public API
- **`Sources/Ably/PrivateHeaders/`**: Private headers with two categories:
  1. Private declarations for public types (exposed via `Ably.Private` module for testing)
  2. Private types not exposed externally

**Swift Access Control Strategy:**
```swift
// Public API (equivalent to include/ headers)
public class ARTRealtime {
    public func connect() { }
}

// Internal API (equivalent to private declarations for public types)
// Its definition should be inserted inside the implementation of the class
    internal func internalConnect() { }
}

// Private types (equivalent to private headers)
internal class ARTInternalHelper { }
```

### Swift-Specific Requirements

#### 1. Interface Priority
- **Favor header declarations over implementation** - headers more likely to have correct nullability and be accurate
- Use header interfaces as the source of truth for method signatures

### Low-Hanging Swift Improvements

While maintaining carbon-copy behavior, these Swift idioms can be adopted:

#### 1. Foundation Type Modernization
```objective-c
// Avoid in Swift
var items: NSMutableArray
var properties: NSMutableDictionary
var identifier: NSString

// Use instead
var items: [SomeType]
var properties: [String: Any]
var identifier: String
```

#### 2. Functional Programming Patterns
```objective-c
// Replace manual array building
NSMutableArray *results = [NSMutableArray new];
for (Item *item in items) {
    [results addObject:[self processItem:item]];
}

// With functional equivalent
let results = items.map { processItem($0) }
```


### File Organization

**Proposed Structure:**
```
Sources/
├── Ably/                    # Existing Objective-C (keep during transition)
├── AblySwift/              # New Swift implementation
│   ├── MigrationPlaceholders.swift  # Temporary placeholder types
│   ├── ARTAnnotation.swift
│   ├── ARTAttachRequestParams.swift
│   ├── ARTAuth.swift
│   ├── ... (all other migrated .swift files in single directory)
│   └── NSURLRequest+ARTUtils.swift
└── SocketRocket/          # Unchanged C/ObjC dependency
```

**File Organization Rules:**
- All migrated `.swift` files go directly into the `Sources/AblySwift/` directory
- No subdirectories or categorization - keep all Swift files in a flat structure
- `MigrationPlaceholders.swift` is the only special file for temporary placeholder types

## Migration Implementation Rules

### Error and Warning Handling

**Testing Requirement:** `swift build` must be run before considering any batch of files complete.

**Compilation Errors:**

**ACCEPTABLE immediate fixes (with `swift-migration:` comment):**
- Syntax translation (e.g., `@selector` → `#selector`)
- Import statement changes
- Type annotation fixes that don't change logic
- Property access syntax (`obj.property` → `obj.property`)
- Simple placeholder type additions to support dependencies

**UNACCEPTABLE without user guidance:**
- **Changing queue/threading behavior** (e.g., replacing `_userQueue` with `DispatchQueue.main`)
- **Replacing configured objects with new empty instances** (e.g., `options` → `ARTAuthOptions()`)
- **Changing callback patterns or timing**
- **Any change that alters runtime behavior**
- **Missing class inheritance relationships in placeholder types**

**When in doubt:** Stop migration and ask user for guidance

**Compilation Warnings:**
- **Obvious fixes**: Fix immediately and document in `swift-migration-files-progress.md`
- **Significant deviations**: Leave code as-is and document decision in `swift-migration-files-progress.md`

**Ignored Warnings:**
- Unused method call results
- Concurrency safety warnings (e.g., `Capture of 'callback' with non-sendable type`)

### Placeholder Type Management

**Purpose:** Handle dependencies on unmigrated types to prevent build failures.

**Placeholder File:** All placeholder types go in `Sources/AblySwift/MigrationPlaceholders.swift`

**Placeholder Creation Rules:**
1. **Enums**: Create the full enum definition
2. **Protocols**: Create the full protocol interface for method calls  
3. **Classes**: Create class with `fatalError()` implementations for all methods/properties
4. **Extensions**: Create extension with `fatalError()` implementations for all methods/properties
5. **CRITICAL - Inheritance**: Always check if placeholder classes should inherit from other types
   - Example: `ARTClientOptions` inherits from `ARTAuthOptions` in original code
   - Missing inheritance relationships will cause type errors during migration

**Placeholder Removal:** Remove placeholder types from `MigrationPlaceholders.swift` once proper implementation exists

### Code Comment Guidelines

**Migration Comments:** All migration-related code comments MUST start with `swift-migration: ` so that a human reviewer can distinguish them from the original Objective-C comments

**Required Comments:**
- **Source Location**: Before each migrated entity (class, method, property, enum, etc.), add a comment indicating its original location: `// swift-migration: original location Foo.m, line 123`
  - **IMPORTANT**: This comment must appear BEFORE any documentation comments or original Objective-C comments
  - **For entities with both declaration and definition**: Include both locations: `// swift-migration: original location Foo.h, line 45 and Foo.m, line 123`
- Any code modifications or skips during migration
- Decisions documented in both code and `swift-migration-files-progress.md`

**Original Comments:** Preserve all existing Objective-C comments unchanged

**CRITICAL: Implementation Rule**
- **ONLY implement methods/properties that exist in the .m file being migrated**
- **DO NOT implement methods/properties that are only declared in headers** - these may be inherited from parent classes or implemented elsewhere
- **If a header declares something not implemented in the .m file**: Document this in migration notes, do not implement it
- **ALL explanatory comments about what you're doing must have `swift-migration:` prefix**

**Source Location Comment Format:**
```swift
// swift-migration: original location ARTAuth.m, line 45
/// Authenticates the user with the given callback
/// - Parameter callback: The callback to invoke when authentication completes
func authenticate(callback: @escaping ARTAuthCallback) {
    // ... implementation
}

// swift-migration: original location ARTAuth.h, line 23
/// The ARTAuth class handles authentication for Ably connections
/// This class manages token-based authentication and callback patterns
public class ARTAuth {
    // ... implementation
}

// swift-migration: original location ARTTypes.h, line 156
/// Connection state enumeration
public enum ARTConnectionState: UInt {
    // ... cases
}
```

### Special Translation Rules

**Platform Conditionals:**
```objective-c
// Objective-C
#if TARGET_OS_IOS

// Swift
#if os(iOS)
```

**NSMutableArray Queue Operations:**

Do not migrate the following methods; instead just use the following at the call sites in `ARTRealtime`:

- `NSMutableArray.art_enqueue` → `Array.append`
- `NSMutableArray.art_dequeue` → `Array.popFirst`
- `NSMutableArray.art_peek` → `Array.first`

**NSMutableDictionary Parameters:**
- Methods accepting `NSMutableDictionary` → Accept `inout Dictionary` in Swift
- Examples: `ARTMessageOperation.writeToDictionary:`, `ARTJsonLikeEncoder.writeData:…`

## Risk Assessment & Mitigation

### High-Risk Areas

1. **State Machine Complexity**
   - **Risk**: Connection/channel state logic bugs
   - **Mitigation**: Line-by-line translation, extensive state testing

2. **Callback Pattern Translation** 
   - **Risk**: Memory leaks, retain cycles in closures
   - **Mitigation**: Careful weak reference management, cancellation patterns

3. **Platform-Specific Code**
   - **Risk**: iOS/macOS conditional compilation issues
   - **Mitigation**: Preserve exact `#if` patterns, platform-specific testing

4. **C Interop**  
   - **Risk**: Loss of C function compatibility
   - **Mitigation**: Maintain C functions, add Swift wrappers where needed

### Medium-Risk Areas

1. **External Dependencies**
   - **Risk**: Breaking changes in SocketRocket/msgpack integration  
   - **Mitigation**: Maintain existing integration patterns

2. **Build System Changes**
   - **Risk**: SPM configuration issues
   - **Mitigation**: Incremental build testing, dual-target approach

## Success Criteria

### Functional Requirements
- [ ] All existing tests pass against Swift implementation
- [ ] No behavioral changes in client-facing APIs
- [ ] Memory usage comparable to current implementation

### Quality Requirements  
- [ ] 100% API compatibility maintained
- [ ] Zero breaking changes for existing Swift/ObjC clients
- [ ] Clean Swift idioms where possible without breaking compatibility
- [ ] Comprehensive documentation updates

### Timeline
- **Total Duration:** 24-30 weeks (6-7 months) 
- **Team Size:** 2-3 senior developers
- **Batch Size:** 10-15 files per batch (2-3 weeks each)
- **Total Batches:** 9 batches + build system work
- **Testing:** Continuous compilation and testing after each batch

## Project Management & Review Process

### Migration Progress Documentation **[REQUIRED]**

**Progress Tracking Files:**
- **[`swift-migration-overall-progress.md`](swift-migration-overall-progress.md)**: Master table tracking migration status of all 115 files with progress column
- **[`swift-migration-files-progress.md`](swift-migration-files-progress.md)**: Detailed file-by-file progress with batch organization, compilation notes, and migration decisions
- **Update Frequency**: Both files must be updated as each file is migrated and each batch is completed

**CRITICAL: Progress File Format Preservation**
- **NEVER completely rewrite or change the structure** of these progress tracking files
- **ONLY update the relevant entries** (Progress column in overall file, Notes sections in detailed file)
- **PRESERVE the original table structure, headers, and file organization**
- When updating files, make minimal changes to only the relevant sections - this ensures clean Git diffs for human reviewers
- The files have established formats that must be maintained for proper tracking

**Documentation Standards:**
- Document **why** certain translation approaches were chosen
- Record patterns that can be reused for similar code
- Track deviations from mechanical translation with reasoning
- Maintain architectural decision records (ADRs) for significant choices
- Include code examples showing Objective-C → Swift transformations
- **All migration comments in code must start with `swift-migration: `**

## Conclusion

This mechanical migration approach prioritizes reliability and speed over Swift modernization. The result will be a Swift-native codebase that behaves identically to the current Objective-C implementation, providing a solid foundation for future Swift-idiomatic enhancements.

The phased approach allows for incremental validation and reduces risk by tackling components in dependency order, ensuring each layer is stable before building upon it. The comprehensive process management ensures both quality assurance and maintainability throughout the migration lifecycle.
