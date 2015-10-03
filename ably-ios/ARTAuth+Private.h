//
//  ARTAuth+Private.h
//  ably
//
//  Created by Ricardo Pereira on 03/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTAuth.h"

@class ARTAuthOptions;

NS_ASSUME_NONNULL_BEGIN

@interface ARTAuth (Private)

- (ARTAuthOptions *)mergeOptions:(nonnull ARTAuthOptions *)customOptions;
- (ARTAuthTokenParams *)mergeParams:(nonnull ARTAuthTokenParams *)customParams;

- (NSURL *)buildURL:(nonnull ARTAuthOptions *)options withParams:(nonnull ARTAuthTokenParams *)params;
- (NSMutableURLRequest *)buildRequest:(nonnull ARTAuthOptions *)options withParams:(nonnull ARTAuthTokenParams *)params;

@end

NS_ASSUME_NONNULL_END
