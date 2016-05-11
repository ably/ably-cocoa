//
//  ARTClientOptions+Private.h
//  ably
//
//  Created by Toni Cárdenas on 24/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTClientOptions_Private_h
#define ARTClientOptions_Private_h

#import "ARTClientOptions.h"

@interface ARTClientOptions ()

+ (void)setDefaultEnvironment:(NSString *__art_nullable)environment;
- (NSURLComponents *__art_nonnull)restUrlComponents;

@end

#endif /* ARTClientOptions_Private_h */
