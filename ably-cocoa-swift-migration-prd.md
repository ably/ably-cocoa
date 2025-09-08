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

The following table shows all 106 `.m` files to be migrated in alphabetical order, along with their associated header files and resulting Swift file names:

| .m File | Associated .h Files | Resulting .swift File |
|---------|-------------------|---------------------|
| ARTAnnotation.m | ARTAnnotation+Private.h, ARTAnnotation.h | ARTAnnotation.swift |
| ARTAttachRequestParams.m | ARTAttachRequestParams.h | ARTAttachRequestParams.swift |
| ARTAttachRetryState.m | ARTAttachRetryState.h | ARTAttachRetryState.swift |
| ARTAuth.m | ARTAuth+Private.h, ARTAuth.h | ARTAuth.swift |
| ARTAuthDetails.m | ARTAuthDetails.h | ARTAuthDetails.swift |
| ARTAuthOptions.m | ARTAuthOptions+Private.h, ARTAuthOptions.h | ARTAuthOptions.swift |
| ARTBackoffRetryDelayCalculator.m | ARTBackoffRetryDelayCalculator.h | ARTBackoffRetryDelayCalculator.swift |
| ARTBaseMessage.m | ARTBaseMessage+Private.h, ARTBaseMessage.h | ARTBaseMessage.swift |
| ARTChannel.m | ARTChannel+Private.h, ARTChannel.h | ARTChannel.swift |
| ARTChannelOptions.m | ARTChannelOptions+Private.h, ARTChannelOptions.h | ARTChannelOptions.swift |
| ARTChannelProtocol.m | ARTChannelProtocol.h | ARTChannelProtocol.swift |
| ARTChannelStateChangeParams.m | ARTChannelStateChangeParams.h | ARTChannelStateChangeParams.swift |
| ARTChannels.m | ARTChannels+Private.h, ARTChannels.h | ARTChannels.swift |
| ARTClientInformation.m | ARTClientInformation+Private.h, ARTClientInformation.h | ARTClientInformation.swift |
| ARTClientOptions.m | ARTClientOptions+Private.h, ARTClientOptions.h | ARTClientOptions.swift |
| ARTConnectRetryState.m | ARTConnectRetryState.h | ARTConnectRetryState.swift |
| ARTConnection.m | ARTConnection+Private.h, ARTConnection.h | ARTConnection.swift |
| ARTConnectionDetails.m | ARTConnectionDetails+Private.h, ARTConnectionDetails.h | ARTConnectionDetails.swift |
| ARTConnectionStateChangeParams.m | ARTConnectionStateChangeParams.h | ARTConnectionStateChangeParams.swift |
| ARTConstants.m | ARTConstants.h | ARTConstants.swift |
| ARTContinuousClock.m | ARTContinuousClock.h | ARTContinuousClock.swift |
| ARTCrypto.m | ARTCrypto+Private.h, ARTCrypto.h | ARTCrypto.swift |
| ARTDataEncoder.m | ARTDataEncoder.h | ARTDataEncoder.swift |
| ARTDataQuery.m | ARTDataQuery+Private.h, ARTDataQuery.h | ARTDataQuery.swift |
| ARTDefault.m | ARTDefault+Private.h, ARTDefault.h | ARTDefault.swift |
| ARTDeviceDetails.m | ARTDeviceDetails+Private.h, ARTDeviceDetails.h | ARTDeviceDetails.swift |
| ARTDeviceIdentityTokenDetails.m | ARTDeviceIdentityTokenDetails+Private.h, ARTDeviceIdentityTokenDetails.h | ARTDeviceIdentityTokenDetails.swift |
| ARTDevicePushDetails.m | ARTDevicePushDetails+Private.h, ARTDevicePushDetails.h | ARTDevicePushDetails.swift |
| ARTErrorChecker.m | ARTErrorChecker.h | ARTErrorChecker.swift |
| ARTEventEmitter.m | ARTEventEmitter+Private.h, ARTEventEmitter.h | ARTEventEmitter.swift |
| ARTFallback.m | ARTFallback+Private.h, ARTFallback.h | ARTFallback.swift |
| ARTFallbackHosts.m | ARTFallbackHosts.h | ARTFallbackHosts.swift |
| ARTFormEncode.m | ARTFormEncode.h | ARTFormEncode.swift |
| ARTGCD.m | ARTGCD.h | ARTGCD.swift |
| ARTHTTPPaginatedResponse.m | ARTHTTPPaginatedResponse+Private.h, ARTHTTPPaginatedResponse.h | ARTHTTPPaginatedResponse.swift |
| ARTHttp.m | ARTHttp+Private.h, ARTHttp.h | ARTHttp.swift |
| ARTInternalLog.m | ARTInternalLog+Testing.h, ARTInternalLog.h | ARTInternalLog.swift |
| ARTInternalLogCore.m | ARTInternalLogCore+Testing.h, ARTInternalLogCore.h | ARTInternalLogCore.swift |
| ARTJitterCoefficientGenerator.m | ARTJitterCoefficientGenerator.h | ARTJitterCoefficientGenerator.swift |
| ARTJsonEncoder.m | ARTJsonEncoder.h | ARTJsonEncoder.swift |
| ARTJsonLikeEncoder.m | ARTJsonLikeEncoder.h | ARTJsonLikeEncoder.swift |
| ARTLocalDevice.m | ARTLocalDevice+Private.h, ARTLocalDevice.h | ARTLocalDevice.swift |
| ARTLocalDeviceStorage.m | ARTLocalDeviceStorage.h | ARTLocalDeviceStorage.swift |
| ARTLog.m | ARTLog+Private.h, ARTLog.h | ARTLog.swift |
| ARTLogAdapter.m | ARTLogAdapter+Testing.h, ARTLogAdapter.h | ARTLogAdapter.swift |
| ARTMessage.m | ARTMessage.h | ARTMessage.swift |
| ARTMessageOperation.m | ARTMessageOperation+Private.h, ARTMessageOperation.h | ARTMessageOperation.swift |
| ARTMsgPackEncoder.m | ARTMsgPackEncoder.h | ARTMsgPackEncoder.swift |
| ARTOSReachability.m | ARTOSReachability.h | ARTOSReachability.swift |
| ARTPaginatedResult.m | ARTPaginatedResult+Private.h, ARTPaginatedResult+Subclass.h, ARTPaginatedResult.h | ARTPaginatedResult.swift |
| ARTPendingMessage.m | ARTPendingMessage.h | ARTPendingMessage.swift |
| ARTPluginAPI.m | ARTPluginAPI.h | ARTPluginAPI.swift |
| ARTPluginDecodingContext.m | ARTPluginDecodingContext.h | ARTPluginDecodingContext.swift |
| ARTPresence.m | ARTPresence+Private.h, ARTPresence.h | ARTPresence.swift |
| ARTPresenceMessage.m | ARTPresenceMessage+Private.h, ARTPresenceMessage.h | ARTPresenceMessage.swift |
| ARTProtocolMessage.m | ARTProtocolMessage+Private.h, ARTProtocolMessage.h | ARTProtocolMessage.swift |
| ARTPublicRealtimeChannelUnderlyingObjects.m | ARTPublicRealtimeChannelUnderlyingObjects.h | ARTPublicRealtimeChannelUnderlyingObjects.swift |
| ARTPush.m | ARTPush+Private.h, ARTPush.h | ARTPush.swift |
| ARTPushActivationEvent.m | ARTPushActivationEvent.h | ARTPushActivationEvent.swift |
| ARTPushActivationState.m | ARTPushActivationState.h | ARTPushActivationState.swift |
| ARTPushActivationStateMachine.m | ARTPushActivationStateMachine+Private.h, ARTPushActivationStateMachine.h | ARTPushActivationStateMachine.swift |
| ARTPushAdmin.m | ARTPushAdmin+Private.h, ARTPushAdmin.h | ARTPushAdmin.swift |
| ARTPushChannel.m | ARTPushChannel+Private.h, ARTPushChannel.h | ARTPushChannel.swift |
| ARTPushChannelSubscription.m | ARTPushChannelSubscription.h | ARTPushChannelSubscription.swift |
| ARTPushChannelSubscriptions.m | ARTPushChannelSubscriptions+Private.h, ARTPushChannelSubscriptions.h | ARTPushChannelSubscriptions.swift |
| ARTPushDeviceRegistrations.m | ARTPushDeviceRegistrations+Private.h, ARTPushDeviceRegistrations.h | ARTPushDeviceRegistrations.swift |
| ARTQueuedDealloc.m | ARTQueuedDealloc.h | ARTQueuedDealloc.swift |
| ARTQueuedMessage.m | ARTQueuedMessage.h | ARTQueuedMessage.swift |
| ARTRealtime.m | ARTRealtime+Private.h, ARTRealtime+WrapperSDKProxy.h, ARTRealtime.h | ARTRealtime.swift |
| ARTRealtimeAnnotations.m | ARTRealtimeAnnotations+Private.h, ARTRealtimeAnnotations.h | ARTRealtimeAnnotations.swift |
| ARTRealtimeChannel.m | ARTRealtimeChannel+Private.h, ARTRealtimeChannel.h | ARTRealtimeChannel.swift |
| ARTRealtimeChannelOptions.m | ARTRealtimeChannelOptions.h | ARTRealtimeChannelOptions.swift |
| ARTRealtimeChannels.m | ARTRealtimeChannels+Private.h, ARTRealtimeChannels.h | ARTRealtimeChannels.swift |
| ARTRealtimePresence.m | ARTRealtimePresence+Private.h, ARTRealtimePresence.h | ARTRealtimePresence.swift |
| ARTRealtimeTransport.m | ARTRealtimeTransport.h | ARTRealtimeTransport.swift |
| ARTRealtimeTransportFactory.m | ARTRealtimeTransportFactory.h | ARTRealtimeTransportFactory.swift |
| ARTRest.m | ARTRest+Private.h, ARTRest.h | ARTRest.swift |
| ARTRestChannel.m | ARTRestChannel+Private.h, ARTRestChannel.h | ARTRestChannel.swift |
| ARTRestChannels.m | ARTRestChannels+Private.h, ARTRestChannels.h | ARTRestChannels.swift |
| ARTRestPresence.m | ARTRestPresence+Private.h, ARTRestPresence.h | ARTRestPresence.swift |
| ARTRetrySequence.m | ARTRetrySequence.h | ARTRetrySequence.swift |
| ARTStats.m | ARTStats.h | ARTStats.swift |
| ARTStatus.m | ARTStatus.h | ARTStatus.swift |
| ARTStringifiable.m | ARTStringifiable+Private.h, ARTStringifiable.h | ARTStringifiable.swift |
| ARTTestClientOptions.m | ARTTestClientOptions.h | ARTTestClientOptions.swift |
| ARTTokenDetails.m | ARTTokenDetails.h | ARTTokenDetails.swift |
| ARTTokenParams.m | ARTTokenParams+Private.h, ARTTokenParams.h | ARTTokenParams.swift |
| ARTTokenRequest.m | ARTTokenRequest.h | ARTTokenRequest.swift |
| ARTTypes.m | ARTTypes+Private.h, ARTTypes.h | ARTTypes.swift |
| ARTURLSessionServerTrust.m | ARTURLSessionServerTrust.h | ARTURLSessionServerTrust.swift |
| ARTWebSocketFactory.m | ARTWebSocketFactory.h | ARTWebSocketFactory.swift |
| ARTWebSocketTransport.m | ARTWebSocketTransport+Private.h, ARTWebSocketTransport.h | ARTWebSocketTransport.swift |
| ARTWrapperSDKProxyOptions.m | ARTWrapperSDKProxyOptions.h | ARTWrapperSDKProxyOptions.swift |
| ARTWrapperSDKProxyPush.m | ARTWrapperSDKProxyPush+Private.h, ARTWrapperSDKProxyPush.h | ARTWrapperSDKProxyPush.swift |
| ARTWrapperSDKProxyPushAdmin.m | ARTWrapperSDKProxyPushAdmin+Private.h, ARTWrapperSDKProxyPushAdmin.h | ARTWrapperSDKProxyPushAdmin.swift |
| ARTWrapperSDKProxyPushChannel.m | ARTWrapperSDKProxyPushChannel+Private.h, ARTWrapperSDKProxyPushChannel.h | ARTWrapperSDKProxyPushChannel.swift |
| ARTWrapperSDKProxyPushChannelSubscriptions.m | ARTWrapperSDKProxyPushChannelSubscriptions+Private.h, ARTWrapperSDKProxyPushChannelSubscriptions.h | ARTWrapperSDKProxyPushChannelSubscriptions.swift |
| ARTWrapperSDKProxyPushDeviceRegistrations.m | ARTWrapperSDKProxyPushDeviceRegistrations+Private.h, ARTWrapperSDKProxyPushDeviceRegistrations.h | ARTWrapperSDKProxyPushDeviceRegistrations.swift |
| ARTWrapperSDKProxyRealtime.m | ARTWrapperSDKProxyRealtime+Private.h, ARTWrapperSDKProxyRealtime.h | ARTWrapperSDKProxyRealtime.swift |
| ARTWrapperSDKProxyRealtimeAnnotations.m | ARTWrapperSDKProxyRealtimeAnnotations+Private.h, ARTWrapperSDKProxyRealtimeAnnotations.h | ARTWrapperSDKProxyRealtimeAnnotations.swift |
| ARTWrapperSDKProxyRealtimeChannel.m | ARTWrapperSDKProxyRealtimeChannel+Private.h, ARTWrapperSDKProxyRealtimeChannel.h | ARTWrapperSDKProxyRealtimeChannel.swift |
| ARTWrapperSDKProxyRealtimeChannels.m | ARTWrapperSDKProxyRealtimeChannels+Private.h, ARTWrapperSDKProxyRealtimeChannels.h | ARTWrapperSDKProxyRealtimeChannels.swift |
| ARTWrapperSDKProxyRealtimePresence.m | ARTWrapperSDKProxyRealtimePresence+Private.h, ARTWrapperSDKProxyRealtimePresence.h | ARTWrapperSDKProxyRealtimePresence.swift |
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

