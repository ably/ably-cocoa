//
//  ARTJsonEncoder.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTJsonEncoder.h"

#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTProtocolMessage.h"
#import "ARTStats.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTLog.h"
#import "ARTHttp.h"
#import "ARTStatus.h"
#import "ARTAuthTokenDetails.h"
#import "ARTAuthTokenRequest.h"

@interface ARTJsonEncoder ()

- (ARTMessage *)messageFromDictionary:(NSDictionary *)input;
- (NSArray *)messagesFromArray:(NSArray *)input;

- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input;
- (NSArray *)presenceMessagesFromArray:(NSArray *)input;

- (NSDictionary *)messageToDictionary:(ARTMessage *)message;
- (NSArray *)messagesToArray:(NSArray *)messages;

- (NSDictionary *)presenceMessageToDictionary:(ARTPresenceMessage *)message;
- (NSArray *)presenceMessagesToArray:(NSArray *)messages;

- (NSDictionary *)protocolMessageToDictionary:(ARTProtocolMessage *)message;
- (ARTProtocolMessage *)protocolMessageFromDictionary:(NSDictionary *)input;

- (NSDictionary *)tokenRequestToDictionary:(ARTAuthTokenRequest *)tokenRequest;

- (NSArray *)statsFromArray:(NSArray *)input;
- (ARTStats *)statsFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input;
- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input;
- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input;

- (ARTPayload *)payloadFromDictionary:(NSDictionary *)input;
- (void)writePayload:(ARTPayload *)payload toDictionary:(NSMutableDictionary *)output;

- (id)decode:(NSData *)data;
- (NSDictionary *)decodeDictionary:(NSData *)data;
- (NSArray *)decodeArray:(NSData *)data;

- (NSData *)encode:(id)obj;

@end

@implementation ARTJsonEncoder

- (instancetype)initWithLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _logger = logger;
    }
    return self;
}

- (NSString *)mimeType {
    return @"application/json";
}

- (ARTEncoderFormat)format {
    return ARTEncoderFormatJson;
}

- (NSString *)formatAsString {
    return @"json";
}

- (ARTMessage *)decodeMessage:(NSData *)data {
    return [self messageFromDictionary:[self decodeDictionary:data]];
}

- (NSArray *)decodeMessages:(NSData *)data {
    return [self messagesFromArray:[self decodeArray:data]];
}

- (NSData *)encodeMessage:(ARTMessage *)message {
    return [self encode:[self messageToDictionary:message]];
}

- (NSData *)encodeMessages:(NSArray *)messages {
    return [self encode:[self messagesToArray:messages]];
}

- (ARTPresenceMessage *)decodePresenceMessage:(NSData *)data {
    return [self presenceMessageFromDictionary:[self decodeDictionary:data]];
}

- (NSArray *)decodePresenceMessages:(NSData *)data {
    return [self presenceMessagesFromArray:[self decodeArray:data]];
}

- (NSData *)encodePresenceMessage:(ARTPresenceMessage *)message {
    return [self encode:[self presenceMessageToDictionary:message]];
}

- (NSData *)encodePresenceMessages:(NSArray *)messages {
    return [self encode:[self presenceMessagesToArray:messages]];
}

