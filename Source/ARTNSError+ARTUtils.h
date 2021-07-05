//
//  NSError+ARTUtils.h
//  Ably
//
//  Created by Łukasz Szyszkowski on 05/07/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ARTUtils)

@property (nullable, readonly) NSString *requestId;

/**
 if `requestId` is nil, pointer to this instance is returned. If `requestId` is NOT nil, pointer to new instance of NSError is returned
 */
- (NSError *)errorWithRequestId:(nullable NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
