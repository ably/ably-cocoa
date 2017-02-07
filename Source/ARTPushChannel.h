//
//  ARTPushChannel.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTPushChannel : NSObject

- (void)subscribeForDevice:(NSString *)device;
- (void)subscribeForClientId:(NSString *)clientId;

- (void)unsubscribeForDevice:(NSString *)device;
- (void)unsubscribeForClientId:(NSString *)clientId;

@end
