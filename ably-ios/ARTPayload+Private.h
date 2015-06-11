//
//  ARTPayload+Private.h
//  ably
//
//  Created by vic on 22/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTPayload (Private)
{
    
}

+(NSArray *) parseEncodingChain:(NSString *) encodingChain key:(NSData *) key iv:(NSData *) iv;
+(id<ARTPayloadEncoder>) createEncoder:(NSString *) name key:(NSData *) key iv:(NSData *) iv;
+(size_t) getPayloadArraySizeLimit:(size_t) newLimit modify:(bool) modify;
@end
