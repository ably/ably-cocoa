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

### Implementation Phases

#### Phase 1: Foundation & Types (Low Dependencies)
- **Target:** 15 Foundation extension files + ARTTypes
- **Complexity:** Low - mostly utility functions and type definitions
- **Timeline:** 1-2 weeks

**Key Files:**
```
NSString+ARTUtil.m → StringExtensions.swift
NSDate+ARTUtil.m → DateExtensions.swift
NSDictionary+ARTDictionaryUtil.m → DictionaryExtensions.swift
ARTTypes.m → ARTTypes.swift
ARTConstants.m → ARTConstants.swift
```

**Swift Adaptations:**
```objective-c
// Objective-C
typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    // ...
};

// Swift
@objc public enum ARTRealtimeConnectionState: UInt, CaseIterable, Sendable {
    case initialized = 0
    case connecting = 1
    case connected = 2
    // ...
}
```

#### Phase 2: Encoding & Data Processing (Medium Dependencies)
- **Target:** 8 encoder/decoder classes
- **Complexity:** Medium - handles multiple data formats
- **Timeline:** 2-3 weeks

**Key Files:**
```
ARTJsonEncoder.m → JsonEncoder.swift
ARTMsgPackEncoder.m → MsgPackEncoder.swift
ARTDataEncoder.m → DataEncoder.swift
```

#### Phase 3: Networking & Authentication (Medium-High Dependencies)
- **Target:** 12 networking and auth-related classes
- **Complexity:** Medium-High - complex async patterns
- **Timeline:** 3-4 weeks

**Key Files:**
```
ARTHttp.m → HttpClient.swift
ARTAuth.m → Auth.swift  
ARTFallback.m → FallbackManager.swift
```

**Callback Pattern Translation:**
```objective-c
// Objective-C
typedef void (^ARTTokenDetailsCallback)(ARTTokenDetails *_Nullable result, NSError *_Nullable error);

// Swift  
public typealias ARTTokenDetailsCallback = (ARTTokenDetails?, Error?) -> Void
// Or with Result type for new Swift APIs
public typealias ARTTokenDetailsResult = (Result<ARTTokenDetails, Error>) -> Void
```

#### Phase 4: Message & Protocol Handling (High Dependencies)
- **Target:** 10 message processing classes
- **Complexity:** High - core business logic
- **Timeline:** 4-5 weeks

#### Phase 5: Channel Management (High Dependencies)  
- **Target:** 15 channel-related classes
- **Complexity:** High - complex state management
- **Timeline:** 4-5 weeks

#### Phase 6: Real-time Transport (Highest Dependencies)
- **Target:** 8 transport and connection classes  
- **Complexity:** Highest - complex async state machines
- **Timeline:** 5-6 weeks

#### Phase 7: Push Notifications (iOS-Specific)
- **Target:** 12 push-related classes
- **Complexity:** High - platform-specific code
- **Timeline:** 3-4 weeks

#### Phase 8: Main Clients & Proxies (Final Integration)
- **Target:** 15 client and proxy classes
- **Complexity:** High - integration of all components
- **Timeline:** 3-4 weeks

#### Phase 9: Build System & Testing
- **Target:** Package.swift updates, test execution
- **Complexity:** Medium - build configuration
- **Timeline:** 2-3 weeks

## Technical Requirements

### API Compatibility

**Must Preserve:**
- All public class names and method signatures
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

// Swift replacement
fatalError("InvalidArgument: ...")
// Or preferably, convert to exit tests where possible
```

#### 2. Atomic Properties
```objective-c
// Current usage (found in ARTGCD.m)
@property (atomic, copy, nullable) dispatch_block_t block;

// Swift equivalent
private let _lock = NSLock()
private var _block: DispatchWorkItem?
var block: DispatchWorkItem? {
    get { _lock.withLock { _block } }
    set { _lock.withLock { _block = newValue } }
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

// Swift replacement - initially use functions
func ARTLogError(_ logger: ARTInternalLog, _ message: String, _ args: CVarArg...) {
    logger.log(String(format: message, arguments: args), withLevel: .error)
}
```

#### 4. Nullability Analysis Required
- **Header Interfaces**: Some may have incorrect nullability annotations
- **Local Variables**: Need to determine proper optionals for local vars
- **Generic Collections**: Need to resolve generic type arguments for dictionaries/arrays

#### 5. Foundation Type Migration
```objective-c
// Objective-C
NSString *name;
NSMutableDictionary *dict;
NSDate *timestamp;

// Swift equivalent
var name: String
var dict: [String: Any]
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
extension ARTRealtime {
    internal func internalConnect() { }
}

// Private types (equivalent to private headers)
internal class ARTInternalHelper { }
```

### Swift-Specific Requirements

#### 1. Import Strategy
```swift
// Use internal imports for all external dependencies
@_implementationOnly import SocketRocket
@_implementationOnly import msgpack
@_implementationOnly import AblyDeltaCodec
```

#### 2. Interface Priority
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
- **Total Duration:** 30-35 weeks (7-8 months)
- **Team Size:** 2-3 senior developers
- **Testing:** Continuous throughout each phase

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