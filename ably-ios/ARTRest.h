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
#import "ARTOptions.h"
#import "ARTPaginatedResult.h"

@class ARTCipherParams;
@class ARTAuthToken;
@class ARTAuthTokenParams;

@interface ARTRestChannel : NSObject

- (id<ARTCancellable>)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (id<ARTCancellable>)publish:(id)payload cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

- (id<ARTCancellable>)presence:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)presenceWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)presenceHistory:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)presenceHistoryWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

@end

@interface ARTRest : NSObject
{

}
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithOptions:(ARTOptions *)options;



//TODO really not sure about this.
- (id<ARTCancellable>) token:(ARTAuthTokenParams *) keyId tokenCb:(void (^)(ARTAuthToken *)) cb;


- (id<ARTCancellable>)time:(void(^)(ARTStatus status, NSDate *time))cb;
- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;
- (ARTRestChannel *)channel:(NSString *)channelName;
- (ARTRestChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;

@end
