//
//  ARTReachability.h
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTReachability_h
#define ARTReachability_h

#import "CompatibilityMacros.h"
#import "ARTLog.h"

ART_ASSUME_NONNULL_BEGIN

@protocol ARTReachability <NSObject>

- (instancetype)initWithLogger:(ARTLog *)logger;

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback;
- (void)off;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTReachability_h */
