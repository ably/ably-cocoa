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

@class ARTClientOptions;
@class ARTRest;
@class ARTLog;

ART_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;
@property (readonly, strong, nonatomic) ARTLog *protocolMessagesLogger;

@end

ART_ASSUME_NONNULL_END
