#import <Foundation/Foundation.h>

#import <Ably/ARTMessage.h>
#import <Ably/ARTMessageFilter.h>

NS_ASSUME_NONNULL_BEGIN


@interface ARTMessageExtrasFilter : NSObject

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFilter:(ARTMessageFilter*) filter;
- (bool) onMessage:(ARTMessage*) message;

@end

NS_ASSUME_NONNULL_END
