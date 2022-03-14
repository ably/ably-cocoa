#import "ARTMessage.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTBaseMessage+Private.h"
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTMessage

- (instancetype)initWithName:(NSString *)name data:(id)data {
    if (self = [self init]) {
        self.name = [name copy];
        if (data) {
            self.data = data;
            self.encoding = @"";
        }
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    if (self = [self initWithName:name data:data]) {
        self.clientId = clientId;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" name: %@\n", self.name];
    if (self.extras) {
        [description appendFormat:@" extras: %@\n", self.extras];
    }
    [description appendFormat:@"}"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [super copyWithZone:zone];
    message.name = self.name;
    message.extras = self.extras;
    return message;
}

- (NSInteger)messageSize {
    // TO3l8*
    return [super messageSize] + [self.name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation ARTMessage (Decryption)

+ (instancetype)fromEncodedJsonObject:(NSDictionary *)input channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher error:error];
    
    ARTMessage *message = [jsonEncoder messageFromDictionary:input];
    message = [message decodeWithEncoder:decoder error:error];
    
    return message;
}

+ (NSArray<ARTMessage *> *)fromEncodedJsonArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher error:error];
    
    NSArray <ARTMessage *> *messagesArray = [jsonEncoder messagesFromArray:jsonArray];
    messagesArray = [messagesArray artMap:^(ARTMessage *message) {
        return [message decodeWithEncoder:decoder error:nil];
    }];
    return messagesArray;
}

@end
