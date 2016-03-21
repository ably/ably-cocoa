//
//  ARTJsonLikeEncoder.h
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTJsonLikeEncoder_h
#define ARTJsonLikeEncoder_h

#import "CompatibilityMacros.h"
#import "ARTLog.h"
#import "ARTEncoder.h"

ART_ASSUME_NONNULL_BEGIN

@protocol ARTJsonLikeEncoderDelegate <NSObject>

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (id)decode:(NSData *)data;
- (NSData *)encode:(id)obj;

@end

@interface ARTJsonLikeEncoder : NSObject <ARTEncoder>

@property (nonatomic, weak) ARTLog *logger;
@property (nonatomic, strong, art_nullable) id<ARTJsonLikeEncoderDelegate> delegate;

- (instancetype)initWithLogger:(ARTLog *)logger delegate:(id<ARTJsonLikeEncoderDelegate> __art_nullable)delegate;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTJsonLikeEncoder_h */
