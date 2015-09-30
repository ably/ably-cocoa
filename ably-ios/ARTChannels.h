//
//  ARTChannels.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTMessage.h>
#import <ably/ARTCrypto.h>
#import <ably/ARTDataQuery.h>
#import <ably/ARTPaginatedResult.h>
#import <ably/ARTStatus.h>
#import <ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannelOptions : NSObject

@property (nonatomic, assign) BOOL isEncrypted;
@property (nonatomic, strong, nullable) ARTCipherParams *cipherParams;

+ (instancetype)unencrypted;

- (instancetype)initEncrypted:(ARTCipherParams *)cipherParams;

@end

@class ARTPresence;

@interface ARTChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) ARTPresence *presence;

- (void)publish:(nullable id)payload callback:(nullable ARTErrorCallback)callback;

- (void)publish:(nullable id)payload name:(nullable NSString *)name callback:(nullable ARTErrorCallback)callback;

- (void)publishMessage:(ARTMessage *)message callback:(nullable ARTErrorCallback)callback;

- (void)publishMessages:(NSArray /* <ARTMessage *> */ *)messages callback:(nullable ARTErrorCallback)callback;

- (void)history:(nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult /* <ARTMessage *> */ *__nullable result, NSError *__nullable error))callback;

@end

@interface ARTChannelCollection : NSObject<NSFastEnumeration>

- (BOOL)exists:(NSString *)channelName;

- (ARTChannel *)get:(NSString *)channelName;

- (ARTChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options;

- (void)releaseChannel:(ARTChannel *)channel;

@end

NS_ASSUME_NONNULL_END
