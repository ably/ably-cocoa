//
//  ARTHttp+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 23/04/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import <Ably/ARTHttp.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTHttp (Private)

@property (readonly) dispatch_queue_t queue;

@end

NS_ASSUME_NONNULL_END
