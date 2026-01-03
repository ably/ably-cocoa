#import "ARTRestAnnotations+Private.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTNSString+ARTUtil.h"
#import "ARTChannel+Private.h"
#import "ARTBaseMessage+Private.h"
#import "ARTInternalLog.h"
#import "ARTChannel.h"
#import "ARTDataQuery.h"
#import "ARTAnnotation.h"
#import "ARTOutboundAnnotation.h"
#import "ARTAnnotation+Private.h"
#import "ARTDefault.h"
#import "ARTCrypto+Private.h"
#import "ARTConstants.h"
#import "ARTGCD.h"

@implementation ARTAnnotationsQuery

- (instancetype)init {
    self = [super init];
    if (self) {
        _limit = 100;
    }
    return self;
}

- (instancetype)initWithLimit:(NSUInteger)limit {
    NSAssert(limit > 0, @"Limit should be greater than 0.");
    self = [super init];
    if (self) {
        _limit = limit;
    }
    return self;
}

- (NSStringDictionary *)asQueryParams {
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"limit"] = [NSString stringWithFormat:@"%lu", (unsigned long)self.limit];
    return params;
}

@end

@implementation ARTRestAnnotations {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRestAnnotationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [_internal getForMessage:message query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [_internal getForMessageSerial:messageSerial query:query callback:callback];
}

- (void)publishForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal publishForMessage:message annotation:annotation callback:callback];
}

- (void)publishForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal publishForMessageSerial:messageSerial annotation:annotation callback:callback];
}

- (void)deleteForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal deleteForMessage:message annotation:annotation callback:callback];
}

- (void)deleteForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal deleteForMessageSerial:messageSerial annotation:annotation callback:callback];
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestAnnotationsInternal ()

@property (nonatomic, readonly) ARTInternalLog *logger;

@end

NS_ASSUME_NONNULL_END

@implementation ARTRestAnnotationsInternal {
    __weak ARTRestChannelInternal *_channel; // weak because channel owns self
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
    ARTDataEncoder *_dataEncoder;
}

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _channel = channel;
        _userQueue = channel.rest.userQueue;
        _queue = channel.rest.queue;
        _logger = logger;
        _dataEncoder = _channel.dataEncoder;
    }
    return self;
}

- (void)publishAnnotation:(ARTOutboundAnnotation *)outboundAnnotation
            messageSerial:(NSString *)messageSerial
                   action:(ARTAnnotationAction)action
                 callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    // RSAN1a1: Message object must contain a populated serial field
    if (messageSerial == nil) {
        if (callback) {
            callback([ARTErrorInfo createWithCode:ARTErrorBadRequest message:@"Message serial cannot be nil."]);
        }
        return;
    }
    
    // RSAN1c4: generate annotation identifier if `idempotentRestPublishing` is enabled and id not provided
    NSString *annotationId = outboundAnnotation.id;
    if (!annotationId && _channel.rest.options.idempotentRestPublishing) {
        NSData *baseIdData = [ARTCrypto generateSecureRandomData:ARTIdempotentLibraryGeneratedIdLength];
        annotationId = [NSString stringWithFormat:@"%@:0", [baseIdData base64EncodedStringWithOptions:0]];
    }
    
    // Convert ARTOutboundAnnotation to ARTAnnotation for internal processing
    ARTAnnotation *annotation = [[ARTAnnotation alloc] initWithId:annotationId
                                                           action:action // RSAN1c1
                                                         clientId:outboundAnnotation.clientId
                                                             name:outboundAnnotation.name
                                                            count:outboundAnnotation.count
                                                             data:outboundAnnotation.data
                                                         encoding:nil
                                                        timestamp:nil
                                                           serial:nil
                                                    messageSerial:messageSerial // RSAN1c2
                                                             type:outboundAnnotation.type
                                                           extras:outboundAnnotation.extras];
