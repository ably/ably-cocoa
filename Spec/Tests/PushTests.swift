import Ably
import Nimble
import XCTest

private var rest: ARTRest!
private var mockHttpExecutor: MockHTTPExecutor!
private var storage: MockDeviceStorage!
private var stateMachineDelegate: StateMachineDelegate!
private var localDevice: ARTLocalDevice!

private let quxChannelName = "pushenabled:qux"

private let subscription = ARTPushChannelSubscription(clientId: "newClient", channel: quxChannelName)

class PushTests: XCTestCase {
    enum TestDeviceToken {
        static let tokenBase64 = "HYRXxPSQdt1pnxqtDAvc6PTTLH7N6okiBhYyLClJdmQ="
        static let tokenData = Data(base64Encoded: tokenBase64, options: [])!
        static let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
    }
    
    private static let deviceDetails: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "testDeviceDetails")
        deviceDetails.platform = "ios"
        deviceDetails.formFactor = "phone"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "apns",
            "deviceToken": "foo",
        ]
        return deviceDetails
    }()
    
    private static let failedDeviceDetails: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "testFailedDeviceDetails")
        deviceDetails.platform = "ios"
        deviceDetails.formFactor = "phone"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "apns"
        ]
        deviceDetails.push.errorReason = ARTErrorInfo(domain: ARTAblyErrorDomain, code: 0, userInfo: nil)
        deviceDetails.push.state = ARTPushState.failed
        return deviceDetails
    }()

    private static let deviceDetails1ClientA: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails1ClientA")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientA"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
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
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
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
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
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
    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = rest
        _ = mockHttpExecutor
        _ = storage
        _ = stateMachineDelegate
        _ = localDevice
        _ = quxChannelName
        _ = subscription

        return super.defaultTestSuite
    }

    override func setUp() {
        super.setUp()

        rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.resetDeviceSingleton()
        mockHttpExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHttpExecutor
        storage = MockDeviceStorage()
        rest.internal.storage = storage
        stateMachineDelegate = StateMachineDelegate()
        rest.push.internal.createActivationStateMachine(withDelegate: stateMachineDelegate!)
        localDevice = rest.device
    }
    
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
            rest.push.deviceRegistrations.save(device) { error in
                assert(error == nil, error?.message ?? "no message")
                if allDeviceDetails.last == device {
                    group.leave()
                }
            }
        }
        group.wait()

        group.enter()
        for subscription in allSubscriptions {
            rest.push.channelSubscriptions.save(subscription) { error in
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
            rest.push.deviceRegistrations.remove(device.id) { _ in
                group.leave()
            }
        }

        for subscription in allSubscriptions {
            group.enter()
            rest.push.channelSubscriptions.remove(subscription) { _ in
                group.leave()
            }
        }

        super.tearDown()
    }
    
    // RSH2

    // RSH2a
    func test__001__activation__activate_method_should_send_a_CalledActivate_event_to_the_state_machine() {
        defer { rest.push.internal.activationMachine.transitions = nil }
        waitUntil(timeout: testTimeout) { done in
            rest.push.internal.activationMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventCalledActivate {
                    done()
                }
            }
            rest.push.activate()
        }
    }

    // RSH2b
    func test__002__activation__deactivate_method_should_send_a_CalledDeactivate_event_to_the_state_machine() {
        defer { rest.push.internal.activationMachine.transitions = nil }
        waitUntil(timeout: testTimeout) { done in
            rest.push.internal.activationMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventCalledDeactivate {
                    done()
                }
            }
            rest.push.deactivate()
        }
    }

    // RSH2c / RSH8g
    func test__003__activation__should_handle_GotPushDeviceDetails_event_when_platform_s_APIs_sends_the_details_for_push_notifications() {
        let stateMachine = rest.push.internal.activationMachine
        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
        stateMachine.rest.device.setAndPersistAPNSDeviceToken(testDeviceToken)
        let stateMachineDelegate = StateMachineDelegate()
        stateMachine.delegate = stateMachineDelegate
        defer {
            stateMachine.transitions = nil
            stateMachine.delegate = nil
            stateMachine.rest.device.setAndPersistAPNSDeviceToken(nil)
        }
        waitUntil(timeout: testTimeout) { done in
            stateMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventGotPushDeviceDetails {
                    done()
                }
            }
            rest.push.activate()
        }
    }

    // RSH2d / RSH8h
    func test__004__activation__sends_GettingPushDeviceDetailsFailed_when_push_registration_fails() {
        let stateMachine = rest.push.internal.activationMachine
        defer { stateMachine.transitions = nil }
        waitUntil(timeout: testTimeout) { done in
            stateMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventGettingPushDeviceDetailsFailed {
                    done()
                }
            }
            rest.push.activate()

            let error = NSError(domain: ARTAblyErrorDomain, code: 42, userInfo: nil)
            ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, rest: rest)
        }
    }

    // https://github.com/ably/ably-cocoa/issues/877
    func test__005__activation__should_update_LocalDevice_clientId_when_it_s_null_with_auth_clientId() {
        let expectedClientId = "foo"
        let options = AblyTests.clientOptions()

        options.authCallback = { _, completion in
            getTestTokenDetails(clientId: expectedClientId, completion: { tokenDetails, error in
                expect(error).to(beNil())
                guard let tokenDetails = tokenDetails else {
                    fail("TokenDetails are missing"); return
                }
                expect(tokenDetails.clientId) == expectedClientId
                completion(tokenDetails, error)
            })
        }

        let rest = ARTRest(options: options)
        let mockHttpExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHttpExecutor
        let storage = MockDeviceStorage()
        rest.internal.storage = storage

        rest.internal.resetDeviceSingleton()

        var stateMachine: ARTPushActivationStateMachine!
        waitUntil(timeout: testTimeout) { done in
            rest.push.internal.getActivationMachine { machine in
                stateMachine = machine
                done()
            }
        }

        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
        stateMachine.rest.device.setAndPersistAPNSDeviceToken(testDeviceToken)
        let stateMachineDelegate = StateMachineDelegate()
        stateMachine.delegate = stateMachineDelegate
        defer {
            stateMachine.transitions = nil
            stateMachine.delegate = nil
            stateMachine.rest.device.setAndPersistAPNSDeviceToken(nil)
        }

        expect(rest.device.clientId).to(beNil())
        expect(rest.auth.clientId).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            stateMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventGotPushDeviceDetails {
                    partialDone()
                } else if event is ARTPushActivationEventGotDeviceRegistration {
                    stateMachine.transitions = nil
                    partialDone()
                }
            }
            rest.push.activate()
        }

        expect(rest.device.clientId) == expectedClientId
        expect(rest.auth.clientId) == expectedClientId

        let registerRequest = mockHttpExecutor.requests.filter { req in
            req.httpMethod == "POST" && req.url?.path == "/push/deviceRegistrations"
        }.first

        switch extractBodyAsMsgPack(registerRequest) {
        case let .failure(error):
            fail(error)
        case let .success(httpBody):
            guard let requestedClientId = httpBody.unbox["clientId"] as? String else {
                fail("No clientId field in HTTPBody"); return
            }
            expect(requestedClientId).to(equal(expectedClientId))
        }
    }

    // https://github.com/ably/ably-cocoa/issues/889
    func test__006__activation__should_store_the_device_token_data_as_string() {
        let expectedDeviceToken = TestDeviceToken.tokenString
        defer { rest.push.internal.activationMachine.transitions = nil }
        waitUntil(timeout: testTimeout) { done in
            rest.push.internal.activationMachine.onEvent = { event, _ in
                if event is ARTPushActivationEventGotPushDeviceDetails {
                    done()
                }
            }
            ARTPush.didRegisterForRemoteNotifications(withDeviceToken: TestDeviceToken.tokenData, rest: rest)
        }
        expect(storage.keysWritten.keys).to(contain(["ARTAPNSDeviceToken"]))
        expect(storage.keysWritten.at("ARTAPNSDeviceToken")?.value as? String).to(equal(expectedDeviceToken))
    }

    // https://github.com/ably/ably-cocoa/issues/888
    func test__007__activation__should_not_sync_the_local_device_dispatched_in_internal_queue() {
        expect { ARTPush.didRegisterForRemoteNotifications(withDeviceToken: TestDeviceToken.tokenData, rest: rest) }.toNot(raiseException())
    }

    // RSH8
    func test__008__LocalDevice__has_a_device_method_that_returns_a_LocalDevice() {
        let _: ARTLocalDevice = ARTRest(key: "fake:key").device
        let _: ARTLocalDevice = ARTRealtime(key: "fake:key").device
    }

    // RSH8a
    func test__009__LocalDevice__the_device_is_lazily_populated_from_the_persisted_state() {
        let testToken = "testDeviceToken"
        let testIdentity = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )

        let rest = ARTRest(key: "fake:key")
        rest.internal.storage = storage
        storage.simulateOnNextRead(string: testToken, for: ARTAPNSDeviceTokenKey)
        storage.simulateOnNextRead(data: testIdentity.archive(), for: ARTDeviceIdentityTokenKey)

        rest.internal.resetDeviceSingleton()
        
        let device = rest.device

        expect(device.apnsDeviceToken()).to(equal(testToken))
        expect(device.identityTokenDetails?.token).to(equal(testIdentity.token))
    }

    // RSH8d

    func test__012__LocalDevice__when_using_token_authentication__new_clientID_is_set() {
        let options = ARTClientOptions(key: "fake:key")
        options.autoConnect = false
        options.authCallback = { _, callback in
            delay(0.1) {
                callback(ARTTokenDetails(token: "fake:token", expires: nil, issued: nil, capability: nil, clientId: "testClient"), nil)
            }
        }

        let realtime = ARTRealtime(options: options)
        expect(realtime.device.clientId).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            realtime.auth.authorize { _, _ in
                done()
            }
        }

        expect(realtime.device.clientId).to(equal("testClient"))
    }

    // RSH8d

    func test__013__LocalDevice__when_getting_a_client_ID_from_CONNECTED_message__new_clientID_is_set() {
        let options = ARTClientOptions(key: "fake:key")
        options.autoConnect = false

        let realtime = ARTRealtime(options: options)
        expect(realtime.device.clientId).to(beNil())

        realtime.internal.setTransport(TestProxyTransport.self)

        waitUntil(timeout: testTimeout) { done in
            realtime.connection.once(.connected) { _ in
                done()
            }
            realtime.connect()

            let transport = realtime.internal.transport as! TestProxyTransport
            transport.actionsIgnored += [.error]
            transport.simulateTransportSuccess(clientId: "testClient")
        }

        expect(realtime.device.clientId).to(equal("testClient"))
    }

    // RSH8e
    func test__010__LocalDevice__authentication_on_registered_device_sends_a_GotPushDeviceDetails_with_new_clientID() {
        let testDeviceToken = "testDeviceToken"
        let testDeviceIdentity = ARTDeviceIdentityTokenDetails(
            token: "123456",
            issued: Date(),
            expires: Date.distantFuture,
            capability: "",
            clientId: ""
        )
        let expectedClient = "testClient"

        let options = ARTClientOptions(key: "fake:key")
        options.autoConnect = false
        options.authCallback = { _, callback in
            delay(0.1) {
                callback(ARTTokenDetails(token: "fake:token", expires: nil, issued: nil, capability: nil, clientId: expectedClient), nil)
            }
        }

        let realtime = ARTRealtime(options: options)
        let mockHttpExecutor = MockHTTPExecutor()
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let storage = MockDeviceStorage(
            startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(
                machine: ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
            )
        )
        realtime.internal.rest.storage = storage

        var stateMachine: ARTPushActivationStateMachine!
        waitUntil(timeout: testTimeout) { done in
            realtime.internal.rest.push.getActivationMachine { machine in
                stateMachine = machine
                done()
            }
        }
        let delegate = StateMachineDelegate()
        stateMachine.delegate = delegate

        storage.simulateOnNextRead(string: testDeviceToken, for: ARTAPNSDeviceTokenKey)
        storage.simulateOnNextRead(data: testDeviceIdentity.archive(), for: ARTDeviceIdentityTokenKey)

        expect(realtime.device.clientId).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            stateMachine.transitions = { event, _, _ in
                if event is ARTPushActivationEventGotPushDeviceDetails {
                    done()
                }
            }
            realtime.auth.authorize { _, _ in }
        }

        expect(realtime.device.clientId).to(equal(expectedClient))

        let expectation = XCTestExpectation(description: "Consecutive Authorization")
        expectation.isInverted = true
        stateMachine.transitions = { event, _, _ in
            if event is ARTPushActivationEventGotPushDeviceDetails {
                fail("GotPushDeviceDetails should only be emitted when clientId is different from the present identified client")
            }
        }
        realtime.auth.authorize { _, _ in }
        wait(for: [expectation], timeout: 3.0)

        expect(mockHttpExecutor.requests.filter { $0.url?.pathComponents.contains("deviceRegistrations") == true }).to(haveCount(1))
        expect(realtime.device.clientId).to(equal(expectedClient))
    }

    // RSH8f
    func test__011__LocalDevice__sets_device_s_client_ID_from_registration_response() {
        let expectedClientId = "testClientId"

        let stateMachineDelegate = StateMachineDelegateCustomCallbacks()
        stateMachineDelegate.onPushCustomRegisterIdentity = { _, _ in
            ARTDeviceIdentityTokenDetails(
                token: "123456",
                issued: Date(),
                expires: Date.distantFuture,
                capability: "",
                clientId: expectedClientId
            )
        }
        rest.push.internal.activationMachine.delegate = stateMachineDelegate

        expect(rest.device.clientId).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            stateMachineDelegate.onDidActivateAblyPush = { _ in
                done()
            }

            rest.push.activate()

            ARTPush.didRegisterForRemoteNotifications(withDeviceToken: "testDeviceToken".data(using: .utf8)!, rest: rest)
        }

        expect(rest.device.clientId).to(equal(expectedClientId))
    }

    func test__014__Registerer_Delegate_option__a_successful_activation_should_call_the_correct_registerer_delegate_method() {
        let options = AblyTests.commonAppSetup()
        options.key = "xxxx:xxxx"
        let pushRegistererDelegate = StateMachineDelegate()
        options.pushRegistererDelegate = pushRegistererDelegate
        let rest = ARTRest(options: options)
        waitUntil(timeout: testTimeout) { done in
            pushRegistererDelegate.onDidActivateAblyPush = { _ in
                done()
            }
            pushRegistererDelegate.onDidDeactivateAblyPush = { _ in
                fail("should not be called")
            }
            rest.push.activate()
            ARTPush.didRegisterForRemoteNotifications(withDeviceToken: TestDeviceToken.tokenData, rest: rest)
        }
    }

    func test__015__Registerer_Delegate_option__registerer_delegate_should_not_hold_a_strong_instance_reference() {
        let options = AblyTests.commonAppSetup()
        options.key = "xxxx:xxxx"
        var pushRegistererDelegate: StateMachineDelegate? = StateMachineDelegate()
        options.pushRegistererDelegate = pushRegistererDelegate
        let rest = ARTRest(options: options)
        expect(rest.internal.options.pushRegistererDelegate).toNot(beNil())
        pushRegistererDelegate = nil
        expect(rest.internal.options.pushRegistererDelegate).to(beNil())
    }
    
    // RSH1b1

    func test__006__Device_Registrations__get__should_return_a_device() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.get("testDeviceDetails") { device, error in
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
            realtime.push.deviceRegistrations.get("madeup") { device, error in
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

    func test__007__Device_Registrations__get__should_return_failed_device_with_error_info_and_with_a_state_equal_to_failed() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.get("testFailedDeviceDetails") { device, error in
                guard let device = device else {
                    fail("Device is missing"); done(); return
                }
                expect(device).to(equal(Self.failedDeviceDetails))
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__008__Device_Registrations__get__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() {
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
            realtime.push.deviceRegistrations.get(localDevice.id) { _, _ in
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__009__Device_Registrations__get__push_device_authentication__should_include_DeviceSecret_HTTP_header() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.get(localDevice.id) { _, _ in
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1b2

    func test__010__Device_Registrations__list__should_list_devices_by_id() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.list(["deviceId": "testDeviceDetails"]) { result, error in
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
            realtime.push.deviceRegistrations.list(["clientId": "clientA"]) { result, error in
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
            realtime.push.deviceRegistrations.list(["direction": "forwards"]) { result, error in
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
            realtime.push.deviceRegistrations.list(["deviceId": "madeup"]) { result, error in
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

    func test__014__Device_Registrations__remove__should_unregister_a_device() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor
        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.remove(Self.deviceDetails.id) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        expect(request.httpMethod) == "DELETE"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    // RSH1b3

    func test__015__Device_Registrations__save__should_register_a_device() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor
        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.save(Self.deviceDetails) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        expect(request.httpMethod) == "PUT"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    func test__016__Device_Registrations__save__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() {
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
            realtime.push.deviceRegistrations.save(localDevice) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }
        expect(request.httpMethod).to(equal("PUT"))

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__017__Device_Registrations__save__push_device_authentication__should_include_DeviceSecret_HTTP_header() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.save(localDevice) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }
        expect(request.httpMethod).to(equal("PUT"))

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1b5

    func test__018__Device_Registrations__removeWhere__should_unregister_a_device() {
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let params = [
            "clientId": "clientA",
        ]

        let expectedRemoved = Self.allDeviceDetails.filter { $0.clientId == "clientA" }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.list(params) { result, error in
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
            realtime.push.deviceRegistrations.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        expect(request.httpMethod) == "DELETE"
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            realtime.push.deviceRegistrations.list(params) { result, error in
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
                realtime.push.deviceRegistrations.save(removedDevice) { error in
                    expect(error).to(beNil())
                    partialDone()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            realtime.push.channelSubscriptions.save(Self.subscriptionFooDevice2) { error in
                expect(error).to(beNil())
                partialDone()
            }
            realtime.push.channelSubscriptions.save(Self.subscriptionBarDevice2) { error in
                expect(error).to(beNil())
                partialDone()
            }
        }
    }

    // RSH1c3

    func test__019__Channel_Subscriptions__save__should_add_a_subscription() {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let testProxyHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
        realtime.internal.rest.httpExecutor = testProxyHTTPExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = testProxyHTTPExecutor.requests.first else {
            fail("No requests found")
            return
        }

        expect(request.httpMethod).to(equal("POST"))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
    }

    func test__020__Channel_Subscriptions__save__should_update_a_subscription() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let updateSubscription = ARTPushChannelSubscription(clientId: subscription.clientId!, channel: "pushenabled:foo")
        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.save(updateSubscription) { error in
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
            realtime.push.channelSubscriptions.save(invalidSubscription) { error in
                guard let error = error else {
                    fail("Error is nil"); done(); return
                }
                expect(error.statusCode) == 400
                expect(error.message).to(contain("device madeup doesn't exist"))
                done()
            }
        }
    }

    func test__022__Channel_Subscriptions__save__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() {
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
            realtime.push.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__023__Channel_Subscriptions__save__push_device_authentication__should_include_DeviceSecret_HTTP_header() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
        expect(authorization).to(equal(localDevice.secret))
    }

    // RSH1c1

    func test__024__Channel_Subscriptions__list__should_receive_a_list_of_subscriptions() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.save(subscription) { error in
                expect(error).to(beNil())
                realtime.push.channelSubscriptions.list(["channel": quxChannelName]) { result, error in
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
            realtime.push.channelSubscriptions.listChannels { result, error in
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

    func test__026__Channel_Subscriptions__remove__should_remove_a_subscription() {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let testProxyHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
        realtime.internal.rest.httpExecutor = testProxyHTTPExecutor

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = testProxyHTTPExecutor.requests.first else {
            fail("No requests found")
            return
        }

        expect(request.httpMethod).to(equal("DELETE"))
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceToken"]).to(beNil())
        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.list(["channel": quxChannelName]) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }
    }

    func test__027__Channel_Subscriptions__remove__push_device_authentication__should_include_DeviceIdentityToken_HTTP_header() {
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
            realtime.push.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
    }

    func test__028__Channel_Subscriptions__remove__push_device_authentication__should_include_DeviceSecret_HTTP_header() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        realtime.internal.rest.httpExecutor = mockHttpExecutor

        let subscription = ARTPushChannelSubscription(deviceId: localDevice.id, channel: quxChannelName)

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.remove(subscription) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("No requests found")
            return
        }

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
            realtime.push.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.list(params) { result, error in
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
                realtime.push.channelSubscriptions.save(removedSubscription) { error in
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
            realtime.push.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.list(params) { result, error in
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
            realtime.push.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items).to(contain(expectedRemoved))
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.removeWhere(params) { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.list(params) { result, error in
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
            realtime.push.channelSubscriptions.list(params) { result, error in
                guard let result = result else {
                    fail("PaginatedResult should not be empty"); done(); return
                }
                expect(result.items.count) == 0
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            realtime.push.channelSubscriptions.removeWhere(params) { error in
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
