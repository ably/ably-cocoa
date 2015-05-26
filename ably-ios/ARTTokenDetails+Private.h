//
//  ARTTokenDetails+Private.h
//  ably
//
//  Created by vic on 22/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTTokenDetails (Private)
-(void) setExpiresTime:(int64_t) time;
@end

@interface ARTAuthOptions (Private)
-(void) setKeySecretTo:(NSString *) keySecret;
@end