//
//  PushChannel.swift
//  Ably
//
//  Created by Ricardo Pereira on 23/03/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick

class PushChannel : QuickSpec {
    override func spec() {

        var rest: ARTRest!
        var mockHttpExecutor: MockHTTPExecutor!

        beforeEach {
            mockHttpExecutor = MockHTTPExecutor()
            rest = ARTRest(key: "xxxx:xxxx")
            rest.httpExecutor = mockHttpExecutor
        }

        // RSH4
        describe("Push Channel") {

            // RSH4a
            context("subscribeDevice") {
                // RSH4a1
                it("should fail if the LocalDevice doesn't have an deviceIdentityToken") {
                    waitUntil(timeout: testTimeout) { done in
                        rest.channels.get("foo").push.subscribeDevice { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("cannot use device before ARTRest.push.activate has finished"))
                            done()
                        }
                    }
                }

                // RSH4a2, RSH4a3
                it("should do a request to /push/channelSubscriptions and include device authentication") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", deviceId: rest.device.id)
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.push.subscribeDevice { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let request = mockHttpExecutor.requests.first else {
                        fail("should have a \"/push/channelSubscriptions\" request"); return
                    }
                    guard let url = request.url, url.absoluteString.contains("/push/channelSubscriptions") else {
                        fail("should have a \"/push/channelSubscriptions\" URL"); return
                    }
                    guard let rawBody = request.httpBody else {
                        fail("should have a body"); return
                    }
                    guard let body = rest.defaultEncoder.decode(rawBody, error: nil) as? NSDictionary else {
                        fail("body is invalid"); return
                    }

                    expect(request.httpMethod) == "POST"
                    expect(body.value(forKey: "deviceId") as? String).to(equal(rest.device.id))
                    expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

                    let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceIdentityToken"]
                    expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
                }
            }

        }

    }

}
