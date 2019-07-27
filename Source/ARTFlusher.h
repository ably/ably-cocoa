//
//  ARTFlusher.h
//  Ably
//
//  Created by Toni Cárdenas on 27/07/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#ifndef ARTFlusher_h
#define ARTFlusher_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTFlushable <NSObject>

- (void)flush;

@end

@interface ARTFlusher : NSObject

- (instancetype)init;
- (void)add:(id<ARTFlushable>)flushable;
- (void)remove:(id<ARTFlushable>)flushable;
- (void)flush;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTFlusher_h */
