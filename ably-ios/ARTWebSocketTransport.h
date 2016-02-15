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
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial;

@property (readwrite, weak, nonatomic) id<ARTRealtimeTransportDelegate> delegate;

@property (readonly, getter=getIsConnected) BOOL isConnected;

- (NSURL *)setupWebSocket:(__GENERIC(NSArray, NSURLQueryItem *) *)params withOptions:(ARTClientOptions *)options resumeKey:(NSString *__art_nullable)resumeKey connectionSerial:(NSNumber *__art_nullable)connectionSerial;

- (BOOL)getIsConnected;

@end

ART_ASSUME_NONNULL_END
