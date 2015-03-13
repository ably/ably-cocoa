//
//  ARTAppSetup.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTOptions.h"

@interface ARTAppSetup : NSObject

+ (void)setupApp:(ARTOptions *)options cb:(void(^)(ARTOptions *options))cb;
+ (NSString *) restHost;
+ (NSString *) realtimeHost;
+ (float) timeout;

+(ARTOptions *) jsonRestOptions;
+(ARTOptions *) binaryRestOptions;
@end
