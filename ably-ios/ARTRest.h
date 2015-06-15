//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"
#import "ARTTypes.h"
#import "ARTClientOptions.h"
#import "ARTPaginatedResult.h"

@class ARTCipherParams;
@class ARTTokenDetails;
@class ARTAuthTokenParams;
@class ARTRestPresence;

@interface ARTRestChannel : NSObject

- (id<ARTCancellable>)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (id<ARTCancellable>)publish:(id)payload cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

@property (readonly, strong, nonatomic) ARTRestPresence *presence;
@end

@interface ARTRestPresence : NSObject
- (instancetype) initWithChannel:(ARTRestChannel *) channel;
- (id<ARTCancellable>)get:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)getWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;
@end

@interface ARTRest : NSObject
{

}

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype) initWithOptions:(ARTClientOptions *) options;
-(instancetype) initWithKey:(NSString *) key;
- (id<ARTCancellable>) token:(ARTAuthTokenParams *) keyName tokenCb:(void (^)(ARTStatus * status, ARTTokenDetails *)) cb;

- (id<ARTCancellable>)time:(void(^)(ARTStatus * status, NSDate *time))cb;
- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb;
- (ARTRestChannel *)channel:(NSString *)channelName;
- (ARTRestChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;


-(ARTAuth *) auth;



@end
