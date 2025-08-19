#ifdef ABLY_SUPPORTS_PLUGINS

@import Foundation;
@import _AblyPluginSupportPrivate;

NS_ASSUME_NONNULL_BEGIN

/// Our implementation of `APPluginAPIProtocol`, which allows Ably-authored plugins to access the internals of this SDK.
@interface ARTPluginAPI: NSObject <APPluginAPIProtocol>

/// If not already registered, registers an instance of this class on the shared `APDependencyStore` instance.
///
/// This needs to be called before any plugin tries to fetch a `PluginAPI` from the `APDependencyStore`. Ensure that you call it as part of the initialization of any type that a plugin may try to extend.
+ (void)registerSelf;

@end

NS_ASSUME_NONNULL_END

#endif
