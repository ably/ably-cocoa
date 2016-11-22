//
//  ARTJsonLikeEncoder.m
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTJsonLikeEncoder.h"

#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTStats.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTLog.h"
#import "ARTHttp.h"
#import "ARTStatus.h"
#import "ARTTokenDetails.h"
#import "ARTTokenRequest.h"
#import "ARTConnectionDetails.h"
#import "ARTRest+Private.h"

@interface ARTJsonLikeEncoder ()

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

- (NSDictionary *)tokenRequestToDictionary:(ARTTokenRequest *)tokenRequest;

- (NSArray *)statsFromArray:(NSArray *)input;
- (ARTStats *)statsFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input;
- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input;
- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input;

- (void)writeData:(id)data encoding:(NSString *)encoding toDictionary:(NSMutableDictionary *)output;

- (NSDictionary *)decodeDictionary:(NSData *)data;
- (NSArray *)decodeArray:(NSData *)data;

@end

@implementation ARTJsonLikeEncoder {
    ARTLog *_logger;
}

- (instancetype)initWithRest:(ARTRest *)rest delegate:(id<ARTJsonLikeEncoderDelegate>)delegate {
    if (self = [super init]) {
        _rest = rest;
        _logger = rest.logger;
        _delegate = delegate;
    }
    return self;
}

- (NSString *)mimeType {
    return [_delegate mimeType];
}

- (ARTEncoderFormat)format {
    return [_delegate format];
}

- (NSString *)formatAsString {
    return [_delegate formatAsString];
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

- (ARTTokenDetails *)decodeTokenDetails:(NSData *)data error:(NSError * __autoreleasing *)error {
    return [self tokenFromDictionary:[self decodeDictionary:data] error:error];
}

- (ARTTokenRequest *)decodeTokenRequest:(NSData *)data error:(NSError * __autoreleasing *)error {
    return [self tokenRequestFromDictionary:[self decodeDictionary:data] error:error];
}

- (NSData *)encodeTokenRequest:(ARTTokenRequest *)request {
    return [self encode:[self tokenRequestToDictionary:request]];
}

- (NSData *)encodeTokenDetails:(ARTTokenDetails *)tokenDetails {
    return [self encode:[self tokenDetailsToDictionary:tokenDetails]];
}

- (NSDate *)decodeTime:(NSData *)data {
    NSArray *resp = [self decodeArray:data];
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: decodeTime %@", _rest, [_delegate formatAsString], resp];
    if (resp && resp.count == 1) {
        NSNumber *num = resp[0];
        if ([num isKindOfClass:[NSNumber class]]) {
            return [NSDate dateWithTimeIntervalSince1970:([num doubleValue] / 1000.0)];
        }
    }
    return nil;
}

- (NSArray *)decodeStats:(NSData *)data {
    return [self statsFromArray:[self decodeArray:data]];
}

- (ARTMessage *)messageFromDictionary:(NSDictionary *)input {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: messageFromDictionary %@", _rest, [_delegate formatAsString], input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTMessage *message = [[ARTMessage alloc] init];
    message.id = [input artString:@"id"];
    message.name = [input artString:@"name"];
    message.clientId = [input artString:@"clientId"];
    message.data = [input objectForKey:@"data"];
    message.encoding = [input artString:@"encoding"];;
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
    [_logger error:@"RS:%p ARTJsonEncoder invalid ARTPresenceAction %d", _rest, action];
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
    }
}

- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: presenceMessageFromDictionary %@", _rest, [_delegate formatAsString], input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    ARTPresenceMessage *message = [[ARTPresenceMessage alloc] init];
    message.id = [input artString:@"id"];
    message.data = [input objectForKey:@"data"];
    message.encoding = [input artString:@"encoding"];
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
    
    if (message.data) {
        [self writeData:message.data encoding:message.encoding toDictionary:output];
    }
    
    if (message.name) {
        [output setObject:message.name forKey:@"name"];
    }

    if (message.connectionId) {
        [output setObject:message.connectionId forKey:@"connectionId"];
    }

    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: messageToDictionary %@", _rest, [_delegate formatAsString], output];
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
    
    if (message.data) {
        [self writeData:message.data encoding:message.encoding toDictionary:output];
    }
    if(message.connectionId) {
        [output setObject:message.connectionId forKey:@"connectionId"];
    }
    
    int action = [self intFromPresenceMessageAction:message.action];
    
    [output setObject:[NSNumber numberWithInt:action] forKey:@"action"];
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: presenceMessageToDictionary %@", _rest, [_delegate formatAsString], output];
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
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: protocolMessageToDictionary %@", _rest, [_delegate formatAsString], output];
    return output;
}

