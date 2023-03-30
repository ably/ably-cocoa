@import Foundation;
#import "ARTTypes.h"

@class ARTRetryAttempt;

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnectionStateChange ()

/**
 The retry attempt that triggered this connection state change, if any.

 Intended for tests that wish to make assertions about the exact value of retry delays.
 */
@property (nonatomic, readonly, nullable) ARTRetryAttempt *retryAttempt;

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(nullable ARTErrorInfo *)reason
                        retryIn:(NSTimeInterval)retryIn
                   retryAttempt:(nullable ARTRetryAttempt *)retryAttempt;

@end

NS_ASSUME_NONNULL_END
