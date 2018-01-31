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
- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)value forKey:(NSString *)key;
@end

@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

@end

NS_ASSUME_NONNULL_END
