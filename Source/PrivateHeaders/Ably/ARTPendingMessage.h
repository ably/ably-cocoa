#import <Foundation/Foundation.h>
#import "ARTQueuedMessage.h"
#import "ARTMessageSendStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTPendingMessage : ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTMessageSendCallback)ackCallback UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg ackCallback:(nullable ARTMessageSendCallback)ackCallback;

@end

NS_ASSUME_NONNULL_END
