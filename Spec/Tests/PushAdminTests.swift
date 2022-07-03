import Ably
import Nimble
import XCTest

private var rest: ARTRest!
private var mockHttpExecutor: MockHTTPExecutor!
private var storage: MockDeviceStorage!
private var localDevice: ARTLocalDevice!

private let recipient = [
    "clientId": "bob",
]

private let payload = [
    "notification": [
        "title": "Welcome",
    ],
]

private let quxChannelName = "pushenabled:qux"

private let subscription = ARTPushChannelSubscription(clientId: "newClient", channel: quxChannelName)

class PushAdminTests: XCTestCase {
    private static let deviceDetails: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "testDeviceDetails")
        deviceDetails.platform = "ios"
        deviceDetails.formFactor = "phone"
        deviceDetails.metadata = [String : String]()
        deviceDetails.pushRecipient = [
            "transportType": "apns",
            "deviceToken": "foo",
        ]
        return deviceDetails
    }()

    private static let deviceDetails1ClientA: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails1ClientA")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientA"
        deviceDetails.metadata = [String : String]()
        deviceDetails.pushRecipient = [
            "transportType": "gcm",
            "registrationToken": "qux",
        ]
        return deviceDetails
    }()

    private static let deviceDetails2ClientA: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails2ClientA")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientA"
        deviceDetails.metadata = [String : String]()
        deviceDetails.pushRecipient = [
            "transportType": "gcm",
            "registrationToken": "qux",
        ]
        return deviceDetails
    }()

    private static let deviceDetails3ClientB: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails3ClientB")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientB"
        deviceDetails.metadata = [String : String]()
        deviceDetails.pushRecipient = [
            "transportType": "gcm",
            "registrationToken": "qux",
        ]
        return deviceDetails
    }()

    private static let allDeviceDetails: [ARTDeviceDetails] = [
        deviceDetails,
        deviceDetails1ClientA,
        deviceDetails2ClientA,
        deviceDetails3ClientB,
    ]

    private static let subscriptionFooDevice1 = ARTPushChannelSubscription(deviceId: "deviceDetails1ClientA", channel: "pushenabled:foo")
    private static let subscriptionFooDevice2 = ARTPushChannelSubscription(deviceId: "deviceDetails2ClientA", channel: "pushenabled:foo")
    private static let subscriptionBarDevice2 = ARTPushChannelSubscription(deviceId: "deviceDetails2ClientA", channel: "pushenabled:bar")
    private static let subscriptionFooClientA = ARTPushChannelSubscription(clientId: "clientA", channel: "pushenabled:foo")
    private static let subscriptionFooClientB = ARTPushChannelSubscription(clientId: "clientB", channel: "pushenabled:foo")
    private static let subscriptionBarClientB = ARTPushChannelSubscription(clientId: "clientB", channel: "pushenabled:bar")

    private static let allSubscriptions: [ARTPushChannelSubscription] = [
        subscriptionFooDevice1,
        subscriptionFooDevice2,
        subscriptionBarDevice2,
        subscriptionFooClientA,
        subscriptionFooClientB,
        subscriptionBarClientB,
    ]

    private static let allSubscriptionsChannels: [String] = {
        var seen = Set<String>()
        return allSubscriptions.filter { seen.insert($0.channel).inserted }.map { $0.channel }
    }()

    override class func setUp() {
        super.setUp()
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        options.dispatchQueue = AblyTests.userQueue
        let rest = ARTRest(options: options)
        rest.internal.storage = MockDeviceStorage()
        let group = DispatchGroup()

        group.enter()
        for device in allDeviceDetails {
            rest.push.admin.deviceRegistrations.save(device) { error in
                assert(error == nil, error?.message ?? "no message")
                if allDeviceDetails.last == device {
                    group.leave()
                }
            }
        }
        group.wait()

        group.enter()
        for subscription in allSubscriptions {
            rest.push.admin.channelSubscriptions.save(subscription) { error in
                assert(error == nil, error?.message ?? "no message")
                if allSubscriptions.last == subscription {
                    group.leave()
                }
            }
        }

        group.wait()
    }

    override class func tearDown() {
        let options = AblyTests.commonAppSetup()
        options.dispatchQueue = AblyTests.userQueue
        let rest = ARTRest(options: options)
        rest.internal.storage = MockDeviceStorage()
        let group = DispatchGroup()

        for device in allDeviceDetails {
            group.enter()
            rest.push.admin.deviceRegistrations.remove(device.id) { _ in
                group.leave()
            }
        }

        for subscription in allSubscriptions {
            group.enter()
            rest.push.admin.channelSubscriptions.remove(subscription) { _ in
                group.leave()
            }
        }

        super.tearDown()
    }

    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = rest
        _ = mockHttpExecutor
        _ = storage
        _ = localDevice
        _ = recipient
        _ = payload
        _ = quxChannelName
        _ = subscription

        return super.defaultTestSuite
    }

    override func setUp() {
        super.setUp()

        rest = ARTRest(key: "xxxx:xxxx")
        mockHttpExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHttpExecutor
        storage = MockDeviceStorage()
        rest.internal.storage = storage
        localDevice = rest.device
    }

    // RSH1a

    func test__001__publish__should_perform_an_HTTP_request_to__push_publish() throws {
        waitUntil(timeout: testTimeout) { done in
            rest.push.admin.publish(recipient, data: payload) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let url = try XCTUnwrap(request.url, "No request url found")

        expect(url.absoluteString).to(contain("/push/publish"))

        switch extractBodyAsMsgPack(request) {
        case let .failure(error):
            XCTFail(error)
        case let .success(httpBody):
            guard let bodyRecipient = httpBody.unbox["recipient"] as? [String: String] else {
                fail("recipient is missing"); return
            }
            expect(bodyRecipient).to(equal(recipient))

            guard let bodyPayload = httpBody.unbox["notification"] as? [String: String] else {
                fail("notification is missing"); return
            }
            expect(bodyPayload).to(equal(payload["notification"]))
        }
    }

    func skipped__test__002__publish__should_publish_successfully() {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:\(uniqueChannelName())") // works with pure uniqueChannelName() as well
        let publishObject = ["transportType": "ablyChannel",
                             "channel": channel.name,
                             "ablyKey": options.key!,
                             "ablyUrl": "https://\(options.restHost)"]

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.subscribe("__ably_push__") { message in
                guard let data = message.data as? String else {
                    fail("Failure in reading returned data"); partialDone(); return
                }
                expect(data).to(contain("foo"))
                partialDone()
            }
            realtime.push.admin.publish(publishObject, data: ["data": ["foo": "bar"]]) { error in
                expect(error).to(beNil())
                partialDone()
            }
        }
    }

    func skipped__test__003__publish__should_fail_with_a_bad_recipient() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:\(uniqueChannelName())") // works with pure uniqueChannelName() as well

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish(["foo": "bar"], data: ["data": ["foo": "bar"]]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.statusCode) == 400
                expect(error.message).to(contain("recipient must contain"))
                done()
            }
        }
    }

    func skipped__test__004__publish__should_fail_with_an_empty_recipient() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:\(uniqueChannelName())") // works with pure uniqueChannelName() as well

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish([:], data: ["data": ["foo": "bar"]]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.message.lowercased()).to(contain("recipient is missing"))
                done()
            }
        }
    }

    func test__005__publish__should_fail_with_an_empty_payload() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:\(uniqueChannelName())") // works with pure uniqueChannelName() as well

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish(["ablyChannel": channel.name], data: [:]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.message.lowercased()).to(contain("data payload is missing"))
                done()
            }
        }
    }

    // RSH1b1

    func test__006__Device_Registrations__get__should_return_a_device() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.get("testDeviceDetails") { device, error in
                guard let device = device else {
                    fail("Device is missing"); done(); return
                }
                expect(device).to(equal(Self.deviceDetails))
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__007__Device_Registrations__get__should_not_return_a_device_if_it_doesnt_exist() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.get("madeup") { device, error in
                expect(device).to(beNil())
                guard let error = error else {
                    fail("Error should not be empty"); done(); return
                }
                expect(error.statusCode) == 404
                expect(error.message).to(contain("not found"))
                done()
            }
        }
    }

    func test__008__Device_Registrations__get__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )

        expect(localDevice.identityTokenDetails).to(beNil())
        realtime.internal.rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { realtime.internal.rest.device.setAndPersistIdentityTokenDetails(nil) }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.get(localDevice.id) { _, _ in
                done()
            }
        }
        
        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__009__Device_Registrations__get__push_device_authentication__should_include_DeviceSecret_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.get(localDevice.id) { _, _ in
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1b2

    func test__010__Device_Registrations__list__should_list_devices_by_id() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(["deviceId": "testDeviceDetails"]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 1
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__011__Device_Registrations__list__should_list_devices_by_client_id() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(["clientId": "clientA"]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == Self.allDeviceDetails.filter { $0.clientId == "clientA" }.count
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__012__Device_Registrations__list__should_list_devices_sorted() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(["direction": "forwards"]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == Self.allDeviceDetails.count
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__013__Device_Registrations__list__should_return_an_empty_list_when_id_does_not_exist() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(["deviceId": "madeup"]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }
    }

    // RSH1b4

    func test__014__Device_Registrations__remove__should_unregister_a_device() throws {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.remove(Self.deviceDetails.id) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")

        expect(request.httpMethod) == "DELETE"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    // RSH1b3

    func test__015__Device_Registrations__save__should_register_a_device() throws {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.save(Self.deviceDetails) { error in
                expect(error).to(beNil())
                done()
            }
        }
        
        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")

        expect(request.httpMethod) == "PUT"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    func test__016__Device_Registrations__save__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() throws {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )

        expect(localDevice.identityTokenDetails).to(beNil())
        realtime.internal.rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { realtime.internal.rest.device.setAndPersistIdentityTokenDetails(nil) }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.save(localDevice) { error in
                expect(error).to(beNil())
                done()
            }
        }
        
        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        
        expect(request.httpMethod).to(equal("PUT"))
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__017__Device_Registrations__save__push_device_authentication__should_include_DeviceSecret_HTTP_header() throws {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.save(localDevice) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        
        expect(request.httpMethod).to(equal("PUT"))
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1b5

    func test__018__Device_Registrations__removeWhere__should_unregister_a_device() throws {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "clientId": "clientA",
        ]

        let expectedRemoved = Self.allDeviceDetails.filter { $0.clientId == "clientA" }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be nil"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        realtime.internal.rest.httpExecutor = mockHttpExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }
        
        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")

        expect(request.httpMethod) == "DELETE"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.deviceRegistrations.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be nil"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }

        // --- Restore state for next tests ---

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(expectedRemoved.count, done: done)
            for removedDevice in expectedRemoved {
                realtime.push.admin.deviceRegistrations.save(removedDevice) { error in
                    expect(error).to(beNil())
                    partialDone()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            realtime.push.admin.channelSubscriptions.save(Self.subscriptionFooDevice2) { error in
                expect(error).to(beNil())
                partialDone()
            }
            realtime.push.admin.channelSubscriptions.save(Self.subscriptionBarDevice2) { error in
                expect(error).to(beNil())
                partialDone()
            }
        }
    }

    // RSH1c3

    func test__019__Channel_Subscriptions__save__should_add_a_subscription() throws {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let testProxyHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
        realtime.internal.rest.httpExecutor = testProxyHTTPExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(testProxyHTTPExecutor.requests.first, "No request found")

        expect(request.httpMethod).to(equal("POST"))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    func test__020__Channel_Subscriptions__save__should_update_a_subscription() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let updateSubscription = ARTPushChannelSubscription(clientId: subscription.clientId!, channel: "pushenabled:foo")
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(updateSubscription) { error in
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__021__Channel_Subscriptions__save__should_fail_with_a_bad_recipient() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let invalidSubscription = ARTPushChannelSubscription(deviceId: "madeup", channel: "pushenabled:foo")
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(invalidSubscription) { error in
                guard let error = error else {
                    fail("Error is nil"); done(); return
                }
                expect(error.statusCode) == 400
                expect(error.message).to(contain("device madeup doesn't exist"))
                done()
            }
        }
    }

    func test__022__Channel_Subscriptions__save__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )

        expect(localDevice.identityTokenDetails).to(beNil())
        realtime.internal.rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { realtime.internal.rest.device.setAndPersistIdentityTokenDetails(nil) }

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__023__Channel_Subscriptions__save__push_device_authentication__should_include_DeviceSecret_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1c1

    func test__024__Channel_Subscriptions__list__should_receive_a_list_of_subscriptions() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                realtime.push.admin.channelSubscriptions.list(["channel": quxChannelName]) { result, error in
                    guard let result = result else {
                        fail("PaginatedResult should not be empty"); done(); return
                    }
                    expect(result.items.count) == 1
                    expect(error).to(beNil())
                    done()
                }
            }
        }
    }

    // RSH1c2

    func test__025__Channel_Subscriptions__listChannels__should_receive_a_list_of_subscriptions() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.listChannels { result, error in
                expect(error).to(beNil())
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items as [String]).to(contain(Self.allSubscriptionsChannels + [subscription.channel]))
                done()
            }
        }
    }

    // RSH1c4

    func test__026__Channel_Subscriptions__remove__should_remove_a_subscription() throws {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let testProxyHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
        realtime.internal.rest.httpExecutor = testProxyHTTPExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(testProxyHTTPExecutor.requests.first, "No request found")
        
        expect(request.httpMethod).to(equal("DELETE"))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(["channel": quxChannelName]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__027__Channel_Subscriptions__remove__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )

        expect(localDevice.identityTokenDetails).to(beNil())
        realtime.internal.rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
        defer { realtime.internal.rest.device.setAndPersistIdentityTokenDetails(nil) }

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__028__Channel_Subscriptions__remove__push_device_authentication__should_include_DeviceSecret_HTTP_header() throws {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        let request = try XCTUnwrap(mockHttpExecutor.requests.first, "No request found")
        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1c5

    func test__029__Channel_Subscriptions__removeWhere__should_remove_by_cliendId() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "clientId": "clientB",
        ]

        let expectedRemoved = [
            Self.subscriptionFooClientB,
            Self.subscriptionBarClientB,
        ]

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(expectedRemoved.count, done: done)
            for removedSubscription in expectedRemoved {
                realtime.push.admin.channelSubscriptions.save(removedSubscription) { error in
                    expect(error).to(beNil())
                    partialDone()
                }
            }
        }
    }

    func test__030__Channel_Subscriptions__removeWhere__should_remove_by_cliendId_and_channel() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "clientId": "clientB",
            "channel": "pushenabled:foo",
        ]

        let expectedRemoved = [
            Self.subscriptionFooClientB,
        ]

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__031__Channel_Subscriptions__removeWhere__should_remove_by_deviceId() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "deviceId": "deviceDetails2ClientA",
        ]

        let expectedRemoved = [
            Self.subscriptionFooDevice2,
            Self.subscriptionBarDevice2,
        ]

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__032__Channel_Subscriptions__removeWhere__should_not_remove_by_inexistent_deviceId() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "deviceId": "madeup",
        ]

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__033__local_device__should_include_an_id_and_a_secret() {
        expect(localDevice.id).toNot(beNil())
        expect(localDevice.secret).toNot(beNil())
        expect(localDevice.identityTokenDetails).to(beNil())
    }
}
