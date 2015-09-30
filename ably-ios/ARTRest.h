//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTChannels.h>
#import <ably/ARTStatus.h>
#import <ably/ARTTypes.h>
#import <ably/ARTClientOptions.h>
#import <ably/ARTPaginatedResult.h>
#import <ably/ARTStats.h>
#import <ably/ARTPresence.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestPresence : ARTPresence

@end

@interface ARTRestChannel : ARTChannel

@property (nonatomic, strong, readonly) ARTRestPresence *presence;

@end

@interface ARTRestChannelCollection : ARTChannelCollection

- (ARTRestChannel *)get:(NSString *)channelName;
- (ARTRestChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options;

@end


# pragma mark - ARTRest

@interface ARTRest : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;

- (id<ARTCancellable>)token:(ARTAuthTokenParams *)keyName tokenCb:(void (^)(ARTStatus * status, ARTTokenDetails *))cb;

- (id<ARTCancellable>)time:(void(^)(ARTStatus * status, NSDate *time))cb;

- (void)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult /* <ARTStats *> */ *__nullable result))callback;

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb;

@property (nonatomic, strong, readonly) ARTLog *logger;
@property (nonatomic, strong, readonly) ARTRestChannelCollection *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;
@property (nonatomic, strong, readonly) ARTClientOptions *options;

@end

NS_ASSUME_NONNULL_END
