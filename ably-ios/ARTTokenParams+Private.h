//
//  ARTTokenParams+Private.h
//  ably
//
//  Created by Toni Cárdenas on 5/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTTokenParams_Private_h
#define ARTTokenParams_Private_h

#import "ARTTokenParams.h"
#import "CompatibilityMacros.h"

@interface ARTTokenParams (Private)

- (ARTTokenRequest *)sign:(NSString *)key;
- (ARTTokenRequest *)sign:(NSString *)key withNonce:(NSString *)nonce;

@end

#endif /* ARTTokenParams_Private_h */
