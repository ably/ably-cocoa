#import <Foundation/Foundation.h>

/// :nodoc:
@interface ARTBaseQuery : NSObject

@property (nonatomic, getter=isFrozen) BOOL frozen;

- (void)throwIfFrozen;

@end
