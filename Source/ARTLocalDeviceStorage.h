//
//  ARTLocalDeviceStorage.h
//  Ably
//
//  Created by Ricardo Pereira on 18/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTDeviceStorage <NSObject>
- (nullable NSData *)readKey:(NSString *)key;
- (void)writeKey:(NSString *)key withValue:(nullable NSData *)value;
@end

@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

@end

NS_ASSUME_NONNULL_END
