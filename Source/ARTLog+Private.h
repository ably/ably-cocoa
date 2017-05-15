//
//  ARTLog+Private.h
//  ably
//
//  Created by Toni Cárdenas on 25/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTLog_Private_h
#define ARTLog_Private_h

#import "ARTLog.h"
#import "ARTSentry.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTLogLine : NSObject <ARTSentryBreadcrumb>

@property(nonatomic, readonly, strong) NSDate *date;
@property(nonatomic, readonly) ARTLogLevel level;
@property(nonatomic, readonly, strong) NSString *message;
@property(nonatomic, readonly) NSString *breadcrumbsKey;

- (instancetype)initWithDate:(NSDate *)date level:(ARTLogLevel)level message:(NSString *)message breadcrumbsKey:(NSString *)breadcrumbsKey;

- (NSString *)toString;

@end

@interface ARTLog ()

@property (readonly) NSArray<ARTLogLine *> *captured;
@property (readonly) NSArray<ARTLogLine *> *history;
@property (readwrite) NSString *breadcrumbsKey;

- (instancetype)initCapturingOutput:(BOOL)capturing;
- (instancetype)initCapturingOutput:(BOOL)capturing historyLines:(NSUInteger)historyLines;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTLog_Private_h */
