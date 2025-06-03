@import Foundation;
@import Ably;

NS_ASSUME_NONNULL_BEGIN

/// `APTPluginTestingAPI` is intended to be used by the test suite of an Ably-authored plugin. It exposes any parts of ably-cocoa's private API that are needed for testing a plugin.
NS_SWIFT_NAME(PluginTestingAPI)
NS_SWIFT_SENDABLE
@interface APTPluginTestingAPI: NSObject

/// An example method that always returns `YES`. TODO: remove once we've added a proper API to this class.
+ (BOOL)exampleMethodThatReturnsTrue;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