art_dispatch_async(_queue, ^{
    // RSAN1c3: encode annotation data
    NSError *encodeError = nil;
    ARTAnnotation *annotationToPublish = self->_dataEncoder ? [annotation encodeDataWithEncoder:self->_dataEncoder error:&encodeError] : annotation;
    if (encodeError) {
        if (callback) {
            callback([ARTErrorInfo createFromNSError:encodeError]);
        }
        return;
    }
    
    // Validate the annotation size
    NSInteger annotationSize = [annotationToPublish annotationSize];
    NSInteger maxSize = [ARTDefault maxMessageSize];
    
    if (annotationSize > maxSize) {
        if (callback) {
            callback([ARTErrorInfo createWithCode:ARTErrorMaxMessageLengthExceeded
                                       message:[NSString stringWithFormat:@"Annotation size of %ld bytes exceeds maxMessageSize of %ld bytes", (long)annotationSize, (long)maxSize]]);
        }
        return;
    }
    
    NSData *encodedAnnotation = [self->_channel.rest.defaultEncoder encodeAnnotations:@[annotationToPublish] error:&encodeError];
    if (encodeError) {
        if (callback) {
            callback([ARTErrorInfo createFromNSError:encodeError]);
        }
        return;
    }
    
    // Construct URL for the annotation endpoint
    NSString *path = [NSString stringWithFormat:@"%@/messages/%@/annotations", [self->_channel getBasePath], [messageSerial encodePathSegment]];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_channel.rest buildRequest:@"POST"
                                                                path:path
                                                             baseUrl:nil
                                                              params:nil
                                                                body:encodedAnnotation
                                                             headers:nil
                                                               error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    ARTLogDebug(self->_logger, @"RS:%p CH:%p (%@) publish annotation %@",
                self->_channel.rest, self->_channel, self->_channel.name,
                [[NSString alloc] initWithData:encodedAnnotation encoding:NSUTF8StringEncoding]);
    
    [self->_channel.rest executeAblyRequest:request
                             withAuthOption:ARTAuthenticationOn
                           wrapperSDKAgents:nil
                                 completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (callback) {
            ARTErrorInfo *errorInfo = nil;
            if (error) {
                if (self->_channel.rest.options.addRequestIds) {
                    errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error]
                                           prepend:[NSString stringWithFormat:@"Request '%@' failed with ", request.URL]];
                } else {
                    errorInfo = [ARTErrorInfo createFromNSError:error];
                }
            }
            callback(errorInfo);
        }
    }];
});
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self getForMessageSerial:message.serial query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    if (callback) {
        ARTPaginatedAnnotationsCallback userCallback = callback;
        callback = ^(ARTPaginatedResult<ARTAnnotation *> *result, ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    // RSAN3a: Message object must contain a populated serial field
    if (messageSerial == nil) {
        if (callback) {
            callback(nil, [ARTErrorInfo createWithCode:ARTErrorBadRequest message:@"Message serial cannot be nil."]);
        }
        return;
    }
    
art_dispatch_async(_queue, ^{
    NSString *path = [NSString stringWithFormat:@"%@/messages/%@/annotations", [self->_channel getBasePath], [messageSerial encodePathSegment]];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_channel.rest buildRequest:@"GET"
                                                                path:path
                                                             baseUrl:nil
                                                              params:[query asQueryParams]
                                                                body:nil
                                                             headers:nil
                                                               error:&error];
    if (error) {
        if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    ARTLogDebug(self->_logger, @"RS:%p CH:%p (%@) get annotations request %@",
                self->_channel.rest, self->_channel, self->_channel.name, request);
    
    ARTPaginatedResultResponseProcessor responseProcessor = ^NSArray<ARTAnnotation *> *(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [self->_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeAnnotations:data error:errorPtr] artMap:^(ARTAnnotation *annotation) {
            NSError *decodeError = nil;
            annotation = [annotation decodeDataWithEncoder:self->_channel.dataEncoder error:&decodeError];
            if (decodeError != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason] prepend:@"Failed to decode data: "];
                ARTLogError(self.logger, @"RS:%p C:%p (%@) %@", self->_channel.rest, self->_channel, self->_channel.name, errorInfo.message);
            }
            return annotation;
        }];
    };
    
    [ARTPaginatedResult executePaginated:self->_channel.rest
                             withRequest:request
                    andResponseProcessor:responseProcessor
                        wrapperSDKAgents:nil
                                  logger:self.logger
                                callback:callback];
});
}

- (void)publishForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:message.serial action:ARTAnnotationCreate callback:callback];
}

- (void)publishForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:messageSerial action:ARTAnnotationCreate callback:callback];
}

- (void)deleteForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:message.serial action:ARTAnnotationDelete callback:callback];
}

- (void)deleteForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:messageSerial action:ARTAnnotationDelete callback:callback];
}

@end
