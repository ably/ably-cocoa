//
//  ARTMsgPackEncoder.h
//  ably
//
//  Created by Toni Cárdenas on 21/3/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTMsgPackEncoder_h
#define ARTMsgPackEncoder_h

#import <Foundation/Foundation.h>
#import "ARTJsonLikeEncoder.h"

@interface ARTMsgPackEncoder : NSObject <ARTJsonLikeEncoderDelegate>

@end

#endif
