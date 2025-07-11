@import Foundation;

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/// The interface that plugins use to interact with a realtime client.
///
/// This exists so that plugins do not need to make use of the public `ARTRealtime` class, which allows the internal components of ably-cocoa to continue the (existing before we introduced plugins) pattern of also not making use of this public class.
///
/// Note that AblyPlugin does not allow you to pass it arbitrary objects that conform to this protocol; rather you must pass it an object which it previously passed to the plugin (e.g. via TODO we don't have an example yet; will come later).
/// TODO mention public API, remove this
NS_SWIFT_NAME(RealtimeClient)
NS_SWIFT_SENDABLE
@protocol APRealtimeClient <NSObject>

/// Returns the server time, as calculated from the client's stored offset between the local clock and the server time. Copied from ably-js, not yet implemented. Will document this method once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion;

@end

NS_ASSUME_NONNULL_END
