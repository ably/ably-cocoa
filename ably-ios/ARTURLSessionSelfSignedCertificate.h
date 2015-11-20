//
//  ARTURLSessionSelfSignedCertificate.h
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARTTypes.h"

@interface ARTURLSessionSelfSignedCertificate : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (void)get:(NSURLRequest *)request completion:(ARTHttpRequestCallback)callback;

@end
