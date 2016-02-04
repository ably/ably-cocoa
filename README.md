# [Ably](https://www.ably.io) iOS client library

[![Build Status](https://travis-ci.org/ably/ably-ios.png)](https://travis-ci.org/ably/ably-ios)

An iOS client library for [ably.io](https://www.ably.io), the realtime messaging service, written in Objective-C.

## Documentation

Visit https://www.ably.io/documentation for a complete API reference and more examples.

## CocoaPod Installation
add pod ably to your Podfile. 

## Manual Installation 

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
         }
     }];
```

### Subscribing to a channel

```
ARTRealtimeChannel * channel = [client.channels get:@"test"];
[channel subscribe:^(ARTMessage *message) {
     NSString *content =[message content];
     NSLog(@"message is %@", content);
}];
```

### Publishing to a channel
```
    [channel publish:nil data:@"Hello, Channel!" cb:^(ARTErrorInfo *errorInfo) {
        if(status.status != ARTStatusOk) {
            //something went wrong.
        }
    }];
```

### Querying the History
```
    [channel history:^(ARTStatus *status, id<ARTPaginatedResult> messagesPage) {
        if(status.status != ARTStatusOk) {
            //something went wrong.
        }
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
    ARTRealtimeChannel * channel = [client.channels get:@"test"];
    [channel publishPresenceEnter:@"I'm here" cb:^(ARTStatus *status) {
        if(status != ARTStatusOk) {
            //something went wrong
        }
    }];
```

### Querying the Presence History
```
    [channel presenceHistory:^(ARTStatus *status, id<ARTPaginatedResult> presencePage) {
        if(status.status != ARTStatusOk) {
            //something went wrong
        }
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
   ARTRestChannel * channel = [client.channels get:@"test"];
```

## Publishing a message to a channel
```
   [channel publish:nil data:@"Hello, channel!" cb:^(ARTErrorInfo *errorInfo){
       if(status.status != ARTStatusOk) {
           //something went wrong
       }
   }];
```

## Dependencies

The library works on iOS8, and uses [SocketRocket](https://github.com/square/SocketRocket)

## Known limitations

The following features are not implemented yet:

* msgpack transportation

## Support, feedback and troubleshooting

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

You can also view the [community reported Github issues](https://github.com/ably/ably-ios/issues).

To see what has changed in recent versions of Bundler, see the [CHANGELOG](CHANGELOG.md).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Ensure you have added suitable tests and the test suite is passing
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright (c) 2015 Ably Real-time Ltd, Licensed under the Apache License, Version 2.0.  Refer to [LICENSE](LICENSE) for the license terms.
