import Ably
import Nimble
import XCTest

private var rest: ARTRest!
private var mockHttpExecutor: MockHTTPExecutor!

class PushChannelTests: XCTestCase {
    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = rest
        _ = mockHttpExecutor

        return super.defaultTestSuite
    }

    override func setUp() {
        super.setUp()

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

    // RSH7a

    // RSH7a1
    func test__001__Push_Channel__subscribeDevice__should_fail_if_the_LocalDevice_doesn_t_have_an_deviceIdentityToken() {
        waitUntil(timeout: testTimeout) { done in
            rest.channels.get(uniqueChannelName()).push.subscribeDevice { error in
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
    func test__002__Push_Channel__subscribeDevice__should_do_a_POST_request_to__push_channelSubscriptions_and_include_device_authentication() throws {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.push.subscribeDevice { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let rawBody = try XCTUnwrap(request.httpBody, "should have a body")
        let decodedBody = try XCTUnwrap(try rest.internal.defaultEncoder.decode(rawBody), "Decode request body failed")
        let body = try XCTUnwrap(decodedBody as? NSDictionary, "Request body is invalid")

        expect(request.httpMethod) == "POST"
        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(body.value(forKey: "deviceId") as? String).to(equal(rest.device.id))
        expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
    }

    // RSH7b

    // RSH7b1
    func test__003__Push_Channel__subscribeClient__should_fail_if_the_LocalDevice_doesn_t_have_a_clientId() {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let originalClientId = rest.device.clientId
        rest.device.clientId = nil
        defer { rest.device.clientId = originalClientId }

        waitUntil(timeout: testTimeout) { done in
            rest.channels.get(uniqueChannelName()).push.subscribeClient { error in
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
    func test__004__Push_Channel__subscribeClient__should_do_a_POST_request_to__push_channelSubscriptions() throws {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.push.subscribeClient { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let rawBody = try XCTUnwrap(request.httpBody, "should have a body")
        let decodedBody = try XCTUnwrap(try rest.internal.defaultEncoder.decode(rawBody), "Decode request body failed")
        let body = try XCTUnwrap(decodedBody as? NSDictionary, "Request body is invalid")

        expect(request.httpMethod) == "POST"
        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(body.value(forKey: "clientId") as? String).to(equal(rest.device.clientId))
        expect(body.value(forKey: "channel") as? String).to(equal(channel.name))

        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
    }

    // RSH7c

    // RSH7c1
    func test__005__Push_Channel__unsubscribeDevice__should_fail_if_the_LocalDevice_doesn_t_have_a_deviceIdentityToken() {
        waitUntil(timeout: testTimeout) { done in
            rest.channels.get(uniqueChannelName()).push.unsubscribeDevice { error in
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
    func test__006__Push_Channel__unsubscribeDevice__should_do_a_DELETE_request_to__push_channelSubscriptions_and_include_device_authentication() throws {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.push.unsubscribeDevice { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let query = try XCTUnwrap(url.query, "should have a query")

        expect(request.httpMethod) == "DELETE"
        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(query).to(haveParam("deviceId", withValue: rest.device.id))
        expect(query).to(haveParam("channel", withValue: channel.name))

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
    }

    // RSH7d

    // RSH7d1
    func test__007__Push_Channel__unsubscribeClient__should_fail_if_the_LocalDevice_doesn_t_have_a_clientId() {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let originalClientId = rest.device.clientId
        rest.device.clientId = nil
        defer { rest.device.clientId = originalClientId }

        waitUntil(timeout: testTimeout) { done in
            rest.channels.get(uniqueChannelName()).push.unsubscribeClient { error in
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
    func test__008__Push_Channel__unsubscribeClient__should_do_a_DELETE_request_to__push_channelSubscriptions() throws {
        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }

        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.push.unsubscribeClient { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let query = try XCTUnwrap(url.query, "should have a query")
        
        expect(request.httpMethod) == "DELETE"
        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(query).to(haveParam("clientId", withValue: rest.device.clientId!))
        expect(query).to(haveParam("channel", withValue: channel.name))

        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecrect"]).to(beNil())
    }

    // RSH7e

    func test__009__Push_Channel__listSubscriptions__should_return_a_paginated_result_with_PushChannelSubscription_filtered_by_channel_and_device() throws {
        let params = [
            "deviceId": "111",
            "channel": "aaa",
        ]
        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            try? channel.push.listSubscriptions(params) { result, error in
                expect(error).to(beNil())
                expect(result).toNot(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let query = try XCTUnwrap(url.query, "should have a query")

        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(query).to(haveParam("deviceId", withValue: params["deviceId"]))
        expect(query).toNot(haveParam("clientId", withValue: rest.device.clientId))
        expect(query).to(haveParam("channel", withValue: params["channel"]))
        expect(query).to(haveParam("concatFilters", withValue: "true"))
    }

    func test__010__Push_Channel__listSubscriptions__should_return_a_paginated_result_with_PushChannelSubscription_filtered_by_channel_and_client() throws {
        let params = [
            "clientId": "tester",
            "channel": "aaa",
        ]
        let channel = rest.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            try? channel.push.listSubscriptions(params) { result, error in
                expect(error).to(beNil())
                expect(result).toNot(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "should have a \"/push/channelSubscriptions\" request")
        let url = try XCTUnwrap(request.url, "No request url found")
        let query = try XCTUnwrap(url.query, "should have a query")

        expect(url.absoluteString).to(contain("/push/channelSubscriptions"))
        expect(query).to(haveParam("clientId", withValue: params["clientId"]))
        expect(query).toNot(haveParam("deviceId", withValue: rest.device.id))
        expect(query).to(haveParam("channel", withValue: params["channel"]))
        expect(query).to(haveParam("concatFilters", withValue: "true"))
    }

    func test__011__Push_Channel__listSubscriptions__should_not_accept_null_deviceId_and_null_clientId() {
        let channel = rest.channels.get(uniqueChannelName())
        expect { try channel.push.listSubscriptions([:]) { _, _ in } }.to(throwError { (error: NSError) in
            expect(error.code).to(equal(ARTDataQueryError.missingRequiredFields.rawValue))
        })
    }

    func test__012__Push_Channel__listSubscriptions__should_not_accept_both_deviceId_and_clientId_params_at_the_same_time() {
        let params = [
            "deviceId": "x",
            "clientId": "y",
        ]
        let channel = rest.channels.get(uniqueChannelName())
        expect { try channel.push.listSubscriptions(params) { _, _ in } }.to(throwError { (error: NSError) in
            expect(error.code).to(equal(ARTDataQueryError.invalidParameters.rawValue))
        })
    }

    func test__013__Push_Channel__listSubscriptions__should_return_a_paginated_result_with_PushChannelSubscription() {
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

        let channel = rest.channels.get("pushenabled:\(uniqueChannelName())")
        waitUntil(timeout: testTimeout) { done in
            channel.push.subscribeClient { error in
                expect(error).to(beNil())
                done()
            }
        }

        let params: [String: String] = [
            "clientId": options.clientId!,
            "channel": channel.name,
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
