#import "ARTFilteredMessageCallbackFactory.h"
#import <Ably/ARTMessageExtrasFilter.h>

@implementation ARTFilteredMessageCallbackFactory

+ (ARTMessageCallback) createFilteredCallback:(ARTMessageCallback) original filter:(ARTMessageFilter *) filter {
    ARTMessageExtrasFilter * extrasFilter = [[ARTMessageExtrasFilter alloc] initWithFilter:filter];

    return ^(ARTMessage* message) {{
        if (![extrasFilter onMessage:message]) {
            return;
        }

        original(message);
    }};
}

@end
