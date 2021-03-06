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
            let options = ARTClientOptions(key: "xxxx:xxxx")
            options.dispatchQueue = AblyTests.userQueue
            options.internalDispatchQueue = AblyTests.queue
            rest = ARTRest(options: options)
            rest.internal.options.clientId = "tester"
            rest.internal.httpExecutor = mockHttpExecutor
            rest.internal.resetDeviceSingleton()
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
                            expect(error.message).to(contain("cannot use device before device activation has finished"))
                            expect(AblyTests.currentQueueLabel() == AblyTests.userQueue.label).to(beTrue())
                            done()
                        }
                    }
                }

                // RSH7a2, RSH7a3
                it("should do a POST request to /push/channelSubscriptions and include device authentication") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
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
                    let decodedBody: Any
                    do {
                        decodedBody = try rest.internal.defaultEncoder.decode(rawBody)
                    }
                    catch {
                        fail("Decode failed: \(error)"); return
                    }
                    guard let body = decodedBody as? NSDictionary else {
                        fail("body is invalid"); return
                    }

                    expect(request.httpMethod) == "POST"
                    expect(body.value(forKey: "deviceId") as? String).to(equal(rest.device.id))
                    expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

                    let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                    expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

            // RSH7b
            context("subscribeClient") {
                // RSH7b1
                it("should fail if the LocalDevice doesn't have a clientId") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
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
                            expect(error.message).to(contain("null client ID"))
                            expect(AblyTests.currentQueueLabel() == AblyTests.userQueue.label).to(beTrue())
                            done()
                        }
                    }
                }

                // RSH7b2
                it("should do a POST request to /push/channelSubscriptions") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
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
                    let decodedBody: Any
                    do {
                        decodedBody = try rest.internal.defaultEncoder.decode(rawBody)
                    }
                    catch {
                        fail("Decode failed: \(error)"); return
                    }
                    guard let body = decodedBody as? NSDictionary else {
                        fail("body is invalid"); return
                    }

                    expect(request.httpMethod) == "POST"
                    expect(body.value(forKey: "clientId") as? String).to(equal(rest.device.clientId))
                    expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

            // RSH7c
            context("unsubscribeDevice") {
                // RSH7c1
                it("should fail if the LocalDevice doesn't have a deviceIdentityToken") {
                    waitUntil(timeout: testTimeout) { done in
                        rest.channels.get("foo").push.unsubscribeDevice { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("cannot use device before device activation has finished"))
                            expect(AblyTests.currentQueueLabel() == AblyTests.userQueue.label).to(beTrue())
                            done()
                        }
                    }
                }

                // RSH7c2, RSH7c3
                it("should do a DELETE request to /push/channelSubscriptions and include device authentication") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.push.unsubscribeDevice { error in
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
                    guard let query = request.url?.query else {
                        fail("should have a body"); return
                    }

                    expect(request.httpMethod) == "DELETE"
                    expect(query).to(haveParam("deviceId", withValue: rest.device.id))
                    expect(query).to(haveParam("channel", withValue: channel.name))

                    let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                    expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

            // RSH7d
            context("unsubscribeClient") {
                // RSH7d1
                it("should fail if the LocalDevice doesn't have a clientId") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let originalClientId = rest.device.clientId
                    rest.device.clientId = nil
                    defer { rest.device.clientId = originalClientId }

                    waitUntil(timeout: testTimeout) { done in
                        rest.channels.get("foo").push.unsubscribeClient { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("null client ID"))
                            expect(AblyTests.currentQueueLabel() == AblyTests.userQueue.label).to(beTrue())
                            done()
                        }
                    }
                }

                // RSH7d2
                it("should do a DELETE request to /push/channelSubscriptions") {
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.push.unsubscribeClient { error in
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
                    guard let query = request.url?.query else {
                        fail("should have a body"); return
                    }

                    expect(request.httpMethod) == "DELETE"
                    expect(query).to(haveParam("clientId", withValue: rest.device.clientId!))
                    expect(query).to(haveParam("channel", withValue: channel.name))

                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
                    expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
                }
            }

            // RSH7e
            context("listSubscriptions") {
                it("should return a paginated result with PushChannelSubscription filtered by channel and device") {
                    let params = [
                        "deviceId": "111",
                        "channel": "aaa"
                    ]
                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        try? channel.push.listSubscriptions(params) { result, error in
                            expect(error).to(beNil())
                            expect(result).toNot(beNil())
                            done()
                        }
                    }

                    guard let request = mockHttpExecutor.requests.first else {
                        fail("should have a \"/push/channelSubscriptions\" request"); return
                    }
                    guard let url = request.url, url.absoluteString.contains("/push/channelSubscriptions") else {
                        fail("should have a \"/push/channelSubscriptions\" URL"); return
                    }
                    guard let query = request.url?.query else {
                        fail("should have a body"); return
                    }

                    expect(query).to(haveParam("deviceId", withValue: params["deviceId"]))
                    expect(query).toNot(haveParam("clientId", withValue: rest.device.clientId))
                    expect(query).to(haveParam("channel", withValue: params["channel"]))
                    expect(query).to(haveParam("concatFilters", withValue: "true"))
                }

                it("should return a paginated result with PushChannelSubscription filtered by channel and client") {
                    let params = [
                        "clientId": "tester",
                        "channel": "aaa"
                    ]
                    let channel = rest.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        try? channel.push.listSubscriptions(params) { result, error in
                            expect(error).to(beNil())
                            expect(result).toNot(beNil())
                            done()
                        }
                    }

                    guard let request = mockHttpExecutor.requests.first else {
                        fail("should have a \"/push/channelSubscriptions\" request"); return
                    }
                    guard let url = request.url, url.absoluteString.contains("/push/channelSubscriptions") else {
                        fail("should have a \"/push/channelSubscriptions\" URL"); return
                    }
                    guard let query = request.url?.query else {
                        fail("should have a body"); return
                    }

                    expect(query).to(haveParam("clientId", withValue: params["clientId"]))
                    expect(query).toNot(haveParam("deviceId", withValue: rest.device.id))
                    expect(query).to(haveParam("channel", withValue: params["channel"]))
                    expect(query).to(haveParam("concatFilters", withValue: "true"))
                }

                it("should not accept null deviceId and null clientId") {
                    let channel = rest.channels.get("foo")
                    expect { try channel.push.listSubscriptions([:]) { _, _ in } }.to(throwError { (error: NSError) in
                        expect(error.code).to(equal(ARTDataQueryError.missingRequiredFields.rawValue))
                    })
                }

                it("should not accept both deviceId and clientId params at the same time") {
                    let params = [
                        "deviceId": "x",
                        "clientId": "y"
                    ]
                    let channel = rest.channels.get("foo")
                    expect { try channel.push.listSubscriptions(params) { _, _ in } }.to(throwError { (error: NSError) in
                        expect(error.code).to(equal(ARTDataQueryError.invalidParameters.rawValue))
                    })
                }

                it("should return a paginated result with PushChannelSubscription") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "tester"
                    // Prevent channel name to be prefixed by test-*
                    options.channelNamePrefix = nil
                    let rest = ARTRest(options: options)
                    rest.internal.storage = MockDeviceStorage()

                    // Activate device
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                    rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                    defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

                    let channel = rest.channels.get("pushenabled:foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.push.subscribeClient { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    let params: [String: String] = [
                        "clientId": options.clientId!,
                        "channel": channel.name
                    ]
                    waitUntil(timeout: testTimeout) { done in
                        try! channel.push.listSubscriptions(params) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("Result is nil"); done(); return
                            }
                            expect(result.items.count) == 1
                            done()
                        }
                    }
                }
            }

        }

    }

}
