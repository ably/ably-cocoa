//
//  ARTExposed.h
//  Ably
//
//  Created by Toni Cárdenas on 05/08/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#ifndef ARTExposed_h
#define ARTExposed_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTQueuedDealloc : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id)ref queue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTExposed_h */
