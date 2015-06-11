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
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSDate+ARTUtil.h"

/*
#import <msgpack/msgpack.h>
#import <msgpack/NSData+MessagePack.h>
#import <msgpack/NSDictionary+MessagePack.h>
#import <msgpack/NSArray+MessagePack.h>
*/


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



-(id) decodeError:(NSData *) data {
    return nil;
}



- (NSData *)encode:(id)obj
{
    return nil;
}
- (NSString *)mimeType {
    return @"application/msgpack";
}


-(ARTTokenDetails *) decodeAccessToken:(NSData *)data {
    return nil;
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
    //TODO implement
    return nil;
}

- (NSArray *)decodeStats:(NSData *)data {
    return [self statsFromArray:[self decodeArray:data]];
}

- (ARTMessage *)messageFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (NSArray *)messagesFromArray:(NSArray *)input {
    //TODO implement
    return nil;
}



- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}


//TODO dup with json?
- (NSArray *)presenceMessagesFromArray:(NSArray *)input {
    //TODO implement
    return nil;
}

- (NSDictionary *)messageToDictionary:(ARTMessage *)message {
    //TODO implement
    return nil;
}

- (NSArray *)messagesToArray:(NSArray *)messages {
    //TODO implement
    return nil;
}

- (NSDictionary *)presenceMessageToDictionary:(ARTPresenceMessage *)message {
    //TODO implement
    return nil;
}

- (NSArray *)presenceMessagesToArray:(NSArray *)messages {
    //TODO implement
    return nil;
}

- (NSDictionary *)protocolMessageToDictionary:(ARTProtocolMessage *)message {
    //TODO implement
    return nil;
}

- (ARTProtocolMessage *)protocolMessageFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (NSArray *)statsFromArray:(NSArray *)input {
    //TODO implement
    return nil;
}

- (ARTStats *)statsFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (ARTPayload *)payloadFromDictionary:(NSDictionary *)input {
    //TODO implement
    return nil;
}

- (void)writePayload:(ARTPayload *)payload toDictionary:(NSMutableDictionary *) input
{
    //TODO implement
}

- (id)decode:(NSData *)data {
   // id obj = [data messagePackParse];
    return nil;
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
    return nil;//[obj messagePack];
}
-(NSData *) encodeArr:(NSArray *) obj
{
    return nil;// [obj messagePack];
}


@end
