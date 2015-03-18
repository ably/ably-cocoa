//
//  ARTJsonEncoder.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTMsgPackEncoder.h"

#import "ARTMessage.h"
#import "ARTPresenceMessage.h"
#import "ARTProtocolMessage.h"
#import "ARTStats.h"
#import "NSDictionary+ARTDictionaryUtil.h"
#import "NSDate+ARTUtil.h"

#import <msgpack/msgpack.h>
#import <msgpack/NSData+MessagePack.h>
#import <msgpack/NSDictionary+MessagePack.h>
#import <msgpack/NSArray+MessagePack.h>



@interface ARTMsgPackEncoder ()

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

@implementation ARTMsgPackEncoder

- (NSString *)mimeType {
    return @"application/msgpack";
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

- (NSDate *)decodeTime:(NSData *)data {
    NSArray *resp = [self decodeArray:data];
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
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTMessage *message = [[ARTMessage alloc] init];
    message.id = [input artString:@"id"];
    message.name = [input artString:@"name"];
    message.clientId = [input artString:@"clientId"];
    message.payload = [self payloadFromDictionary:input];
    message.timestamp = [input artDate:@"timestamp"];
    
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



//TODo this is duplicate from jsonencoder. put somewhere else or rm
- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTPresenceMessage *message = [[ARTPresenceMessage alloc] init];
    message.id = [input artString:@"id"];
    message.clientId = [input artString:@"clientId"];
    message.payload = [self payloadFromDictionary:input];
    message.timestamp = [input artDate:@"timestamp"];
    
    int action = [[input artNumber:@"action"] intValue];
    
    switch (action) {
        case 0:
            message.action = ARTPresenceMessageEnter;
            break;
        case 1:
            message.action = ARTPresenceMessageLeave;
            break;
        case 2:
            message.action = ARTPresenceMessageUpdate;
            break;
        default:
            return nil;
    }
    
    message.memberId = [input artString:@"memberId"];
    
    return message;
}


//TODO dup with json?
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
    
    int action = 0;
    switch (message.action) {
        case ARTPresenceMessageEnter:
            action = 0;
            break;
        case ARTPresenceMessageLeave:
            action = 1;
            break;
        case ARTPresenceMessageUpdate:
            action = 2;
            break;
        default:
            return nil;
    }
    
    [output setObject:[NSNumber numberWithInt:action] forKey:@"action"];
    
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
    output[@"channel"] = message.channel;
    output[@"msgSerial"] = [NSNumber numberWithLongLong:message.msgSerial];
    
    if (message.messages) {
        output[@"messages"] = [self messagesToArray:message.messages];
    }
    
    if (message.presence) {
        output[@"presence"] = [self presenceMessagesToArray:message.presence];
    }
    
    return output;
}

- (ARTProtocolMessage *)protocolMessageFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTProtocolMessage *message = [[ARTProtocolMessage alloc] init];
    message.action = (ARTProtocolMessageAction)[[input artNumber:@"action"] intValue];
    message.count = [[input artNumber:@"count"] intValue];
    // TODO: ERROR, what to do?
    message.channel = [input artString:@"channel"];
    message.channelSerial = [input artString:@"channelSerial"];
    message.connectionId = [input artString:@"connectionId"];
    message.connectionSerial = [[input artNumber:@"connectionSerial"] longLongValue];
    message.id = [input artString:@"id"];
    message.msgSerial = [[input artNumber:@"msgSerial"] longLongValue];
    message.timestamp = [input artDate:@"timestamp"];
    message.messages = [self messagesFromArray:[input objectForKey:@"messages"]];
    message.presence = [self presenceMessagesFromArray:[input objectForKey:@"presence"]];
    
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

- (ARTStats *)statsFromDictionary:(NSDictionary *)input {
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
    
    if (all && inbound && outbound && persisted && connections && channels && apiRequests && tokenRequests) {
        return [[ARTStats alloc] initWithAll:all inbound:inbound outbound:outbound persisted:persisted connections:connections channels:channels apiRequests:apiRequests tokenRequests:tokenRequests];
    }
    
    return nil;
}

- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTStatsMessageCount *all = [self statsMessageCountFromDictionary:[input objectForKey:@"all"]];
    ARTStatsMessageCount *messages = [self statsMessageCountFromDictionary:[input objectForKey:@"messages"]];
    ARTStatsMessageCount *presence = [self statsMessageCountFromDictionary:[input objectForKey:@"presence"]];
    
    if (all && messages && presence) {
        return [[ARTStatsMessageTypes alloc] initWithAll:all messages:messages presence:presence];
    }
    
    return nil;
}

- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSNumber *count = [input objectForKey:@"count"];
    NSNumber *data = [input objectForKey:@"data"];
    
    if ([count isKindOfClass:[NSNumber class]] && [data isKindOfClass:[NSNumber class]]) {
        return [[ARTStatsMessageCount alloc] initWithCount:[count doubleValue] data:[data doubleValue]];
    }
    
    return nil;
}

- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTStatsMessageTypes *all = [self statsMessageTypesFromDictionary:[input objectForKey:@"all"]];
    ARTStatsMessageTypes *realtime = [self statsMessageTypesFromDictionary:[input objectForKey:@"realtime"]];
    ARTStatsMessageTypes *rest = [self statsMessageTypesFromDictionary:[input objectForKey:@"rest"]];
    ARTStatsMessageTypes *push = [self statsMessageTypesFromDictionary:[input objectForKey:@"push"]];
    ARTStatsMessageTypes *httpStream = [self statsMessageTypesFromDictionary:[input objectForKey:@"httpStream"]];
    
    if (all && realtime && rest && push && httpStream) {
        return [[ARTStatsMessageTraffic alloc] initWithAll:all realtime:realtime rest:rest push:push httpStream:httpStream];
    }
    
    return nil;
}

- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ARTStatsResourceCount *all = [self statsResourceCountFromDictionary:[input objectForKey:@"all"]];
    ARTStatsResourceCount *plain = [self statsResourceCountFromDictionary:[input objectForKey:@"plain"]];
    ARTStatsResourceCount *tls = [self statsResourceCountFromDictionary:[input objectForKey:@"tls"]];
    
    if (all && plain && tls) {
        return [[ARTStatsConnectionTypes alloc] initWithAll:all plain:plain tls:tls];
    }
    
    return nil;
}

- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSNumber *opened = [input objectForKey:@"opened"];
    NSNumber *peak = [input objectForKey:@"peak"];
    NSNumber *mean = [input objectForKey:@"mean"];
    NSNumber *min = [input objectForKey:@"min"];
    NSNumber *refused = [input objectForKey:@"refused"];
    
    if ([opened isKindOfClass:[NSNumber class]] &&
        [peak isKindOfClass:[NSNumber class]] &&
        [mean isKindOfClass:[NSNumber class]] &&
        [min isKindOfClass:[NSNumber class]] &&
        [refused isKindOfClass:[NSNumber class]]) {
        return [[ARTStatsResourceCount alloc] initWithOpened:[opened doubleValue] peak:[peak doubleValue] mean:[mean doubleValue] min:[min doubleValue] refused:[refused doubleValue]];
    }
    
    return nil;
}

- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input {
    if (![input isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSNumber *succeeded = [input objectForKey:@"succeeded"];
    NSNumber *failed = [input objectForKey:@"failed"];
    NSNumber *refused = [input objectForKey:@"refused"];
    
    if ([succeeded isKindOfClass:[NSNumber class]] &&
        [failed isKindOfClass:[NSNumber class]] &&
        [refused isKindOfClass:[NSNumber class]]) {
        return [[ARTStatsRequestCount alloc] initWithSucceeded:[succeeded doubleValue] failed:[failed doubleValue] refused:[refused doubleValue]];
    }
    
    return nil;
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
    ARTStatus status = [[ARTBase64PayloadEncoder instance] decode:payload output:&decoded];
    if (status != ARTStatusOk) {
        // TODO log
    }
    return decoded;
}

- (void)writePayload:(ARTPayload *)payload toDictionary:(NSMutableDictionary *)output {
    ARTPayload *encoded = nil;
    ARTStatus status = [[ARTBase64PayloadEncoder instance] encode:payload output:&encoded];
    NSAssert(status == ARTStatusOk, @"Error encoding payload");
    NSAssert([payload.payload isKindOfClass:[NSString class]], @"Only string or data payloads are accepted");
    
    if (encoded.encoding.length) {
        output[@"encoding"] = encoded.encoding;
    }
    
    output[@"data"] = encoded.payload;
}

- (id)decode:(NSData *)data {
    id obj = [data messagePackParse]; //[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    NSLog(@"decoded obj is %@", obj);
    return obj;
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


//TODO write thie up.
//- (NSData *)encode:(id)obj {
//    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
//}

-(NSData *) encodeDict:(NSDictionary *) obj
{
    return [obj messagePack];
}
-(NSData *) encodeArr:(NSArray *) obj
{
    return [obj messagePack];
}


@end
