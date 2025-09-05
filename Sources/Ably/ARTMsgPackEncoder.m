#import "ARTMsgPackEncoder.h"
#import <msgpack/MessagePack.h>

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

- (id)decode:(NSData *)data error:(NSError **)error {
    return [data messagePackParse];
}

- (NSData *)encode:(id)obj error:(NSError **)error {
    return [obj messagePack];
}

@end
