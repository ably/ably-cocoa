@import Foundation;
#import <Ably/ARTInternalLog.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDefaultInternalLogCore ()

// Exposed to test suite so that it can make assertions about how the convenience initializers populate it.
@property (nonatomic, readonly) id<ARTVersion2Log> logger;

@end

NS_ASSUME_NONNULL_END
