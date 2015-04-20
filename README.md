# [Ably](https://www.ably.io) iOS client library

[![Build Status](https://travis-ci.org/ably/ably-ios.png)](https://travis-ci.org/ably/ably-ios)

An iOS client library for [ably.io](https://www.ably.io), the realtime messaging service, written in Objective-C.

## Installation

* git clone https://github.com/ably/ably-ios
* drag the directory ably-ios/ably-ios into your project as a group
* git clone https://github.com/square/SocketRocket.git
* drag the directory SocketRocket/SocketRocket into your project as a group



## Using the Realtime API

### Connection
```
     ARTRealtime * client = [[ARTRealtime alloc] initWithKey:@"xxxxx"];
     [client subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                         if (state == ARTRealtimeConnected) {
                             // you are connected
                         }];
```

### Subscribing to a channel

```
ARTRealtimeChannel * channel = [client channel:@"test"];
[channel subscribe:^(ARTMessage * message) {
     NSString * content =[message content];
     NSLog(@" message is %@", content);
}];
```

### Publishing to a channel
```
    [channel publish:@"Hello, Channel!" cb:^(ARTStatus status) {
        if(status != ARTStatusOk) {
            //something went wrong.
        }
    }];
```

### Querying the History
```
    [channel history:^(ARTStatus status, id<ARTPaginatedResult> messagesPage) {
        XCTAssertEqual(status, ARTStatusOk);
        NSArray *messages = [messagesPage currentItems];

        NSLog(@"this page has %d messages", [messages count]);
        ARTMessage *message = messages[0];
        NSString *messageContent = [message content];
        NSLog(@"first item is %@", messageContent);
    }];
```


### Presence on a channel
```
    ARTOptions * options = [[ARTOptions alloc] initWithKey:@"xxxxx"];
    options.clientId = @"john.doe";
    ARTRealtime * client = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel * channel = [client channel:@"test"];
    [channel publishPresenceEnter:@"I'm here" cb:^(ARTStatus status) {
        if(status != ARTStatusOk) {
            //something went wrong
        }
    }];
```

### Querying the Presence History
```
    [channel presenceHistory:^(ARTStatus status, id<ARTPaginatedResult> presencePage) {
        NSArray *messages = [presencePage currentItems];
        if(messages) {
            ARTPresenceMessage *firstMessage = messages[0];
            NSString * content = [firstMessage content];
            NSLog(@"first message is %@", content);
        }
    }];
```

## Using the REST API
```
   ARTRest * client = [ARTRest alloc] initWithKey:@"xxxxx"];
   ARTRestChannel * channel = [client channel:@"test"];
```

## Publishing a message to a channel
```
   [channel publish:@"Hello, channel!" cb:^(ARTStatus status){
       if(status != ARTStatusOk) {
           //something went wrong
       }
   }];
```

## Dependencies

The library works on iOS8, and uses [SocketRocket](https://github.com/square/SocketRocket)

## Known limitations

The following features are not implemented yet:

* msgpack transportation
* 256 cryptography

The following features are do not have sufficient test coverage:

* 128 cryptography
* app stats
* capability
* token auth

## Support and feedback

Please visit https://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Ensure you have added suitable tests and the test suite is passing(`bundle exec rspec`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright (c) 2015 Ably, Licensed under an MIT license.  Refer to [LICENSE.txt](LICENSE.txt) for the license terms.
