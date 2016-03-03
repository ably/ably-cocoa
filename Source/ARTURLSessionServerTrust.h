//
//  ARTURLSessionSelfSignedCertificate.h
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARTTypes.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTURLSessionServerTrust : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (void)get:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback;

@end

ART_ASSUME_NONNULL_END
