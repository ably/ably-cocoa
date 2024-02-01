#import "ARTMessageExtrasFilter.h"
#import <Foundation/Foundation.h>

// Convenience struct for passing around message ref information
@interface MessageRef : NSObject
    @property (readwrite) NSString* type;
    @property (readwrite) NSString* timeserial;
@end

@implementation MessageRef

@end

#pragma mark ARTMessageExtrasFilter

@implementation ARTMessageExtrasFilter {
    ARTMessageFilter *_filter;
}

- (instancetype) initWithFilter:(ARTMessageFilter *)filter {
    self = [super init];
    if (self) {
        _filter = filter;
    }

    return self;
}

// A message is valid if the client id, name, and reference information matches the filter
- (bool) onMessage: (ARTMessage*) message {
    return [self clientIdMatchesFilter:message] &&
        [self nameMatchesFilter:message] &&
        [self referenceMatchesFilter:message];
}

// Check that the message extras are/are not a reference to another message, and that the
// type and timeserials match the filter.
- (bool) referenceMatchesFilter: (ARTMessage *) message {
    if (_filter.isRef == nil && _filter.refType == nil && _filter.refTimeserial == nil) {
        return true;
    }

    MessageRef* messageRef = [self getMessageRefFromExtras:message];

    return [self isRefMatchesFilter:messageRef] &&
    [self refTimeserialMatchesFilter:messageRef] &&
    [self refTypeMatchesFilter:messageRef];
}

- (bool) clientIdMatchesFilter: (ARTMessage*) message {
    return _filter.clientId == nil || (message.clientId != nil && [message.clientId isEqualToString:_filter.clientId]);
}

- (bool) nameMatchesFilter: (ARTMessage*) message {
    return _filter.name == nil || (message.name != nil && [message.name isEqualToString:_filter.name]);
}

- (MessageRef*) getMessageRefFromExtras: (ARTMessage *) message {
    if (message.extras == nil) {
        return nil;
    }

    NSError *e = nil;
    NSDictionary *extrasDict = [message.extras toJSON:&e];
    if (e) {
        return nil;
    }

    if (extrasDict == nil) {
        return nil;
    }

    NSDictionary* messageRef = [extrasDict valueForKey:@"ref"];
    if (messageRef == nil) {
        return nil;
    }

    NSString* refTimeserial = [messageRef valueForKey:@"timeserial"];
    NSString* refType = [messageRef valueForKey:@"type"];

    if (refTimeserial == nil || refType == nil) {
        return nil;
    }

    MessageRef* ref;
    ref = [MessageRef alloc];
    ref.type = refType;
    ref.timeserial = refTimeserial;

    return ref;
}

- (bool) isRefMatchesFilter: (MessageRef*) messageRef {
    return _filter.isRef == nil ||
        ([_filter.isRef isEqualToNumber:[NSNumber numberWithBool:YES]] && messageRef != nil) ||
    ([_filter.isRef isEqualToNumber:[NSNumber numberWithBool:NO]] && messageRef == nil);
}

- (bool) refTimeserialMatchesFilter: (MessageRef*) messageRef {
    return _filter.refTimeserial == nil ||
    (messageRef.timeserial != nil && [messageRef.timeserial isEqualToString:_filter.refTimeserial]);
}

- (bool) refTypeMatchesFilter: (MessageRef*) messageRef {
    return _filter.refType == nil ||
    (messageRef.type != nil && [messageRef.type isEqualToString:_filter.refType]);
}

@end