- (NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message {
    return [self encode:[self protocolMessageToDictionary:message]];
}

- (ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data {
    return [self protocolMessageFromDictionary:[self decodeDictionary:data]];
}

- (ARTAuthTokenDetails *)decodeAccessToken:(NSData *)data error:(NSError * __autoreleasing *)error {
    return [self tokenFromDictionary:[self decodeDictionary:data] error:error];
}

- (NSData *)encodeTokenRequest:(ARTAuthTokenRequest *)request {
    return [self encode:[self tokenRequestToDictionary:request]];
}

- (NSData *)encodeTokenDetails:(ARTAuthTokenDetails *)tokenDetails {
    return [self encode:[self tokenDetailsToDictionary:tokenDetails]];
}

- (NSDate *)decodeTime:(NSData *)data {
    NSArray *resp = [self decodeArray:data];
    [self.logger verbose:@"ARTJsonEncoder: decodeTime %@", resp];
    if (resp && resp.count == 1) {
        NSNumber *num = resp[0];
        if ([num isKindOfClass:[NSNumber class]]) {
            long long msSince1970 = [num longLongValue];
            return [NSDate dateWithTimeIntervalSince1970:(msSince1970 / 1000.0)];
        }
    }
    return nil;
}

- (NSArray *)decodeStats:(NSData *)data {
    return [self statsFromArray:[self decodeArray:data]];
}

- (ARTMessage *)messageFromDictionary:(NSDictionary *)input {
    [self.logger verbose:@"ARTJsonEncoder: messageFromDictionary %@", input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTMessage *message = [[ARTMessage alloc] init];
    message.id = [input artString:@"id"];
    message.name = [input artString:@"name"];
    message.clientId = [input artString:@"clientId"];
    message.payload = [self payloadFromDictionary:input];
    message.timestamp = [input artDate:@"timestamp"];
    message.connectionId = [input artString:@"connectionId"];
    
    return message;
}

- (NSArray *)messagesFromArray:(NSArray *)input {
    if (![input isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *output = [NSMutableArray array];
    for (NSDictionary *item in input) {
        ARTMessage *message = [self messageFromDictionary:item];
        if (!message) {
            return nil;
        }
        [output addObject:message];
    }
    return output;
}

- (ARTPresenceAction)presenceActionFromInt:(int) action
{
    switch (action) {
        case 0:
            return ARTPresenceAbsent;
        case 1:
            return ARTPresencePresent;
        case 2:
            return ARTPresenceEnter;
        case 3:
            return ARTPresenceLeave;
        case 4:
            return ARTPresenceUpdate;
    }
    [self.logger error:@"ARTJsonEncoder invalid ARTPresenceAction %d", action];
    return ARTPresenceAbsent;
    
}

- (int)intFromPresenceMessageAction:(ARTPresenceAction) action
{
    switch (action) {
        case ARTPresenceAbsent:
            return 0;
        case ARTPresencePresent:
            return 1;
        case ARTPresenceEnter:
            return 2;
        case ARTPresenceLeave:
            return 3;
        case ARTPresenceUpdate:
            return 4;
        case ARTPresenceLast:
            return 5;
    }
}

- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input {
    [self.logger verbose:@"ARTJsonEncoder: presenceMessageFromDictionary %@", input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    ARTPresenceMessage *message = [[ARTPresenceMessage alloc] init];
    message.id = [input artString:@"id"];
    message.payload = [self payloadFromDictionary:input];
    message.payload.encoding = [input artString:@"encoding"];
    message.clientId = [input artString:@"clientId"];
    message.timestamp = [input artDate:@"timestamp"];
    
    int action = [[input artNumber:@"action"] intValue];
    
    message.action = [self presenceActionFromInt:action];
    
    message.connectionId = [input artString:@"connectionId"];
    
    return message;
}

- (NSArray *)presenceMessagesFromArray:(NSArray *)input {
    if (![input isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *output = [NSMutableArray array];
    for (NSDictionary *item in input) {
        ARTPresenceMessage *message = [self presenceMessageFromDictionary:item];
        if (!message) {
            return nil;
        }
        [output addObject:message];
    }
    return output;
}

- (NSDictionary *)messageToDictionary:(ARTMessage *)message {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    
    if (message.timestamp) {
        [output setObject:[message.timestamp artToNumberMs] forKey:@"timestamp"];
    }
    
    if (message.clientId) {
        [output setObject:message.clientId forKey:@"clientId"];
    }
    
    if (message.payload) {
        [self writePayload:message.payload toDictionary:output];
    }
    
    if (message.name) {
        [output setObject:message.name forKey:@"name"];
    }
    [self.logger verbose:@"ARTJsonEncoder: messageToDictionary %@", output];
    return output;
}

- (NSArray *)messagesToArray:(NSArray *)messages {
    NSMutableArray *output = [NSMutableArray array];
    
    for (ARTMessage *message in messages) {
        NSDictionary *item = [self messageToDictionary:message];
        if (!(item)) {
            return nil;
        }
        [output addObject:item];
    }
    
    return output;
}

- (NSDictionary *)presenceMessageToDictionary:(ARTPresenceMessage *)message {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    
    if (message.timestamp) {
        [output setObject:[message.timestamp artToNumberMs] forKey:@"timestamp"];
    }
    
    if (message.clientId) {
        [output setObject:message.clientId forKey:@"clientId"];
    }
    
    if (message.payload) {
        [self writePayload:message.payload toDictionary:output];
    }
    if(message.connectionId) {
        [output setObject:message.connectionId forKey:@"connectionId"];
    }
    
    int action = [self intFromPresenceMessageAction:message.action];
    
    [output setObject:[NSNumber numberWithInt:action] forKey:@"action"];
    [self.logger verbose:@"ARTJsonEncoder: presenceMessageToDictionary %@", output];
    return output;
}

- (NSArray *)presenceMessagesToArray:(NSArray *)messages {
    NSMutableArray *output = [NSMutableArray array];
    
    for (ARTPresenceMessage *message in messages) {
        NSDictionary *item = [self presenceMessageToDictionary:message];
        if (!(item)) {
            return nil;
        }
        [output addObject:item];
    }
    return output;
}

- (NSDictionary *)protocolMessageToDictionary:(ARTProtocolMessage *)message {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    output[@"action"] = [NSNumber numberWithInt:message.action];
    if(message.channel) {
        output[@"channel"] = message.channel;
    }
    output[@"msgSerial"] = [NSNumber numberWithLongLong:message.msgSerial];
    
    if (message.messages) {
        output[@"messages"] = [self messagesToArray:message.messages];
    }
    
    if (message.presence) {
        output[@"presence"] = [self presenceMessagesToArray:message.presence];
    }
    [self.logger verbose:@"ARTJsonEncoder: protocolMessageToDictionary %@", output];
    return output;
}

- (ARTAuthTokenDetails *)tokenFromDictionary:(NSDictionary *)input error:(NSError * __autoreleasing *)error {
    [self.logger verbose:@"ARTJsonEncoder: tokenFromDictionary %@", input];
    
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *jsonError = [input artDictionary:@"error"];
    if (jsonError) {
        [self.logger error:@"ARTJsonEncoder: tokenFromDictionary error %@", jsonError];
        if (error) {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:[jsonError artString:@"message"] forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:ARTAblyErrorDomain
                                         code:[jsonError artNumber:@"code"].integerValue
                                     userInfo:details];
        }
        return nil;
    }
    error = nil;
    
    NSString *token = [input artString:@"token"];
    NSNumber *expiresTimeInterval = [input artNumber:@"expires"];
    NSDate *expires = expiresTimeInterval ? [NSDate dateWithTimeIntervalSince1970:expiresTimeInterval.longLongValue / 1000] : nil;
    NSNumber *issuedInterval = [input artNumber:@"issued"];
    NSDate *issued = issuedInterval ? [NSDate dateWithTimeIntervalSince1970:issuedInterval.longLongValue / 1000] : nil;
    
    return [[ARTAuthTokenDetails alloc] initWithToken:token
                                              expires:expires
                                               issued:issued
                                           capability:[input artString:@"capability"]
                                             clientId:[input artString:@"clientId"]];
    
}

- (NSDictionary *)tokenRequestToDictionary:(ARTAuthTokenRequest *)tokenRequest {
    [self.logger verbose:@"ARTJsonEncoder: tokenRequestToDictionary %@", tokenRequest];

    NSNumber *timestamp;
    if (tokenRequest.timestamp)
        timestamp = [NSNumber numberWithUnsignedLongLong:dateToMiliseconds(tokenRequest.timestamp)];
    else
        timestamp = [NSNumber numberWithUnsignedLongLong:dateToMiliseconds([NSDate date])];

    NSMutableDictionary *dictionary = [@{
             @"keyName":tokenRequest.keyName ? tokenRequest.keyName : @"",
             @"ttl":[NSNumber numberWithUnsignedLongLong: timeIntervalToMiliseconds(tokenRequest.ttl)],
             @"capability":tokenRequest.capability ? tokenRequest.capability : @"",
             @"timestamp":timestamp,
             @"nonce":tokenRequest.nonce ? tokenRequest.nonce : @"",
             @"mac":tokenRequest.mac ? tokenRequest.mac : @""
        } mutableCopy];

    if (tokenRequest.clientId) {
        dictionary[@"clientId"] = tokenRequest.clientId;
    }

    return dictionary;
}

- (NSDictionary *)tokenDetailsToDictionary:(ARTAuthTokenDetails *)tokenDetails {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    dictionary[@"token"] = tokenDetails.token;

    if (tokenDetails.issued) {
        dictionary[@"issued"] = [NSString stringWithFormat:@"%llu", dateToMiliseconds(tokenDetails.issued)];
    }

    if (tokenDetails.expires) {
        dictionary[@"expires"] = [NSString stringWithFormat:@"%llu", dateToMiliseconds(tokenDetails.expires)];
    }

    if (tokenDetails.capability) {
        dictionary[@"capability"] = tokenDetails.capability;
    }

    if (tokenDetails.clientId) {
        dictionary[@"clientId"] = tokenDetails.clientId;
    }
    
    return dictionary;
}

- (ARTProtocolMessage *)protocolMessageFromDictionary:(NSDictionary *)input {
    [self.logger verbose:@"ARTJsonEncoder: protocolMessageFromDictionary %@", input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTProtocolMessage *message = [[ARTProtocolMessage alloc] init];
    message.action = (ARTProtocolMessageAction)[[input artNumber:@"action"] intValue];
    message.count = [[input artNumber:@"count"] intValue];
    message.channel = [input artString:@"channel"];
    message.channelSerial = [input artString:@"channelSerial"];
    message.connectionId = [input artString:@"connectionId"];
    NSNumber * serial =  [input artNumber:@"connectionSerial"];
    if (serial) {
        message.connectionSerial = [serial longLongValue];
    }
    message.id = [input artString:@"id"];
    message.msgSerial = [[input artNumber:@"msgSerial"] longLongValue];
    message.timestamp = [input artDate:@"timestamp"];
    message.messages = [self messagesFromArray:[input objectForKey:@"messages"]];
    message.presence = [self presenceMessagesFromArray:[input objectForKey:@"presence"]];
    message.connectionKey = [input artString:@"connectionKey"];
    message.flags = [[input artNumber:@"flags"] longLongValue];

    NSDictionary *connectionDetails = [input valueForKey:@"connectionDetails"];
    if (connectionDetails) {
        message.clientId = [connectionDetails artString:@"clientId"];
    }

    NSDictionary *error = [input valueForKey:@"error"];
    if (error) {
        message.error = [[ARTErrorInfo alloc] init];
        [message.error setCode:[[error artNumber:@"code"] intValue] status:[[error artNumber:@"statusCode"] intValue] message:[error artString:@"message"]];
    }

    return message;
}

- (NSArray *)statsFromArray:(NSArray *)input {
    if (![input isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *output = [NSMutableArray array];
    
    for (NSDictionary *item in input) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        ARTStats *statsItem = [self statsFromDictionary:item];
        if (!statsItem) {
            return nil;
        }
        [output addObject:statsItem];
    }
    
    return output;
}

- (NSDate *)intervalFromString:(NSString *)string {
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd:HH:mm";
        formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    
    return [formatter dateFromString:string];
}

- (ARTStats *)statsFromDictionary:(NSDictionary *)input {
    [self.logger verbose:@"ARTJsonEncoder: statsFromDictionary %@", input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    ARTStatsMessageTypes *all = [self statsMessageTypesFromDictionary:[input objectForKey:@"all"]];
    ARTStatsMessageTraffic *inbound = [self statsMessageTrafficFromDictionary:[input objectForKey:@"inbound"]];
    ARTStatsMessageTraffic *outbound = [self statsMessageTrafficFromDictionary:[input objectForKey:@"outbound"]];
    ARTStatsMessageTypes *persisted = [self statsMessageTypesFromDictionary:[input objectForKey:@"persisted"]];
    ARTStatsConnectionTypes *connections = [self statsConnectionTypesFromDictionary:[input objectForKey:@"connections"]];
    ARTStatsResourceCount *channels = [self statsResourceCountFromDictionary:[input objectForKey:@"channels"]];
    ARTStatsRequestCount *apiRequests = [self statsRequestCountFromDictionary:[input objectForKey:@"apiRequests"]];
    ARTStatsRequestCount *tokenRequests = [self statsRequestCountFromDictionary:[input objectForKey:@"tokenRequests"]];
    NSDate *interval = [self intervalFromString:input[@"intervalId"]];
    
    return [[ARTStats alloc] initWithAll:all
                                 inbound:inbound
                                outbound:outbound
                               persisted:persisted
                             connections:connections
                                channels:channels
                             apiRequests:apiRequests
                           tokenRequests:tokenRequests
                                interval:interval];
}

- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsMessageTypes empty];
    }
    
    ARTStatsMessageCount *all = [self statsMessageCountFromDictionary:[input objectForKey:@"all"]];
    ARTStatsMessageCount *messages = [self statsMessageCountFromDictionary:[input objectForKey:@"messages"]];
    ARTStatsMessageCount *presence = [self statsMessageCountFromDictionary:[input objectForKey:@"presence"]];
    
    if (all || messages || presence) {
        return [[ARTStatsMessageTypes alloc] initWithAll:all messages:messages presence:presence];
    }
    
    return [ARTStatsMessageTypes empty];
}

- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsMessageCount empty];
    }
    
    NSNumber *count = [input artTyped:[NSNumber class] key:@"count"];
    NSNumber *data = [input artTyped:[NSNumber class] key:@"data"];
    
    return [[ARTStatsMessageCount alloc] initWithCount:count.doubleValue data:data.doubleValue];
}

- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsMessageTraffic empty];
    }
    
    ARTStatsMessageTypes *all = [self statsMessageTypesFromDictionary:[input objectForKey:@"all"]];
    ARTStatsMessageTypes *realtime = [self statsMessageTypesFromDictionary:[input objectForKey:@"realtime"]];
    ARTStatsMessageTypes *rest = [self statsMessageTypesFromDictionary:[input objectForKey:@"rest"]];
    ARTStatsMessageTypes *push = [self statsMessageTypesFromDictionary:[input objectForKey:@"push"]];
    ARTStatsMessageTypes *httpStream = [self statsMessageTypesFromDictionary:[input objectForKey:@"httpStream"]];
    
    if (all || realtime || rest || push || httpStream) {
        return [[ARTStatsMessageTraffic alloc] initWithAll:all realtime:realtime rest:rest push:push httpStream:httpStream];
    }
    
    return [ARTStatsMessageTraffic empty];
}

- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsConnectionTypes empty];
    }
    
    ARTStatsResourceCount *all = [self statsResourceCountFromDictionary:[input objectForKey:@"all"]];
    ARTStatsResourceCount *plain = [self statsResourceCountFromDictionary:[input objectForKey:@"plain"]];
    ARTStatsResourceCount *tls = [self statsResourceCountFromDictionary:[input objectForKey:@"tls"]];
    
    if (all || plain || tls) {
        return [[ARTStatsConnectionTypes alloc] initWithAll:all plain:plain tls:tls];
    }
    
    return [ARTStatsConnectionTypes empty];
}

- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsResourceCount empty];
    }
    
    NSNumber *opened = [input artTyped:[NSNumber class] key:@"opened"];
    NSNumber *peak = [input artTyped:[NSNumber class] key:@"peak"];
    NSNumber *mean = [input artTyped:[NSNumber class] key:@"mean"];
    NSNumber *min = [input artTyped:[NSNumber class] key:@"min"];
    NSNumber *refused = [input artTyped:[NSNumber class] key:@"refused"];
    
    return [[ARTStatsResourceCount alloc] initWithOpened:opened.doubleValue
                                                    peak:peak.doubleValue
                                                    mean:mean.doubleValue
                                                     min:min.doubleValue
                                                 refused:refused.doubleValue];
}

- (NSError *)decodeError:(NSData *)error {
    NSDictionary *decodedError = [[self decodeDictionary:error] valueForKey:@"error"];
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: @"",
                               NSLocalizedFailureReasonErrorKey: decodedError[@"message"],
                               @"ARTErrorStatusCode": decodedError[@"statusCode"]
                               };
    return [NSError errorWithDomain:ARTAblyErrorDomain code:[decodedError[@"code"] intValue] userInfo:userInfo];
}

- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input {
    [self.logger verbose:@"ARTJsonEncoder: statsRequestCountFromDictionary %@", input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return [ARTStatsRequestCount empty];
    }
    
    NSNumber *succeeded = [input artTyped:[NSNumber class] key:@"succeeded"];
    NSNumber *failed = [input artTyped:[NSNumber class] key:@"failed"];
    NSNumber *refused = [input artTyped:[NSNumber class] key:@"refused"];
    
    return [[ARTStatsRequestCount alloc] initWithSucceeded:succeeded.doubleValue
                                                    failed:failed.doubleValue
                                                   refused:refused.doubleValue];
}

