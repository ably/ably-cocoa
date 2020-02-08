//
//  ARTDeltaCodec.m
//  Ably
//
//  Created by Ricardo Pereira on 08/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import "ARTDeltaCodec.h"

@implementation ARTDeltaCodec (ARTDeltaCodec_VCDiffDecoder)

- (NSData *)decode:(NSData *)delta base:(NSData *)base error:(NSError **)error{
    return [ARTDeltaCodec applyDelta:delta previous:base error:error];
}

@end