- (ARTTokenDetails *)tokenFromDictionary:(NSDictionary *)input error:(NSError * __autoreleasing *)error {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: tokenFromDictionary %@", _rest, [_delegate formatAsString], input];
    
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *jsonError = [input artDictionary:@"error"];
    if (jsonError) {
        [_logger error:@"RS:%p ARTJsonLikeEncoder<%@>: tokenFromDictionary error %@", _rest, [_delegate formatAsString], jsonError];
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
    NSNumber *expiresTimeInterval = [input objectForKey:@"expires"];
    NSDate *expires = expiresTimeInterval ? [NSDate dateWithTimeIntervalSince1970:expiresTimeInterval.doubleValue / 1000] : nil;
    NSNumber *issuedInterval = [input objectForKey:@"issued"];
    NSDate *issued = issuedInterval ? [NSDate dateWithTimeIntervalSince1970:issuedInterval.doubleValue / 1000] : nil;
    
    return [[ARTTokenDetails alloc] initWithToken:token
                                              expires:expires
                                               issued:issued
                                           capability:[input artString:@"capability"]
                                             clientId:[input artString:@"clientId"]];
    
}

- (NSDictionary *)tokenRequestToDictionary:(ARTTokenRequest *)tokenRequest {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: tokenRequestToDictionary %@", _rest, [_delegate formatAsString], tokenRequest];

    NSNumber *timestamp;
    if (tokenRequest.timestamp)
        timestamp = [NSNumber numberWithUnsignedLongLong:dateToMilliseconds(tokenRequest.timestamp)];
    else
        timestamp = [NSNumber numberWithUnsignedLongLong:dateToMilliseconds([NSDate date])];

    NSMutableDictionary *dictionary = [@{
             @"keyName":tokenRequest.keyName ? tokenRequest.keyName : @"",
             @"ttl":[NSNumber numberWithUnsignedLongLong: timeIntervalToMilliseconds(tokenRequest.ttl)],
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

- (ARTTokenRequest *)tokenRequestFromDictionary:(NSDictionary *)input error:(NSError * __autoreleasing *)error {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: tokenRequestFromDictionary %@", _rest, [_delegate formatAsString], input];

    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *jsonError = [input artDictionary:@"error"];
    if (jsonError) {
        [_logger error:@"RS:%p ARTJsonLikeEncoder<%@>: tokenRequestFromDictionary error %@", _rest, [_delegate formatAsString], jsonError];
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

    ARTTokenParams *params = [[ARTTokenParams alloc] initWithClientId:[input artString:@"clientId"]
                                                                nonce:[input artString:@"nonce"]];
    params.ttl = millisecondsToTimeInterval([input artInteger:@"ttl"]);
    params.capability = [input artString:@"capability"];
    params.timestamp = [input artDate:@"timestamp"];

    return [[ARTTokenRequest alloc] initWithTokenParams:params
                                                keyName:[input artString:@"keyName"]
                                                  nonce:[input artString:@"nonce"]
                                                    mac:[input artString:@"mac"]];
}

- (NSDictionary *)tokenDetailsToDictionary:(ARTTokenDetails *)tokenDetails {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    dictionary[@"token"] = tokenDetails.token;

    if (tokenDetails.issued) {
        dictionary[@"issued"] = [NSString stringWithFormat:@"%llu", dateToMilliseconds(tokenDetails.issued)];
    }

    if (tokenDetails.expires) {
        dictionary[@"expires"] = [NSString stringWithFormat:@"%llu", dateToMilliseconds(tokenDetails.expires)];
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
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: protocolMessageFromDictionary %@", _rest, [_delegate formatAsString], input];
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
    message.connectionDetails = [self connectionDetailsFromDictionary:[input valueForKey:@"connectionDetails"]];

    NSDictionary *error = [input valueForKey:@"error"];
    if (error) {
        message.error = [ARTErrorInfo createWithCode:[[error artNumber:@"code"] intValue] status:[[error artNumber:@"statusCode"] intValue] message:[error artString:@"message"]];
    }

    return message;
}

- (ARTConnectionDetails *)connectionDetailsFromDictionary:(NSDictionary *)input {
    if (!input) {
        return nil;
    }

   return [[ARTConnectionDetails alloc] initWithClientId:[input artString:@"clientId"]
                                           connectionKey:[input artString:@"connectionKey"]
                                          maxMessageSize:[input artInteger:@"maxMessageSize"]
                                            maxFrameSize:[input artInteger:@"maxFrameSize"]
                                          maxInboundRate:[input artInteger:@"maxInboundRate"]
                                      connectionStateTtl:(NSTimeInterval)[input artInteger:@"connectionStateTtl"]
                                                serverId:[input artString:@"serverId"]];
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

- (ARTStats *)statsFromDictionary:(NSDictionary *)input {
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: statsFromDictionary %@", _rest, [_delegate formatAsString], input];
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return [[ARTStats alloc] initWithAll:[self statsMessageTypesFromDictionary:[input objectForKey:@"all"]]
                                 inbound:[self statsMessageTrafficFromDictionary:[input objectForKey:@"inbound"]]
                                outbound:[self statsMessageTrafficFromDictionary:[input objectForKey:@"outbound"]]
                               persisted:[self statsMessageTypesFromDictionary:[input objectForKey:@"persisted"]]
                             connections:[self statsConnectionTypesFromDictionary:[input objectForKey:@"connections"]]
                                channels:[self statsResourceCountFromDictionary:[input objectForKey:@"channels"]]
                             apiRequests:[self statsRequestCountFromDictionary:[input objectForKey:@"apiRequests"]]
                           tokenRequests:[self statsRequestCountFromDictionary:[input objectForKey:@"tokenRequests"]]
                                intervalId:input[@"intervalId"]];
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
    ARTStatsMessageTypes *webhook = [self statsMessageTypesFromDictionary:[input objectForKey:@"webhook"]];
    
    if (all || realtime || rest || webhook) {
        return [[ARTStatsMessageTraffic alloc] initWithAll:all
                                                  realtime:realtime
                                                      rest:rest
                                                   webhook:webhook];
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
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@>: statsRequestCountFromDictionary %@", _rest, [_delegate formatAsString], input];
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

- (void)writeData:(id)data encoding:(NSString *)encoding toDictionary:(NSMutableDictionary *)output {
    if (encoding.length) {
        output[@"encoding"] = encoding;
    }
    output[@"data"] = data;
}

- (id)decode:(NSData *)data {
    id decoded = [_delegate decode:data];
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@> decoding '%@'; got: %@", _rest, [_delegate formatAsString], data, decoded];
    return decoded;
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
    NSData *encoded = [_delegate encode:obj]; 
    [_logger verbose:@"RS:%p ARTJsonLikeEncoder<%@> encoding '%@'; got: %@", _rest, [_delegate formatAsString], obj, encoded];
    return encoded;
}

@end

