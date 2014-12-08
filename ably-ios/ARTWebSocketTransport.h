//
//  ARTWebSocketTransport.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTRealtimeTransport.h"
#import "ARTEncoder.h"

@class ARTOptions;
@class ARTRest;

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

@property (readwrite, weak, nonatomic) id<ARTRealtimeTransportDelegate> delegate;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTOptions *)options;

@end
