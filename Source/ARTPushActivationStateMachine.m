//
//  ARTPushActivationStateMachine.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationStateMachine.h"
#import "ARTPushActivationEvent.h"
#import "ARTPushActivationState.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTTypes.h"

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationState *_current;
    NSMutableArray<ARTPushActivationEvent *> *_pendingEvents;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _logger = [_httpExecutor logger];
        // Unarquiving
        NSData *stateData = [[NSUserDefaults standardUserDefaults] objectForKey:ARTPushActivationCurrentStateKey];
        _current = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
        if (!_current) {
            _current = [ARTPushActivationNotActivatedState new];
        }
        NSData *pendingEventsData = [[NSUserDefaults standardUserDefaults] objectForKey:ARTPushActivationPendingEventsKey];
        _pendingEvents = [NSKeyedUnarchiver unarchiveObjectWithData:pendingEventsData];
        if (!_pendingEvents) {
            _pendingEvents = [NSMutableArray array];
        }
    }
    return self;
}

- (void)handleEvent:(nonnull ARTPushActivationEvent *)event {
    ARTPushActivationState *next = [_current transition:event];
    _current = next;
    [self persist];
}

- (void)persist {
    // Arquiving
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_current] forKey:ARTPushActivationCurrentStateKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_pendingEvents] forKey:ARTPushActivationPendingEventsKey];
}

@end
