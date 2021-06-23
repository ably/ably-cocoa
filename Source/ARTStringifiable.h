//
//  ARTStringifiable.h
//  Ably
//
//  Created by Łukasz Szyszkowski on 21/06/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ARTStringifiable : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 This method converts values passed on init (BOOL, NSNumber, NSString) to NSSString
 @return NSString
 @throws NSException when value passed on init can't be reconized
 */
- (NSString*)convert;

+ (ARTStringifiable*)withString:(NSString *)value;
+ (ARTStringifiable*)withNumber:(NSNumber *)value;
+ (ARTStringifiable*)withBool:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
