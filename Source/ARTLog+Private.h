//
//  ARTLog+Private.h
//  ably
//
//  Created by Toni Cárdenas on 25/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTLogLine : NSObject

@property(nonatomic, readonly, strong) NSDate *date;
@property(nonatomic, readonly) ARTLogLevel level;
@property(nonatomic, readonly, strong) NSString *message;

- (instancetype)initWithDate:(NSDate *)date level:(ARTLogLevel)level message:(NSString *)message;

- (NSString *)toString;

@end

@interface ARTLog ()

@property (readonly) NSArray<ARTLogLine *> *captured;
@property (readonly) NSArray<ARTLogLine *> *history;

- (instancetype)initCapturingOutput:(BOOL)capturing;
- (instancetype)initCapturingOutput:(BOOL)capturing historyLines:(NSUInteger)historyLines;

@end

NS_ASSUME_NONNULL_END
