@import Foundation;
#import <Ably/ARTLogAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTLogAdapter ()

// Exposed to test suite so that the ARTDefaultInternalLogCore tests can make assertions about how that class’s convenience intializers initialize an ARTLogAdapter object.
@property (nonatomic, readonly) ARTLog *logger;

@end

NS_ASSUME_NONNULL_END
