//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTStatus.h>
#import <ably/ARTTypes.h>
#import <ably/ARTClientOptions.h>
#import <ably/ARTPaginatedResult.h>
#import <ably/ARTStats.h>

@class ARTLog;
@class ARTCipherParams;
@class ARTTokenDetails;
@class ARTAuthTokenParams;
@class ARTRestPresence;


# pragma mark - ARTRestChannel

@interface ARTRestChannel : NSObject

- (id<ARTCancellable>)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (id<ARTCancellable>)publish:(id)payload cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback;

@property (readonly, strong, nonatomic) ARTRestPresence *presence;

@end


# pragma mark - ARTRestPresence

@interface ARTRestPresence : NSObject

- (instancetype) initWithChannel:(ARTRestChannel *) channel;
- (id<ARTCancellable>)get:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)getWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback;

@end


# pragma mark - ARTRest

@interface ARTRest : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;

- (id<ARTCancellable>)token:(ARTAuthTokenParams *)keyName tokenCb:(void (^)(ARTStatus * status, ARTTokenDetails *)) cb;
- (id<ARTCancellable>)time:(void(^)(ARTStatus *status, NSDate *time))cb;
- (id<ARTCancellable>)stats:(ARTStatsQuery *)query callback:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb;
- (ARTRestChannel *)channel:(NSString *)channelName;
- (ARTRestChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;

- (ARTAuth *)auth;

@property (nonatomic, strong, readonly) ARTLog *logger;

@end
