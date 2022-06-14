#import "ARTDeltaCodec+VCDiffDecoder.h"

@implementation ARTDeltaCodec (VCDiffDecoder)

- (NSData *)decode:(NSData *)delta base:(NSData *)base error:(NSError **)error{
    return [ARTDeltaCodec applyDelta:delta previous:base error:error];
}

@end
