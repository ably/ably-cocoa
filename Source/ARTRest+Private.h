//
//  ARTRest+Private.h
//  ably-ios
//
//  Created by Jason Choy on 21/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest.h"
#import "ARTHttp.h"
#import "ARTRealtime.h"
#import "ARTSentry.h"

@protocol ARTEncoder;
@protocol ARTHTTPExecutor;

ART_ASSUME_NONNULL_BEGIN

/// ARTRest private methods that are used internally and for whitebox testing
@interface ARTRest () <ARTHTTPAuthenticatedExecutor>

@property (nonatomic, strong, readonly) ARTClientOptions *options;
@property (nonatomic, weak, nullable) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) __GENERIC(id, ARTEncoder) defaultEncoder;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readonly, strong, nonatomic) NSDictionary<NSString *, id<ARTEncoder>> *encoders;

// Must be atomic!
@property (readwrite, strong, atomic, art_nullable) NSString *prioritizedHost;

@property (nonatomic, weak) id<ARTHTTPExecutor> httpExecutor;

@property (nonatomic, readonly, getter=getBaseUrl) NSURL *baseUrl;

@property (nonatomic, strong, readonly) ARTLog *logger;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_queue_t userQueue;

// MARK: Not accessible by tests
@property (readonly, strong, nonatomic) ARTHttp *http;
@property (strong, nonatomic) ARTAuth *auth;
@property (readwrite, assign, nonatomic) int fallbackCount;

- (instancetype)initWithOptions:(ARTClientOptions *)options realtime:(ARTRealtime *_Nullable)realtime;
- (void)_time:(void (^)(NSDate *__art_nullable, NSError *__art_nullable))callback;

- (nullable id<ARTCancellable>)internetIsUp:(void (^)(BOOL isUp))cb;

- (void)onUncaughtException:(NSException *)e;
- (void)reportUncaughtException:(NSException *_Nullable)exception;
- (void)forceReport:(NSString *)message exception:(NSException *_Nullable)e;

@end

BOOL ARTstartHandlingUncaughtExceptions(ARTRest *self);
void ARTstopHandlingUncaughtExceptions(ARTRest *self);

#define ART_TRY_OR_REPORT_CRASH_START(rest) \
	do {\
	ARTRest *__rest = rest;\
    BOOL __started = ARTstartHandlingUncaughtExceptions(__rest);\
    BOOL __caught = false;\
	@try {\
		do {\

#define ART_TRY_OR_REPORT_CRASH_END \
		} while(0); \
	}\
	@catch(NSException *e) {\
		__caught = true;\
        if (!__started) {\
            @throw e;\
        }\
		[__rest onUncaughtException:e];\
	}\
	@finally {\
		if (!__caught && __started) {\
            ARTstopHandlingUncaughtExceptions(__rest);\
		}\
	}\
	} while(0);

#define ART_EXITING_ABLY_CODE(rest) ARTstopHandlingUncaughtExceptions(rest);

ART_ASSUME_NONNULL_END
