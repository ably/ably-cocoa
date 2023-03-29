#import "ARTResumeRequestResponse.h"
#import "ARTStatus.h"
#import "ARTProtocolMessage.h"
#import "ARTErrorChecker.h"

static NSString *TypeDescription(const ARTResumeRequestResponseType type) {
    switch (type) {
        case ARTResumeRequestResponseTypeValid:
            return @"Valid";
        case ARTResumeRequestResponseTypeInvalid:
            return @"Invalid";
        case ARTResumeRequestResponseTypeFatalError:
            return @"FatalError";
        case ARTResumeRequestResponseTypeTokenError:
            return @"TokenError";
        case ARTResumeRequestResponseTypeUnknown:
            return @"Unknown";
    }
}

@implementation ARTResumeRequestResponse

- (instancetype)initWithCurrentConnectionID:(NSString *const)currentConnectionID
                            protocolMessage:(ARTProtocolMessage *const)protocolMessage
                               errorChecker:(const id<ARTErrorChecker>)errorChecker {
    if (!(self = [super init])) {
        return nil;
    }

    // RTN15c6: "A CONNECTED ProtocolMessage with the same connectionId as the current client (and no error property)."
    if (protocolMessage.action == ARTProtocolMessageConnected && [protocolMessage.connectionId isEqualToString:currentConnectionID] && protocolMessage.error == nil) {
        _type = ARTResumeRequestResponseTypeValid;
        return self;
    }

    // RTN15c7: "CONNECTED ProtocolMessage with a new connectionId and an ErrorInfo in the error field."
    if (protocolMessage.action == ARTProtocolMessageConnected && ![protocolMessage.connectionId isEqualToString:currentConnectionID] && protocolMessage.error != nil) {
        _type = ARTResumeRequestResponseTypeInvalid;
        _error = protocolMessage.error;
        return self;
    }

    // RTN15c5: "ERROR ProtocolMessage indicating a failure to authenticate as a result of a token error (see RTN15h)."
    if (protocolMessage.action == ARTProtocolMessageError && protocolMessage.error != nil && [errorChecker isTokenError:protocolMessage.error]) {
        _type = ARTResumeRequestResponseTypeTokenError;
        _error = protocolMessage.error;
        return self;
    }

    // RTN15c4: "Any other ERROR ProtocolMessage indicating a fatal error in the connection."
    // (I’m reading this as "Any other ERROR ProtocolMessage. This indicates a fatal error in the connection." — that is, I am not expected to apply any further criteria to determine if it is a "fatal" error.)

    // We can assume that an ERROR ProtocolMessage will have a non-nil error (see protocol spec), and if it does not then we will treat it as an "unknown" response type.
    if (protocolMessage.action == ARTProtocolMessageError && protocolMessage.error != nil) {
        _type = ARTResumeRequestResponseTypeFatalError;
        _error = protocolMessage.error;
        return self;
    }

    _type = ARTResumeRequestResponseTypeUnknown;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<%@ %p: type: %@, error: %@>", [self class], self, TypeDescription(self.type), [self.error localizedDescription]];
}

@end
