#import <Foundation/Foundation.h>
#import "ARTJitterCoefficientGenerator.h"

@implementation ARTDefaultJitterCoefficientGenerator

- (double)generateJitterCoefficient {
    return 0.8 + 0.2 * ((double)arc4random() / UINT32_MAX);
}

@end
