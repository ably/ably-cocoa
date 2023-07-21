#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTMessageFilter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTFilteredMessageCallbackFactory : NSObject

- (instancetype) init NS_UNAVAILABLE;
+ (ARTMessageCallback) createFilteredCallback:(ARTMessageCallback) original filter:(ARTMessageFilter *) filter;

@end

NS_ASSUME_NONNULL_END
