//
//  ARTConnectionDetails.h
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTProtocolMessage;

@interface ARTConnectionDetails : NSObject

ART_ASSUME_NONNULL_BEGIN

@property (readonly, strong, nonatomic, nullable) NSString *clientId;
@property (readonly, strong, nonatomic, nullable) NSString *connectionKey;

- (instancetype)initWithClientId:(NSString *__art_nullable)clientId connectionKey:(NSString *__art_nullable)connectionKey;

ART_ASSUME_NONNULL_END

@end
