#import <Foundation/Foundation.h>

#import <Ably/ARTMessage.h>
#import <Ably/ARTPresenceMessage.h>

@class ARTConnectionDetails;
@class ARTAuthDetails;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;

/// :nodoc:
typedef NS_ENUM(NSUInteger, ARTProtocolMessageAction) {
    ARTProtocolMessageHeartbeat = 0,
    ARTProtocolMessageAck = 1,
    ARTProtocolMessageNack = 2,
    ARTProtocolMessageConnect = 3,
    ARTProtocolMessageConnected = 4,
    ARTProtocolMessageDisconnect = 5,
    ARTProtocolMessageDisconnected = 6,
    ARTProtocolMessageClose = 7,
    ARTProtocolMessageClosed = 8,
    ARTProtocolMessageError = 9,
    ARTProtocolMessageAttach = 10,
    ARTProtocolMessageAttached = 11,
    ARTProtocolMessageDetach = 12,
    ARTProtocolMessageDetached = 13,
    ARTProtocolMessagePresence = 14,
    ARTProtocolMessageMessage = 15,
    ARTProtocolMessageSync = 16,
    ARTProtocolMessageAuth = 17,
};

/// :nodoc:
NSString *_Nonnull ARTProtocolMessageActionToStr(ARTProtocolMessageAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 * :nodoc:
 * A message sent and received over the Realtime protocol.
 * ARTProtocolMessage always relates to a single channel only, but can contain multiple individual messages or presence messages.
 * ARTProtocolMessage are serially numbered on a connection.
 */
@interface ARTProtocolMessage : NSObject

@property (readwrite, nonatomic) ARTProtocolMessageAction action;
@property (readwrite, nonatomic) int count;
@property (nullable, readwrite, nonatomic) ARTErrorInfo *error;
@property (nullable, readwrite, nonatomic) NSString *id;
@property (nullable, readwrite, nonatomic) NSString *channel;
@property (nullable, readwrite, nonatomic) NSString *channelSerial;
@property (nullable, readwrite, nonatomic) NSString *connectionId;
@property (nullable, readwrite, nonatomic, getter=getConnectionKey) NSString *connectionKey;
@property (nullable, readwrite, nonatomic) NSNumber *msgSerial;
@property (nullable, readwrite, nonatomic) NSDate *timestamp;
@property (nullable, readwrite, nonatomic) NSArray<ARTMessage *> *messages;
@property (nullable, readwrite, nonatomic) NSArray<ARTPresenceMessage *> *presence;
@property (readwrite, nonatomic) int64_t flags;
@property (nullable, readwrite, nonatomic) ARTConnectionDetails *connectionDetails;
@property (nullable, nonatomic) ARTAuthDetails *auth;
@property (nonatomic, nullable) NSStringDictionary *params;

@end

NS_ASSUME_NONNULL_END
