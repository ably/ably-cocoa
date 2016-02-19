//
//  ARTCrypto.h
//  ably-ios
//
//  Created by Jason Choy on 20/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTStatus.h"

@interface ARTCipherParams : NSObject
@property (readonly, strong, nonatomic) NSString *algorithm;
@property (readonly, strong, nonatomic) NSData *key;
@property (readonly, nonatomic) NSUInteger keyLength;
@property (readonly, strong, nonatomic) NSData *iv;
@property (readonly, getter=getMode) NSString *mode;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(NSData *)key keyLength:(NSUInteger)keyLength;

@end

@interface ARTCrypto : NSObject

+ (ARTCipherParams *)getDefaultParams;
+ (ARTCipherParams *)getDefaultParams:(NSData *)key;

@end