- (ARTPayload *)payloadFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *encoding = [input objectForKey:@"encoding"];
    if (!encoding) {
        encoding = @"";
    }
    id data = [input objectForKey:@"data"];
    ARTPayload *payload = [ARTPayload payloadWithPayload:data encoding:encoding];
    ARTPayload *decoded = nil;
    ARTStatus *status = [[ARTBase64PayloadEncoder instance] decode:payload output:&decoded];
    if (status.state != ARTStateOk) {
        [self.logger error:@"ARTJsonEncoder failed to decode payload %@", payload];
    }
    return decoded;
}

- (void)writePayload:(ARTPayload *)payload toDictionary:(NSMutableDictionary *)output {
    ARTPayload *encoded = nil;
    ARTStatus *status = [[ARTBase64PayloadEncoder instance] encode:payload output:&encoded];
    if(status.state != ARTStateOk) {
        [self.logger error:@"ARTJsonEncoder failed to encode payload"];
    }
    NSAssert(status.state == ARTStateOk, @"Error encoding payload");
    
    if (encoded.encoding.length) {
        output[@"encoding"] = encoded.encoding;
    }
    output[@"data"] = encoded.payload;
}

- (id)decode:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSDictionary *)decodeDictionary:(NSData *)data {
    id obj = [self decode:data];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return obj;
}

- (NSArray *)decodeArray:(NSData *)data {
    id obj = [self decode:data];
    if (![obj isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return obj;
}

- (NSData *)encode:(id)obj {
    [self.logger verbose:@"ARTJsonEncoder encoding '%@'", obj];
    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
}

@end
