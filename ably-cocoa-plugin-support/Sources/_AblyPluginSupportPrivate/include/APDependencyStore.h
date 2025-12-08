@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol APPluginAPIProtocol;

/// `APDependencyStoreProtocol` allows ably-cocoa to register an instance of `APPluginAPI` (that is, the interface through which Ably-authored plugins access ably-cocoa's internals) to be subsequently fetched by a plugin.
///
/// The canonical implementation of this protocol is that returned by `+[APDependencyStore sharedInstance]`.
NS_SWIFT_NAME(DependencyStoreProtocol)
NS_SWIFT_SENDABLE
@protocol APDependencyStoreProtocol

/// Stores an instance of `APPluginAPI` to be subsequently retrieved by `-fetchPluginAPI`.
///
/// This method should be used by ably-cocoa.
///
/// - Note: This method can be called from any thread.
- (void)registerPluginAPI:(id<APPluginAPIProtocol>)pluginAPI;

/// Retrieves an instance of `APPluginAPI` that was previously stored by `-registerPluginAPI:`.
///
/// This method should be used by plugins. It is a programmer error to call it if `-registerPluginAPI:` has not yet been called.
///
/// - Note: This method can be called from any thread.
- (id<APPluginAPIProtocol>)fetchPluginAPI;

@end

/// Provides the canonical implementation of `APDependencyStoreProtocol`.
NS_SWIFT_NAME(DependencyStore)
NS_SWIFT_SENDABLE
@interface APDependencyStore: NSObject <APDependencyStoreProtocol>

/// Returns the singleton instance of this class.
+ (APDependencyStore *)sharedInstance;

// Use `+sharedInstance` instead.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
