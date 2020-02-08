//
//  ARTVCDiffDecoder.h
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTVCDiffDecoder
- (nullable NSData *)decode:(NSData *)delta base:(NSData *)base error:(NSError *__autoreleasing _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
