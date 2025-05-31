#import "ARTRestAnnotations+Private.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTChannel+Private.h"
#import "ARTBaseMessage+Private.h"
#import "ARTInternalLog.h"

#import "ARTChannel.h"
#import "ARTDataQuery.h"

@implementation ARTAnnotationsQuery

- (instancetype)init {
    return [self initWithClientId:nil connectionId:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    return [self initWithLimit:100 clientId:clientId connectionId:connectionId];
}

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super init];
    if (self) {
        _limit = limit;
        _clientId = clientId;
        _connectionId = connectionId;
    }
    return self;
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    if (self.clientId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    }
    if (self.connectionId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"connectionId" value:self.connectionId]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%lu", (unsigned long)self.limit]]];

    return items;
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

- (void)publish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback {
    [_internal publish:annotation callback:callback];
}

- (void)unpublish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback {
    [_internal unpublish:annotation callback:callback];
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
}

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _channel = channel;
        _userQueue = channel.rest.userQueue;
        _queue = channel.rest.queue;
        _logger = logger;
    }
    return self;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self getForMessageSerial:message.serial query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    if (callback) {
        ARTPaginatedAnnotationsCallback userCallback = callback;
        callback = ^(ARTPaginatedResult<ARTAnnotation *> *m, ARTErrorInfo *e) {
            dispatch_async(self->_userQueue, ^{
                userCallback(m, e);
            });
        };
    }

    if (query.limit > 1000) {
        ARTErrorInfo *error = [ARTErrorInfo errorWithDomain:ARTAblyErrorDomain
                                                       code:ARTDataQueryErrorLimit
                                                   userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        callback(nil, error);
    }

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel.basePath stringByAppendingPathComponent:@"presence"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [self->_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodePresenceMessages:data error:errorPtr] artMap:^(ARTPresenceMessage *message) {
            // FIXME: This should be refactored to be done by ART{Json,...}Encoder.
            // The ART{Json,...}Encoder should take a ARTDataEncoder and use it every
            // time it is enc/decoding a message. This also applies for REST and Realtime
            // ARTMessages.
            message = [message decodeWithEncoder:self->_channel.dataEncoder error:nil];
            return message;
        }];
    };

dispatch_async(_queue, ^{
    [ARTPaginatedResult executePaginated:self->_channel.rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:nil logger:self->_logger callback:callback];
});
}

- (void)publish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback {
    // TODO: implement
}

- (void)unpublish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback {
    // TODO: implement
}

@end
