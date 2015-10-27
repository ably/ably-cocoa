//
//  ARTWebSocketTransport.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

#import "ARTRealtimeTransport.h"
#import "ARTEncoder.h"

@class ARTClientOptions;
@class ARTRest;
@class ARTLog;

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options;

@property (readwrite, weak, nonatomic) id<ARTRealtimeTransportDelegate> delegate;

@end
