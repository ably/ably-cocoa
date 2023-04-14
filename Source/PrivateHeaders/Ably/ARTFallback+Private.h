#import <Ably/ARTFallback.h>

NS_ASSUME_NONNULL_BEGIN

extern void (^const ARTFallback_shuffleArray)(NSMutableArray *);

@interface ARTFallback ()

@property (readwrite, nonatomic) NSMutableArray<NSString *> *hosts;

@end

NS_ASSUME_NONNULL_END
