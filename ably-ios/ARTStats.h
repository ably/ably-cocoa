//
//  ARTStats.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARTQueryDirection) {
    ARTQueryDirectionForwards,
    ARTQueryDirectionBackwards
};

typedef NS_ENUM(NSUInteger, ARTStatsUnit) {
    ARTStatsUnitMinute,
    ARTStatsUnitHour,
    ARTStatsUnitDay,
    ARTStatsUnitMonth
};

@interface ARTStatsQuery : NSObject

@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSDate *end;

@property (nonatomic, assign) uint64_t limit;

@property (nonatomic, assign) ARTQueryDirection direction;

@property (nonatomic, assign) ARTStatsUnit unit;

- (NSArray *)asQueryItems;

@end

@interface ARTStatsMessageCount : NSObject

@property (readonly, assign, nonatomic) double count;
@property (readonly, assign, nonatomic) double data;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCount:(double)count data:(double)data;

@end

@interface ARTStatsMessageTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageCount *all;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *messages;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *presence;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(ARTStatsMessageCount *)all messages:(ARTStatsMessageCount *)messages presence:(ARTStatsMessageCount *)presence;

@end

@interface ARTStatsMessageTraffic : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *realtime;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *rest;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *push;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *httpStream;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(ARTStatsMessageTypes *)all realtime:(ARTStatsMessageTypes *)realtime rest:(ARTStatsMessageTypes *)rest push:(ARTStatsMessageTypes *)push httpStream:(ARTStatsMessageTypes *)httpStream;

@end

@interface ARTStatsResourceCount : NSObject

@property (readonly, assign, nonatomic) double opened;
@property (readonly, assign, nonatomic) double peak;
@property (readonly, assign, nonatomic) double mean;
@property (readonly, assign, nonatomic) double min;
@property (readonly, assign, nonatomic) double refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOpened:(double)opened peak:(double)peak mean:(double)mean min:(double)min refused:(double)refused;

@end

@interface ARTStatsConnectionTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsResourceCount *all;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *plain;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *tls;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(ARTStatsResourceCount *)all plain:(ARTStatsResourceCount *)plain tls:(ARTStatsResourceCount *)tls;

@end

@interface ARTStatsRequestCount : NSObject

@property (readonly, assign, nonatomic) double succeeded;
@property (readonly, assign, nonatomic) double failed;
@property (readonly, assign, nonatomic) double refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithSucceeded:(double)succeeded failed:(double)failed refused:(double)refused;

@end

@interface ARTStats : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *inbound;
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *outbound;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *persisted;
@property (readonly, strong, nonatomic) ARTStatsConnectionTypes *connections;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *channels;
@property (readonly, strong, nonatomic) ARTStatsRequestCount *apiRequests;
@property (readonly, strong, nonatomic) ARTStatsRequestCount *tokenRequests;
@property (readonly, strong, nonatomic) NSDate *interval;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(ARTStatsMessageTypes *)all inbound:(ARTStatsMessageTraffic *)inbound outbound:(ARTStatsMessageTraffic *)outbound persisted:(ARTStatsMessageTypes *)persisted connections:(ARTStatsConnectionTypes *)connections channels:(ARTStatsResourceCount *)channels apiRequests:(ARTStatsRequestCount *)apiRequests tokenRequests:(ARTStatsRequestCount *)tokenRequests interval:(NSDate *)interval;

@end
