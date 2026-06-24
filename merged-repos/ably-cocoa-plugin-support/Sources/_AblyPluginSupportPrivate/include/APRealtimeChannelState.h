/// A copy of ably-cocoa's `ARTRealtimeChannelState`.
typedef NS_CLOSED_ENUM(NSUInteger, APRealtimeChannelState) {
    APRealtimeChannelStateInitialized,
    APRealtimeChannelStateAttaching,
    APRealtimeChannelStateAttached,
    APRealtimeChannelStateDetaching,
    APRealtimeChannelStateDetached,
    APRealtimeChannelStateSuspended,
    APRealtimeChannelStateFailed
} NS_SWIFT_NAME(RealtimeChannelState);
