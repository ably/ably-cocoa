import Ably
import Nimble
import Quick

        private var rest: ARTRest!
        private var mockHttpExecutor: MockHTTPExecutor!
        private var storage: MockDeviceStorage!
        private var stateMachineDelegate: StateMachineDelegate!

class Push : XCTestCase {

    struct TestDeviceToken {
        static let tokenBase64 = "HYRXxPSQdt1pnxqtDAvc6PTTLH7N6okiBhYyLClJdmQ="
        static let tokenData = Data(base64Encoded: tokenBase64, options: [])!
        static let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
    }

override class var defaultTestSuite : XCTestSuite {
    let _ = rest
    let _ = mockHttpExecutor
    let _ = storage
    let _ = stateMachineDelegate

    return super.defaultTestSuite
}


        func beforeEach() {
print("START HOOK: Push.beforeEach")

            rest = ARTRest(key: "xxxx:xxxx")
            rest.internal.resetDeviceSingleton()
            mockHttpExecutor = MockHTTPExecutor()
            rest.internal.httpExecutor = mockHttpExecutor
            storage = MockDeviceStorage()
            rest.internal.storage = storage
            stateMachineDelegate = StateMachineDelegate()
            rest.push.internal.createActivationStateMachine(withDelegate: stateMachineDelegate!)
print("END HOOK: Push.beforeEach")

        }

        // RSH2
        

            // RSH2a
            func test__001__activation__activate_method_should_send_a_CalledActivate_event_to_the_state_machine() {
beforeEach()

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
beforeEach()

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
beforeEach()

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
beforeEach()

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
beforeEach()

                let expectedClientId = "foo"
                let options = AblyTests.clientOptions()

                options.authCallback = { tokenParams, completion in
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
                        }
                        else if event is ARTPushActivationEventGotDeviceRegistration {
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
                case .failure(let error):
                    fail(error)
                case .success(let httpBody):
                    guard let requestedClientId = httpBody.unbox["clientId"] as? String else {
                        fail("No clientId field in HTTPBody"); return
                    }
                    expect(requestedClientId).to(equal(expectedClientId))
                }
            }

            // https://github.com/ably/ably-cocoa/issues/889
            func test__006__activation__should_store_the_device_token_data_as_string() {
beforeEach()

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
beforeEach()

                expect { ARTPush.didRegisterForRemoteNotifications(withDeviceToken: TestDeviceToken.tokenData, rest: rest) }.toNot(raiseException())
            }

        
            // RSH8
            func test__008__LocalDevice__has_a_device_method_that_returns_a_LocalDevice() {
beforeEach()

                let _: ARTLocalDevice = ARTRest(key: "fake:key").device
                let _: ARTLocalDevice = ARTRealtime(key: "fake:key").device
            }
            
            // RSH8a
            func test__009__LocalDevice__the_device_is_lazily_populated_from_the_persisted_state() {
beforeEach()

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

                let device = rest.device
                
                expect(device.apnsDeviceToken()).to(equal(testToken))
                expect(device.identityTokenDetails?.token).to(equal(testIdentity.token))
            }
            
            // RSH8d
            
                func test__012__LocalDevice__when_using_token_authentication__new_clientID_is_set() {
beforeEach()

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
beforeEach()

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
beforeEach()

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
                self.wait(for: [expectation], timeout: 3.0)

                expect(mockHttpExecutor.requests.filter({ $0.url?.pathComponents.contains("deviceRegistrations") == true })).to(haveCount(1))
                expect(realtime.device.clientId).to(equal(expectedClient))
            }

            // RSH8f
            func test__011__LocalDevice__sets_device_s_client_ID_from_registration_response() {
beforeEach()

                let expectedClientId = "testClientId"

                let stateMachineDelegate = StateMachineDelegateCustomCallbacks()
                stateMachineDelegate.onPushCustomRegisterIdentity = { _, _ in
                    return ARTDeviceIdentityTokenDetails(
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
beforeEach()

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
beforeEach()

                let options = AblyTests.commonAppSetup()
                options.key = "xxxx:xxxx"
                var pushRegistererDelegate: StateMachineDelegate? = StateMachineDelegate()
                options.pushRegistererDelegate = pushRegistererDelegate
                let rest = ARTRest(options: options)
                expect(rest.internal.options.pushRegistererDelegate).toNot(beNil())
                pushRegistererDelegate = nil
                expect(rest.internal.options.pushRegistererDelegate).to(beNil())
            }
}