### Swift Migration Challenges to Resolve

#### 1. Exception Handling
```objective-c
// Current Objective-C pattern
@throw [NSException exceptionWithName:@"InvalidArgument" reason:@"..." userInfo:nil];
```

Swift replacement:

```swift
fatalError("InvalidArgument: ...")
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

### Build Configuration

**Package.swift Updates:**
```swift
.target(
    name: "AblySwift",
    dependencies: [
        "SocketRocket",
        .product(name: "msgpack", package: "msgpack-objective-c"),
        .product(name: "AblyDeltaCodec", package: "delta-codec-cocoa"),
        .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
    ],
    swiftSettings: [
        .swiftLanguageMode(.v5)
    ]
)
```

**Transitional Approach:**
1. Keep existing "Ably" target (Objective-C) during migration
2. Build new "AblySwift" target alongside
3. Convert 4 Objective-C test files to Swift tests in main test suite
4. Switch primary target once Swift implementation is complete
5. Remove Objective-C target in future release

### File Organization

**Proposed Structure:**
```
Sources/
├── Ably/                    # Existing Objective-C (keep during transition)
├── AblySwift/              # New Swift implementation
│   ├── Foundation/         # Swift extensions
│   ├── Core/              # Types, constants, utilities
│   ├── Encoding/          # Data encoding/decoding
│   ├── Networking/        # HTTP, auth, fallback
│   ├── Messaging/         # Message handling
│   ├── Channels/          # Channel management
│   ├── Realtime/          # Transport, connection
│   ├── Push/              # Push notifications  
│   ├── Clients/           # Main ARTRest, ARTRealtime
│   └── Proxies/           # Wrapper SDK proxies
└── SocketRocket/          # Unchanged C/ObjC dependency
```

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
- [ ] Performance within 5% of Objective-C implementation
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

**Real-Time Migration Log:**
- **File**: [`ably-cocoa-swift-migration-log.md`](ably-cocoa-swift-migration-log.md)
- **Purpose**: Comprehensive documentation of all migration decisions, challenges, and solutions
- **Update Frequency**: After completing each significant component or resolving any technical challenge
- **Content Requirements**:
  - Technical decisions made during migration (with justification)
  - Challenges encountered and solutions applied
  - Swift-specific patterns established
  - Architecture changes from Objective-C to Swift
  - Performance considerations and optimizations
  - Compilation and testing status for each phase

**Documentation Standards:**
- Document **why** certain translation approaches were chosen
- Record patterns that can be reused for similar code
- Track deviations from mechanical translation with reasoning
- Maintain architectural decision records (ADRs) for significant choices
- Include code examples showing Objective-C → Swift transformations

### Progress Tracking
**LLM Progress Documentation:**
- Use `update_todo_list` tool after completing each major component
- Create commit-ready file batches for each migration phase
- Update migration log with progress details and technical decisions
- Generate summary reports showing:
  - Files migrated per phase with line count comparisons
  - Key architectural decisions made during translation
  - Deviations from mechanical translation (with justification)

### Human Review Process
**Structured Review Approach:**
- **Phase-by-Phase Review**: Complete one dependency layer before proceeding
- **Side-by-Side Comparison**: Generate diff reports showing Objective-C → Swift transformations
- **Key Decision Documentation**: Maintain decision log for non-obvious translations
- **Test Result Validation**: Provide before/after test execution reports

### Upstream Change Integration
**Process for Ongoing Objective-C Updates:**
1. **Change Detection**: Monitor upstream commits to Objective-C files
2. **Impact Analysis**: Identify which Swift files need corresponding updates
3. **Mechanical Re-application**: Apply same translation patterns to new changes
4. **Regression Testing**: Ensure changes don't break existing Swift implementation
5. **Documentation Updates**: Update translation decision log for new patterns

**Change Tracking Strategy:**
```
Git workflow:
feature/swift-migration-phase-1  # Foundation & Types
feature/swift-migration-phase-2  # Encoding & Data
feature/swift-migration-phase-3  # Networking & Auth
...
```

## Conclusion

This mechanical migration approach prioritizes reliability and speed over Swift modernization. The result will be a Swift-native codebase that behaves identically to the current Objective-C implementation, providing a solid foundation for future Swift-idiomatic enhancements.

The phased approach allows for incremental validation and reduces risk by tackling components in dependency order, ensuring each layer is stable before building upon it. The comprehensive process management ensures both quality assurance and maintainability throughout the migration lifecycle.
