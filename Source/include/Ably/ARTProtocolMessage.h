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
    ARTProtocolMessageHeartbeat NS_SWIFT_NAME(heartbeat) = 0,
    ARTProtocolMessageAck NS_SWIFT_NAME(ack) = 1,
    ARTProtocolMessageNack NS_SWIFT_NAME(nack) = 2,
    ARTProtocolMessageConnect NS_SWIFT_NAME(connect) = 3,
    ARTProtocolMessageConnected NS_SWIFT_NAME(connected) = 4,
    ARTProtocolMessageDisconnect NS_SWIFT_NAME(disconnect) = 5,
    ARTProtocolMessageDisconnected NS_SWIFT_NAME(disconnected) = 6,
    ARTProtocolMessageClose NS_SWIFT_NAME(close) = 7,
    ARTProtocolMessageClosed NS_SWIFT_NAME(closed) = 8,
    ARTProtocolMessageError NS_SWIFT_NAME(error) = 9,
    ARTProtocolMessageAttach NS_SWIFT_NAME(attach) = 10,
    ARTProtocolMessageAttached NS_SWIFT_NAME(attached) = 11,
    ARTProtocolMessageDetach NS_SWIFT_NAME(detach) = 12,
    ARTProtocolMessageDetached NS_SWIFT_NAME(detached) = 13,
    ARTProtocolMessagePresence NS_SWIFT_NAME(presence) = 14,
    ARTProtocolMessageMessage NS_SWIFT_NAME(message) = 15,
    ARTProtocolMessageSync NS_SWIFT_NAME(sync) = 16,
    ARTProtocolMessageAuth NS_SWIFT_NAME(auth) = 17,
} NS_SWIFT_NAME(ProtocolMessageAction);

/// :nodoc:

NSString *_Nonnull ARTProtocolMessageActionToStr(ARTProtocolMessageAction action) NS_SWIFT_NAME(ProtocolMessageActionToStr(_:));

NS_ASSUME_NONNULL_BEGIN

/**
 * :nodoc:
 * A message sent and received over the Realtime protocol.
 * ARTProtocolMessage always relates to a single channel only, but can contain multiple individual messages or presence messages.
 * ARTProtocolMessage are serially numbered on a connection.
 */
NS_SWIFT_NAME(ProtocolMessage)
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
