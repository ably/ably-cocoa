//
//  ARTMsgPackEncoder.m
//  ably
//
//  Created by Toni Cárdenas on 21/3/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTMsgPackEncoder.h"
#import "MessagePack.h"

@implementation ARTMsgPackEncoder

- (NSString *)mimeType {
    return @"application/x-msgpack";
}

- (ARTEncoderFormat)format {
    return ARTEncoderFormatMsgPack;
}

- (NSString *)formatAsString {
    return @"msgpack";
}

- (id)decode:(NSData *)data {
    return [data messagePackParse];
}

- (NSData *)encode:(id)obj {
    return [obj messagePack];
}

@end