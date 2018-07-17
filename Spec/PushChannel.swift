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
            rest.options.clientId = "tester"
            rest.httpExecutor = mockHttpExecutor
        }

        // RSH7
        describe("Push Channel") {

            // RSH7a
            context("subscribeDevice") {
                // RSH7a1
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

                // RSH7a2, RSH7a3
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
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

            // RSH7b
            context("subscribeClient") {
                // RSH7b1
                it("should fail if the LocalDevice doesn't have a clientId") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", deviceId: rest.device.id)
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let originalClientId = rest.device.clientId
                    rest.device.clientId = nil
                    defer { rest.device.clientId = originalClientId }

                    waitUntil(timeout: testTimeout) { done in
                        rest.channels.get("foo").push.subscribeClient { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("cannot subscribe with null client ID"))
                            done()
                        }
                    }
                }

                // RSH7a2
                it("should do a request to /push/channelSubscriptions") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", deviceId: rest.device.id)
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.push.subscribeClient { error in
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
                    expect(body.value(forKey: "clientId") as? String).to(equal(rest.device.clientId))
                    expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceIdentityToken"]).to(beNil())
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

        }

    }

}
