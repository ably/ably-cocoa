//
//  ARTSentry.h
//  Ably
//
//  Created by Toni Cárdenas on 04/05/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#ifndef ARTSentry_h
#define ARTSentry_h

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTSentry : NSObject

+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception;

@end

id ART_orNull(id _Nullable obj);

ART_ASSUME_NONNULL_END

#endif /* ARTSentry_h */
