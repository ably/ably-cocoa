# [Ably](https://www.ably.io) iOS client library

[![Build Status](https://travis-ci.org/ably/ably-ios.png)](https://travis-ci.org/ably/ably-ios)

An iOS client library for [ably.io](https://www.ably.io), the realtime messaging service, written in Objective-C.

## Installation

* git clone https://github.com/ably/ably-ios
* drag ably-ios/ably-ios into your project as a group
* git clone https://github.com/square/SocketRocket.git
* drag SocketRocket/SocketRocket into your project as a group

## Dependencies

The library works on iOS7 and above, and uses [SocketRocket](https://github.com/square/SocketRocket)

## Usage

See https://www.ably.io/documentation for a quickstart guide

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
