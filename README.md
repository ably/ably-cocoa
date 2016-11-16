# [Ably](https://www.ably.io) iOS client library

An iOS client library for [ably.io](https://www.ably.io), the realtime messaging service, written in Objective-C.

## Documentation

Visit https://www.ably.io/documentation for a complete API reference and more examples.

## Installation

You can install Ably for iOS through CocoaPods, Carthage or manually.

### Installing through [CocoaPods](https://cocoapods.org/) (recommended)

Add this line to your application's Podfile:

    # For Xcode 7.3 and newer
    pod 'Ably', '~> 0.8'

And then install the dependency:

    $ pod install

### Installing through [Carthage](https://github.com/Carthage/Carthage/)

Add this line to your application's Cartfile:

    # For Xcode 7.3 and newer
    github "ably/ably-ios" ~> 0.8

And then run `carthage update` to build the framework and drag the built Ably.framework into your Xcode project.

### Manual installation 

1. Get the code from GitHub [from the release page](https://github.com/ably/ably-ios/releases/tag/0.8.0), or clone it to get the latest, unstable and possibly underdocumented version: `git clone git@github.com:ably/ably-ios.git` 
2. Drag the directory `ably-ios/ably-ios` into your project as a group.
3. Ably depends on [SocketRocket](https://github.com/facebook/SocketRocket) 0.5.1; get it [from the releases page](https://github.com/facebook/SocketRocket/releases/tag/0.5.1) and follow [its manual installation instructions](https://github.com/facebook/SocketRocket#installing-ios).
4. Ably also depends on [msgpack](https://github.com/rvi/msgpack-objective-C) 0.1.8; get it [from the releases page](https://github.com/rvi/msgpack-objective-C/releases/tag/0.1.8) and link it into your project.

## Using the Realtime API

<!--
NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE N
**********************************************
==============================================

(Sorry for the noise.)

Those examples need to be kept in sync with:

ablySpec/ReadmeExamples.swift
ably-iosTests/ARTReadmeExamples.m

==============================================
**********************************************
OTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NO
-->

### Introduction

All examples assume a client has been created as follows:

**Swift**

```swift
// basic auth with an API key
let client = ARTRealtime(key: "xxxx:xxxx")

// using token auth
let client = ARTRealtime(token: "xxxx")
```

**Objective-C**

```objective-c
// basic auth with an API key
ARTRealtime* client = [[ARTRealtime alloc] initWithKey:@"xxxx:xxxx"];

// using token auth
ARTRealtime* client = [[ARTRealtime alloc] initWithToken:@"xxxx"];
```

### Connection

Instantiating `ARTRealtime` starts a connection by default. You can catch connection success or error by listening to the connection's state changes:

**Swift**

```swift
client.connection.on { stateChange in
    let stateChange = stateChange!
    switch stateChange.current {
    case .Connected:
        print("connected!")
    case .Failed:
        print("failed! \(stateChange.reason)")
    default:
        break
    }
}
```

**Objective-C**

```objective-c
[client.connection on:^(ARTConnectionStateChange *stateChange) {
    switch (stateChange.current) {
        case ARTRealtimeConnected:
            NSLog(@"connected!");
            break;
        case ARTRealtimeFailed:
            NSLog(@"failed! %@", stateChange.reason);
            break;
        default:
            break;
    }
}];
```

You can also connect manually by setting the appropiate option.

**Swift**

```swift
let options = ARTClientOptions(key: "xxxx:xxxx")
options.autoConnect = false
let client = ARTRealtime(options: options)
client.connection.connect()
```

**Objective-C**

```objective-c
ARTClientOptions *options = [[ARTClientOptions alloc] initWithKey:@"xxxx:xxxx"];
options.autoConnect = false;
ARTRealtime *client = [[ARTRealtime alloc] initWithOptions:options];
[client.connection connect];
```

### Subscribing to a channel

Given:

**Swift**

```swift
let channel = client.channels.get("test")
```

**Objective-C**

```objective-c
ARTRealtimeChannel *channel = [client.channels get:@"test"];
```

Subscribe to all events:

**Swift**

```swift
channel.subscribe { message in
    print(message.name)
    print(message.data)
}
```

**Objective-C**

```objective-c
[channel subscribe:^(ARTMessage *message) {
    NSLog(@"%@", message.name);
    NSLog(@"%@", message.data);
}];
```

Only certain events:

**Swift**

```swift
channel.subscribe("myEvent") { message in
    print(message.name)
    print(message.data)
}
```

**Objective-C**

```objective-c
[channel subscribe:@"myEvent" callback:^(ARTMessage *message) {
    NSLog(@"%@", message.name);
    NSLog(@"%@", message.data);
}];
```

### Publishing to a channel

**Swift**

```swift
channel.publish("greeting", data: "Hello World!")
```

**Objective-C**

```objective-c
[channel publish:@"greeting" data:@"Hello World!"];
```

### Querying the history

**Swift**

```swift
channel.history { messagesPage, error in
    let messagesPage = messagesPage!
    print(messagesPage.items)
    print(messagesPage.items.first)
    print((messagesPage.items.first as? ARTMessage)?.data) // payload for the message
    print(messagesPage.items.count) // number of messages in the current page of history
    messagesPage.next { nextPage, error in
        // retrieved the next page in nextPage
    }
    print(messagesPage.hasNext) // true, there are more pages
}
```

**Objective-C**

```objective-c
[channel history:^(ARTPaginatedResult<ARTMessage *> *messagesPage, ARTErrorInfo *error) {
    NSLog(@"%@", messagesPage.items);
    NSLog(@"%@", messagesPage.items.firstObject);
    NSLog(@"%@", messagesPage.items.firstObject.data); // payload for the message
    NSLog(@"%lu", (unsigned long)[messagesPage.items count]); // number of messages in the current page of history
    [messagesPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
    NSLog(@"%d", messagesPage.hasNext); // true, there are more pages
}];
```

### Presence on a channel

**Swift**

```swift
let channel = client.channels.get("test")

channel.presence.enter("john.doe") { errorInfo in
    channel.presence.get { members, errorInfo in
        // members is the array of members present
    }
}
```

**Objective-C**

```objective-c
[channel.presence enter:@"john.doe" callback:^(ARTErrorInfo *errorInfo) {
    [channel.presence get:^(ARTPaginatedResult<ARTPresenceMessage *> *result, ARTErrorInfo *error) {
        // members is the array of members present
    }];
}];
```

### Querying the presence history

**Swift**

```swift
channel.presence.history { presencePage, error in
    let presencePage = presencePage!
    if let first = presencePage.items.first as? ARTPresenceMessage {
        print(first.action) // Any of .Enter, .Update or .Leave
        print(first.clientId) // client ID of member
        print(first.data) // optional data payload of member
        presencePage.next { nextPage, error in
            // retrieved the next page in nextPage
        }
    }
}
```

**Objective-C**

```objective-c
[channel.presence history:^(ARTPaginatedResult<ARTPresenceMessage *> *presencePage, ARTErrorInfo *error) {
    ARTPresenceMessage *first = (ARTPresenceMessage *)presencePage.items.firstObject;
    NSLog(@"%lu", (unsigned long)first.action); // Any of ARTPresenceEnter, ARTPresenceUpdate or ARTPresenceLeave
    NSLog(@"%@", first.clientId); // client ID of member
    NSLog(@"%@", first.data); // optional data payload of member
    [presencePage next:^(ARTPaginatedResult<ARTPresenceMessage *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
}];
```

### Using the `authCallback`

A callback to call to obtain a signed token request.  
`ARTClientOptions` and `ARTRealtime` objects can be instantiated as follow:

**Swift**

```swift
let clientOptions = ARTClientOptions()
clientOptions.authCallback = { params, callback in
    getTokenRequestJSONFromYourServer(params) { json, error in
        //handle error
        do {
            callback(try ARTTokenRequest.fromJson(json), nil)
        } catch let error as NSError {
            callback(nil, error)
        }
    }
}

let client = ARTRealtime(options:clientOptions)
```

**Objective-C**

```objective-c
ARTClientOptions *clientOptions = [[ARTClientOptions alloc] init];
clientOptions.authCallback = ^(ARTTokenParams *params, void(^callback)(id<ARTTokenDetailsCompatible>, NSError*)) {
    [self getTokenRequestJSONFromYourServer:params completion:^(NSDictionary *json, NSError *error) {
        //handle error
        ARTTokenRequest *tokenRequest = [ARTTokenRequest fromJson:json error:&error];
        callback(tokenRequest, error);
    }];
};

ARTRealtime *client = [[ARTRealtime alloc] initWithOptions:clientOptions];
```

## Using the REST API

### Introduction

All examples assume a client and/or channel has been created as follows:

**Swift**

```swift
let client = ARTRest(key: "xxxx:xxxx")
let channel = client.channels.get("test")
```

**Objective-C**

```objective-c
ARTRest *client = [[ARTRest alloc] initWithKey:@"xxxx:xxxx"];
ARTRestChannel *channel = [client.channels get:@"test"];
```

### Publishing a message to a channel

**Swift**

```swift
channel.publish("myEvent", data: "Hello!")
```

**Objective-C**

```objective-c
[channel publish:@"myEvent" data:@"Hello!"];
```

### Querying the history

**Swift**

```swift
channel.history { messagesPage, error in
    let messagesPage = messagesPage!
    print(messagesPage.items.first)
    print((messagesPage.items.first as? ARTMessage)?.data) // payload for the message
    messagesPage.next { nextPage, error in
        // retrieved the next page in nextPage
    }
    print(messagesPage.hasNext) // true, there are more pages
}
```

**Objective-C**

```objective-c
[channel history:^(ARTPaginatedResult<ARTMessage *> *messagesPage, ARTErrorInfo *error) {
    NSLog(@"%@", messagesPage.items.firstObject);
    NSLog(@"%@", messagesPage.items.firstObject.data); // payload for the message
    NSLog(@"%lu", (unsigned long)[messagesPage.items count]); // number of messages in the current page of history
    [messagesPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
    NSLog(@"%d", messagesPage.hasNext); // true, there are more pages
}];
```

### Presence on a channel

**Swift**

```swift
channel.presence.get { membersPage, error in
    let membersPage = membersPage!
    print(membersPage.items.first)
    print((membersPage.items.first as? ARTPresenceMessage)?.data) // payload for the message
    membersPage.next { nextPage, error in
        // retrieved the next page in nextPage
    }
    print(membersPage.hasNext) // true, there are more pages
}
```

**Objective-C**

```objective-c
[channel.presence get:^(ARTPaginatedResult<ARTPresenceMessage *> *membersPage, ARTErrorInfo *error) {
    NSLog(@"%@", membersPage.items.firstObject);
    NSLog(@"%@", membersPage.items.firstObject.data); // payload for the message
    [membersPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
    NSLog(@"%d", membersPage.hasNext); // true, there are more pages
}];
```

### Querying the presence history

**Swift**

```swift
channel.presence.history { presencePage, error in
    let presencePage = presencePage!
    if let first = presencePage.items.first as? ARTPresenceMessage {
        print(first.clientId) // client ID of member
        presencePage.next { nextPage, error in
            // retrieved the next page in nextPage
        }
    }
}
```

**Objective-C**

```objective-c
[channel.presence history:^(ARTPaginatedResult<ARTPresenceMessage *> *presencePage, ARTErrorInfo *error) {
    ARTPresenceMessage *first = (ARTPresenceMessage *)presencePage.items.firstObject;
    NSLog(@"%@", first.clientId); // client ID of member
    NSLog(@"%@", first.data); // optional data payload of member
    [presencePage next:^(ARTPaginatedResult<ARTPresenceMessage *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
}];
```

### Generate token

**Swift**

```swift
client.auth.requestToken(nil, withOptions: nil) { tokenDetails, error in
    let tokenDetails = tokenDetails!
    print(tokenDetails.token) // "xVLyHw.CLchevH3hF....MDh9ZC_Q"
    let client = ARTRest(token: tokenDetails.token)
}
```

**Objective-C**

```objective-c
[client.auth requestToken:nil withOptions:nil callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
    NSLog(@"%@", tokenDetails.token); // "xVLyHw.CLchevH3hF....MDh9ZC_Q"
    ARTRest *client = [[ARTRest alloc] initWithToken:tokenDetails.token];
}];
```

### Fetching your application's stats

**Swift**

```swift
client.stats { statsPage, error in
    let statsPage = statsPage!
    print(statsPage.items.first)
    statsPage.next { nextPage, error in
        // retrieved the next page in nextPage
    }
}
```

**Objective-C**

```objective-c
[client stats:^(ARTPaginatedResult<ARTStats *> *statsPage, ARTErrorInfo *error) {
    NSLog(@"%@", statsPage.items.firstObject);
    [statsPage next:^(ARTPaginatedResult<ARTStats *> *nextPage, ARTErrorInfo *error) {
        // retrieved the next page in nextPage
    }];
}];
```

### Fetching the Ably service time

**Swift**

```swift
client.time { time, error in
    print(time) // 2016-02-09 03:59:24 +0000
}
```

**Objective-C**

```objective-c
[client time:^(NSDate *time, NSError *error) {
    NSLog(@"%@", time); // 2016-02-09 03:59:24 +0000
}];
```

## Support, feedback and troubleshooting

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

You can also view the [community reported Github issues](https://github.com/ably/ably-ios/issues).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Ensure you have added suitable tests and the test suite is passing
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright (c) 2015 Ably Real-time Ltd, Licensed under the Apache License, Version 2.0.  Refer to [LICENSE](LICENSE) for the license terms.
