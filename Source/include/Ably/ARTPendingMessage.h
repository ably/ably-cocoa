#import <Foundation/Foundation.h>
#import <Ably/ARTQueuedMessage.h>

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface ARTPendingMessage : ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTStatusCallback)ackCallback UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg ackCallback:(nullable ARTStatusCallback)ackCallback;

@end

NS_ASSUME_NONNULL_END
