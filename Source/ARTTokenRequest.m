#import "ARTTokenRequest.h"
#import "ARTTokenParams.h"
#import "ARTAuth+Private.h"
#import "ARTDefault.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"

@implementation ARTTokenRequest

- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac {
    if (self = [super init]) {
        self.ttl = tokenParams.ttl;
        self.capability = tokenParams.capability;
        self.clientId = tokenParams.clientId;
        self.timestamp = tokenParams.timestamp;
        _keyName = [keyName copy];
        _nonce = [nonce copy];
        _mac = [mac copy];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTTokenRequest: keyName=%@ clientId=%@ nonce=%@ mac=%@ ttl=%@ capability=%@ timestamp=%@",
            self.keyName, self.clientId, self.nonce, self.mac, self.ttl, self.capability, self.timestamp];
}

+ (ARTTokenRequest *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error {
    NSError *e = nil;
    NSDictionary *dict = [json toJSON:&e];
    if (e) {
        if (error) {
            *error = e;
        }
        return nil;
    }

    ARTTokenParams *tokenParams = [[ARTTokenParams alloc] initWithClientId:[dict artString:@"clientId"]];

    ARTTokenRequest *tokenRequest = [[ARTTokenRequest alloc] initWithTokenParams:tokenParams
                                                                         keyName:[dict artString:@"keyName"]
                                                                           nonce:[dict artString:@"nonce"]
                                                                             mac:[dict artString:@"mac"]];
    tokenRequest.clientId = [dict artString:@"clientId"];
    tokenRequest.capability = [dict artString:@"capability"];
    tokenRequest.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dict artNumber:@"timestamp"] doubleValue] / 1000];

    NSNumber *ttlNumber = [dict artNumber:@"ttl"];
    tokenRequest.ttl = ttlNumber != nil ? [NSNumber numberWithDouble:millisecondsToTimeInterval([ttlNumber unsignedLongLongValue])] : nil;
    
    return tokenRequest;
}

@end

@implementation ARTTokenRequest (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    [auth internalAsync:^(ARTAuthInternal *auth) {
        [auth executeTokenRequest:self callback:callback];
    }];
}

@end
