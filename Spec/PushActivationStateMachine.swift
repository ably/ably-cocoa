import Ably
import Nimble
import Quick

        private var rest: ARTRest!
        private var httpExecutor: MockHTTPExecutor!
        private var storage: MockDeviceStorage!
        private var initialStateMachine: ARTPushActivationStateMachine!

        private let expectedFormFactor = "phone"
        private let expectedPlatform = "ios"
        private let expectedPushRecipient: [String: [String: String]] = ["recipient": ["transportType": "apns"]]

        private var stateMachine: ARTPushActivationStateMachine!

class PushActivationStateMachine : XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = rest
    let _ = httpExecutor
    let _ = storage
    let _ = initialStateMachine
    let _ = expectedFormFactor
    let _ = expectedPlatform
    let _ = expectedPushRecipient
    let _ = stateMachine

    return super.defaultTestSuite
}


        func beforeEach() {
print("START HOOK: PushActivationStateMachine.beforeEach")

            rest = ARTRest(key: "xxxx:xxxx")
            httpExecutor = MockHTTPExecutor()
            rest.internal.httpExecutor = httpExecutor
            storage = MockDeviceStorage()
            rest.internal.storage = storage
            initialStateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach")

        }

        func afterEach() {
print("START HOOK: PushActivationStateMachine.afterEach")

           rest.internal.resetDeviceSingleton()
print("END HOOK: PushActivationStateMachine.afterEach")

        }

        

            func test__002__Activation_state_machine__should_set_NotActivated_state_as_current_state_when_disk_is_empty() {
beforeEach()

                expect(initialStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
afterEach()

            }

            func test__003__Activation_state_machine__should_read_the_current_state_from_disk() {
beforeEach()

                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                expect(storage.keysRead).to(haveCount(2))
                expect(storage.keysRead.filter({ $0.hasSuffix("CurrentState") })).to(haveCount(1))
                expect(storage.keysWritten).to(beEmpty())
afterEach()

            }

            func test__004__Activation_state_machine__AfterRegistrationUpdateFailed_state_from_persistence_gets_migrated_to_AfterRegistrationSyncFailed() {
beforeEach()

                let stateEncodedFromOldVersionBase64 = "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwPVSRudWxs0Q0OViRjbGFzc4AC0hAREhNaJGNsYXNzbmFtZVgkY2xhc3Nlc18QM0FSVFB1c2hBY3RpdmF0aW9uU3RhdGVBZnRlclJlZ2lzdHJhdGlvblVwZGF0ZUZhaWxlZKQUFRYXXxAzQVJUUHVzaEFjdGl2YXRpb25TdGF0ZUFmdGVyUmVnaXN0cmF0aW9uVXBkYXRlRmFpbGVkXxAgQVJUUHVzaEFjdGl2YXRpb25QZXJzaXN0ZW50U3RhdGVfEBZBUlRQdXNoQWN0aXZhdGlvblN0YXRlWE5TT2JqZWN0AAgAEQAaACQAKQAyADcASQBMAFEAUwBXAF0AYABnAGkAbgB5AIIAuAC9APMBFgEvAAAAAAAAAgEAAAAAAAAAGAAAAAAAAAAAAAAAAAAAATg="
                let stateEncodedFromOldVersion = Data.init(base64Encoded: stateEncodedFromOldVersionBase64, options: .init())!

                let storage = MockDeviceStorage()
                storage.simulateOnNextRead(data: stateEncodedFromOldVersion, for: ARTPushActivationCurrentStateKey)
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
afterEach()

            }

            // RSH3a
            

                func beforeEach__Activation_state_machine__State_NotActivated() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_NotActivated")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateNotActivated(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_NotActivated")

                }

                // RSH3a1
                func test__007__Activation_state_machine__State_NotActivated__on_Event_CalledDeactivate__should_transition_to_NotActivated() {
beforeEach__Activation_state_machine__State_NotActivated()

                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledDeactivate())

                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
afterEach()

                }

                // RSH3a2
                
                    // RSH3a2a
                    func test__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: TestCase_ReusableTestsRsh3a2a) {
                    // RSH3a2a
                    reusableTestsRsh3a2a(testCase: testCase, context: (beforeEach: beforeEach__Activation_state_machine__State_NotActivated, afterEach: afterEach))}
func test__011__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match() {
test__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match)
}

func test__012__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync)
}

func test__013__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync)
}


                    // RSH3a2b
                    
                        func test__014__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__local_device__should_have_a_generated_id() {
beforeEach__Activation_state_machine__State_NotActivated()

                            rest.internal.resetDeviceSingleton()
                            expect(rest.device.id.count) == 36
afterEach()

                        }
                        func test__015__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__local_device__should_have_a_generated_secret() {
beforeEach__Activation_state_machine__State_NotActivated()

                            guard let deviceSecret = rest.device.secret else {
                                fail("Device Secret should be available because it's loaded when the getter of the property is called"); return
                            }
                            guard let data = Data(base64Encoded: deviceSecret) else {
                                fail("Device Secret should be encoded with Base64"); return
                            }
                            expect(data.count) == 32 
afterEach()
//32 bytes digest
                        }

                        // RSH8b
                        func test__016__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__local_device__should_have_a_clientID_if_the_client_is_identified() {
beforeEach__Activation_state_machine__State_NotActivated()

                            let options = ARTClientOptions(key: "xxxx:xxxx")
                            options.clientId = "deviceClient"
                            let rest = ARTRest(options: options)
                            rest.internal.storage = storage
                            expect(rest.device.clientId).to(equal("deviceClient"))
afterEach()

                        }

                    // RSH3a2c
                    func test__009__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__if_the_local_device_has_the_necessary_push_details_should_send_event_GotPushDeviceDetails() {
beforeEach__Activation_state_machine__State_NotActivated()

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                        stateMachine.rest.device.setAndPersistAPNSDeviceToken(testDeviceToken)
                        defer { stateMachine.rest.device.setAndPersistAPNSDeviceToken(nil) }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, _, _ in
                                if event is ARTPushActivationEventCalledActivate {
                                    partialDone()
                                }
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }
afterEach()

                    }

                    // RSH3a2d
                    func test__010__Activation_state_machine__State_NotActivated__on_Event_CalledActivate__none_of_them_then_should_transition_to_WaitingForPushDeviceDetails() {
beforeEach__Activation_state_machine__State_NotActivated()

                        stateMachine.send(ARTPushActivationEventCalledActivate())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
afterEach()

                    }

                // RSH3a3
                func test__008__Activation_state_machine__State_NotActivated__on_Event_GotPushDeviceDetails() {
beforeEach__Activation_state_machine__State_NotActivated()

                    stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
afterEach()

                }

            // RSH3b
            

                func beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForPushDeviceDetails(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails")

                }

                // RSH3b1
                func test__017__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_CalledActivate() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
afterEach()

                }

                // RSH3b2
                func test__018__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_CalledDeactivate() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
afterEach()

                }

                // RSH3b3
                

                    // TODO: The exception is raised but the `send:` method is doing an async call and the `expect` doesn't catch it
                    func skipped__test__021__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_raise_exception_if_ARTPushRegistererDelegate_is_not_implemented() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
                        expect {
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }.to(raiseException { exception in
                            expect(exception.reason).to(contain("ARTPushRegistererDelegate must be implemented"))
                        })
afterEach()

                    }

                    // RSH3b3a, RSH3b3c
                    func test__022__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_use_custom_registerCallback_and_fire_GotDeviceRegistration_event() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventGotDeviceRegistration {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomRegister = { error, deviceDetails in
                                expect(error).to(beNil())
                                expect(deviceDetails).to(beIdenticalTo(rest.device))
                                partialDone()
                                return nil
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 0
afterEach()

                    }

                    // RSH3b3c
                    func test__023__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_use_custom_registerCallback_and_fire_GettingDeviceRegistrationFailed_event() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(3, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                                    partialDone()
                                }
                                else if let event = event as? ARTPushActivationEventGettingDeviceRegistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomRegister = { error, deviceDetails in
                                expect(error).to(beNil())
                                expect(deviceDetails).to(beIdenticalTo(rest.device))
                                partialDone()
                                return simulatedError
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 0
afterEach()

                    }

                    // RSH3b3b, RSH3b3c
                    func test__024__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_fire_GotDeviceRegistration_event() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        var setAndPersistIdentityTokenDetailsCalled = false
                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            setAndPersistIdentityTokenDetailsCalled = true
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventGotDeviceRegistration {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.url else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        guard let rawBody = request.httpBody else {
                            fail("should have a body"); return
                        }
                        let decodedBody: Any
                        do {
                            decodedBody = try stateMachine.rest.defaultEncoder.decode(rawBody)
                        }
                        catch {
                            fail("Decode failed: \(error)"); return
                        }
                        guard let body = decodedBody as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(url.host).to(equal(rest.internal.options.restUrl().host))
                        expect(request.httpMethod) == "POST"
                        expect(body.value(forKey: "id") as? String).to(equal(rest.device.id))
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(expectedPushRecipient))
                        expect(body.value(forKey: "formFactor") as? String) == expectedFormFactor
                        expect(body.value(forKey: "platform") as? String) == expectedPlatform
afterEach()

                    }

                    // RSH3b3c
                    func test__025__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_fire_GettingDeviceRegistrationFailed_event() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                                    partialDone()
                                }
                                else if let event = event as? ARTPushActivationEventGettingDeviceRegistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard request.url != nil else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        guard let rawBody = request.httpBody else {
                            fail("should have a body"); return
                        }
                        let decodedBody: Any
                        do {
                            decodedBody = try stateMachine.rest.defaultEncoder.decode(rawBody)
                        }
                        catch {
                            fail("Decode failed: \(error)"); return
                        }
                        guard let body = decodedBody as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(body.value(forKey: "id") as? String).to(equal(rest.device.id))
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(expectedPushRecipient))
                        expect(body.value(forKey: "formFactor") as? String) == expectedFormFactor
                        expect(body.value(forKey: "platform") as? String) == expectedPlatform
afterEach()

                    }

                    // RSH3b3d
                    func test__026__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GotPushDeviceDetails__should_transition_to_WaitingForDeviceRegistration() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        var setAndPersistIdentityTokenDetailsCalled = false
                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            setAndPersistIdentityTokenDetailsCalled = true
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventGotDeviceRegistration {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
afterEach()

                    }
                
                // RSH3b4
                func test__019__Activation_state_machine__State_WaitingForPushDeviceDetails__on_Event_GettingPushDeviceDetailsFailed() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                    let expectedError = ARTErrorInfo(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)

                    let delegate = StateMachineDelegate()
                    stateMachine.delegate = delegate
                    
                    waitUntil(timeout: testTimeout) { done in
                        delegate.onDidActivateAblyPush = { error in
                            expect(error).to(equal(expectedError))
                            done()
                        }
                        stateMachine.send(ARTPushActivationEventGettingPushDeviceDetailsFailed(error: expectedError))
                    }

                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
afterEach()

                }
                
                // https://github.com/ably/ably-cocoa/issues/966
                func test__020__Activation_state_machine__State_WaitingForPushDeviceDetails__when_initializing_from_persistent_state_with_a_deviceToken__GotPushDeviceDetails_should_be_re_emitted() {
beforeEach__Activation_state_machine__State_WaitingForPushDeviceDetails()

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForPushDeviceDetails(machine: initialStateMachine))
                    rest.internal.storage = storage
                    rest.device.setAndPersistAPNSDeviceToken("foo")
                    defer { rest.device.setAndPersistAPNSDeviceToken(nil) }
                    
                    var registered = false

                    let delegate = StateMachineDelegateCustomCallbacks()
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: delegate)
                    delegate.onPushCustomRegister = { error, deviceDetails in
                        registered = true
                        return nil
                    }

                    expect(registered).toEventually(beTrue())
afterEach()

                }

            // RSH3c
            

                func beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration")

                }

                // RSH3c1
                func test__027__Activation_state_machine__State_WaitingForDeviceRegistration__on_Event_CalledActivate() {
beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration()

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
afterEach()

                }

                // RSH3c2 / RSH8c
                func test__028__Activation_state_machine__State_WaitingForDeviceRegistration__on_Event_GotDeviceRegistration() {
beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration()

                    rest.internal.resetDeviceSingleton()

                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    var setAndPersistIdentityTokenDetailsCalled = false
                    let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                        setAndPersistIdentityTokenDetailsCalled = true
                    }
                    defer { hookDevice.remove() }

                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
                        token: "123456",
                        issued: Date(),
                        expires: Date.distantFuture,
                        capability: "",
                        clientId: ""
                    )

                    stateMachine.send(ARTPushActivationEventGotDeviceRegistration(identityTokenDetails: testIdentityTokenDetails))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(activatedCallbackCalled).to(beTrue())
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                    expect(storage.keysWritten.keys).to(contain(["ARTDeviceId", "ARTDeviceSecret", "ARTDeviceIdentityToken"]))
afterEach()

                }

                // RSH3c3
                func test__029__Activation_state_machine__State_WaitingForDeviceRegistration__on_Event_GettingDeviceRegistrationFailed() {
beforeEach__Activation_state_machine__State_WaitingForDeviceRegistration()

                    let expectedError = ARTErrorInfo(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)

                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_getArgument(from: NSSelectorFromString("callActivatedCallback:"), at: 0, callback: { arg0 in
                        activatedCallbackCalled = true
                        guard let error = arg0 as? ARTErrorInfo else {
                            fail("Error is missing"); return
                        }
                        expect(error) == expectedError
                    })
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventGettingDeviceRegistrationFailed(error: expectedError))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(activatedCallbackCalled).to(beTrue())
afterEach()

                }

            // RSH3d
            

                func beforeEach__Activation_state_machine__State_WaitingForNewPushDeviceDetails() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForNewPushDeviceDetails")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForNewPushDeviceDetails")

                }

                // RSH3d1
                func test__030__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledActivate() {
beforeEach__Activation_state_machine__State_WaitingForNewPushDeviceDetails()

                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(activatedCallbackCalled).to(beTrue())
afterEach()

                }

                // RSH3d2
                
                    func test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: TestCase_ReusableTestsRsh3d2) {
                    reusableTestsRsh3d2(testCase: testCase, context: (beforeEach: beforeEach__Activation_state_machine__State_WaitingForNewPushDeviceDetails, afterEach: afterEach))}
func test__031__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__should_use_custom_deregisterCallback_and_fire_Deregistered_event() {
test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_use_custom_deregisterCallback_and_fire_Deregistered_event)
}

func test__032__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event() {
test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event)
}

func test__033__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header() {
test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header)
}

func test__034__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header() {
test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header)
}

func test__035__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__should_fire_DeregistrationFailed_event() {
test__Activation_state_machine__State_WaitingForNewPushDeviceDetails__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_DeregistrationFailed_event)
}

enum TestCase_ReusableTestsTestStateWaitingForRegistrationSyncThrough {
case on_Event_CalledActivate
case on_Event_RegistrationSynced
case on_Event_SyncRegistrationFailed
}


            // RSH3e
            func reusableTestsTestStateWaitingForRegistrationSyncThrough(_ fromEvent: ARTPushActivationEvent, testCase: TestCase_ReusableTestsTestStateWaitingForRegistrationSyncThrough, context: (beforeEach: (() -> ())?, afterEach: (() -> ())?)) {
                func beforeEach() {
context.beforeEach?()

print("START HOOK: PushActivationStateMachine.beforeEach")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForRegistrationSync(machine: initialStateMachine, from: fromEvent))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
                    (stateMachine.current as! ARTPushActivationStateWaitingForRegistrationSync).fromEvent = fromEvent
print("END HOOK: PushActivationStateMachine.beforeEach")

                }
                
                // RSH3e1
                func test__on_Event_CalledActivate() {
beforeEach()

                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }
                    
                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                    if (!fromEvent.isKind(of: ARTPushActivationEventCalledActivate.self)) {                        expect(activatedCallbackCalled).to(beTrue())
                        expect(stateMachine.pendingEvents).to(haveCount(0))
                    } else {
                        expect(activatedCallbackCalled).to(beFalse())
                        expect(stateMachine.pendingEvents).to(haveCount(1))
                    }
context.afterEach?()

                }
                
                // RSH3e2
                func test__on_Event_RegistrationSynced() {
beforeEach()

                    var setAndPersistIdentityTokenDetailsCalled = false
                    let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                        setAndPersistIdentityTokenDetailsCalled = true
                    }
                    defer { hookDevice.remove() }
                    
                    let delegate = StateMachineDelegate()
                    stateMachine.delegate = delegate
                    
                    var activateCallbackCalled = false
                    delegate.onDidActivateAblyPush = { error in
                        expect(error).to(beNil())
                        activateCallbackCalled = true
                    }
                    
                    let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
                        token: "123456",
                        issued: Date(),
                        expires: Date.distantFuture,
                        capability: "",
                        clientId: ""
                    )
                    
                    stateMachine.send(ARTPushActivationEventRegistrationSynced(identityTokenDetails: testIdentityTokenDetails))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                    
                    // RSH3e2b
                    expect(activateCallbackCalled).toEventually(equal(fromEvent is ARTPushActivationEventCalledActivate), timeout: testTimeout)
context.afterEach?()

                }
                
                // RSH3e3
                func test__on_Event_SyncRegistrationFailed() {
beforeEach()

                    let expectedError = ARTErrorInfo(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                    
                    var updateFailedCallbackCalled = false
                    let hook = stateMachine.testSuite_getArgument(from: NSSelectorFromString("callUpdateFailedCallback:"), at: 0, callback: { arg0 in
                        updateFailedCallbackCalled = true
                        guard let error = arg0 as? ARTErrorInfo else {
                            fail("Error is missing"); return
                        }
                        expect(error) == expectedError
                    })
                    defer { hook.remove() }
                    
                    let delegate = StateMachineDelegate()
                    stateMachine.delegate = delegate
                    
                    var activateCallbackCalled = false
                    delegate.onDidActivateAblyPush = { error in
                        expect(error) == expectedError
                        activateCallbackCalled = true
                    }
                    
                    stateMachine.send(ARTPushActivationEventSyncRegistrationFailed(error: expectedError))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                    
                    // RSH3e3a
                    expect(updateFailedCallbackCalled).toEventually(equal(!(fromEvent is ARTPushActivationEventCalledActivate)), timeout: testTimeout)
                    // RSH3e3c
                    expect(activateCallbackCalled).toEventually(equal(fromEvent is ARTPushActivationEventCalledActivate), timeout: testTimeout)
context.afterEach?()

                }

switch testCase  {
case .on_Event_CalledActivate:
    test__on_Event_CalledActivate()
case .on_Event_RegistrationSynced:
    test__on_Event_RegistrationSynced()
case .on_Event_SyncRegistrationFailed:
    test__on_Event_SyncRegistrationFailed()
}

            }
            
            
                func test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: TestCase_ReusableTestsTestStateWaitingForRegistrationSyncThrough) {
                reusableTestsTestStateWaitingForRegistrationSyncThrough(ARTPushActivationEventCalledActivate(), testCase: testCase, context: (beforeEach: beforeEach, afterEach: afterEach))}
func test__036__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__on_Event_CalledActivate() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_CalledActivate)
}

func test__037__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__on_Event_RegistrationSynced() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_RegistrationSynced)
}

func test__038__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__on_Event_SyncRegistrationFailed() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventCalledActivate__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_SyncRegistrationFailed)
}

            
            
                func test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: TestCase_ReusableTestsTestStateWaitingForRegistrationSyncThrough) {
                reusableTestsTestStateWaitingForRegistrationSyncThrough(ARTPushActivationEventGotPushDeviceDetails(), testCase: testCase, context: (beforeEach: beforeEach, afterEach: afterEach))}
func test__039__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__on_Event_CalledActivate() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_CalledActivate)
}

func test__040__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__on_Event_RegistrationSynced() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_RegistrationSynced)
}

func test__041__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__on_Event_SyncRegistrationFailed() {
test__Activation_state_machine__State_WaitingForRegistrationSync_through_ARTPushActivationEventGotPushDeviceDetails__reusableTestsTestStateWaitingForRegistrationSyncThrough(testCase: .on_Event_SyncRegistrationFailed)
}

            
            // RSH3f
            

                func beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateAfterRegistrationSyncFailed(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed")

                }

                // RSH3f1
                
                    func test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: TestCase_ReusableTestsRsh3a2a) {
                    reusableTestsRsh3a2a(testCase: testCase, context: (beforeEach: beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed, afterEach: afterEach))}
func test__042__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match)
}

func test__043__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync)
}

func test__044__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledActivate__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync)
}


                // RSH3f1
                
                    func test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__reusableTestsRsh3a2a(testCase: TestCase_ReusableTestsRsh3a2a) {
                    reusableTestsRsh3a2a(testCase: testCase, context: (beforeEach: beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed, afterEach: afterEach))}
func test__045__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match)
}

func test__046__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync)
}

func test__047__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_GotPushDeviceDetails__reusableTestsRsh3a2a(testCase: .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync)
}


                // RSH3f2
                
                    func test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: TestCase_ReusableTestsRsh3d2) {
                    reusableTestsRsh3d2(testCase: testCase, context: (beforeEach: beforeEach__Activation_state_machine__State_AfterRegistrationSyncFailed, afterEach: afterEach))}
func test__048__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__should_use_custom_deregisterCallback_and_fire_Deregistered_event() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_use_custom_deregisterCallback_and_fire_Deregistered_event)
}

func test__049__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event)
}

func test__050__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header)
}

func test__051__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header)
}

func test__052__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__should_fire_DeregistrationFailed_event() {
test__Activation_state_machine__State_AfterRegistrationSyncFailed__on_Event_CalledDeactivate__reusableTestsRsh3d2(testCase: .should_fire_DeregistrationFailed_event)
}


            // RSH3g
            

                func beforeEach__Activation_state_machine__State_WaitingForDeregistration() {
beforeEach()

print("START HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForDeregistration")

                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
print("END HOOK: PushActivationStateMachine.beforeEach__Activation_state_machine__State_WaitingForDeregistration")

                }

                // RSH3g1
                func test__053__Activation_state_machine__State_WaitingForDeregistration__on_Event_CalledDeactivate() {
beforeEach__Activation_state_machine__State_WaitingForDeregistration()

                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
afterEach()

                }

                // RSH3g2
                func test__054__Activation_state_machine__State_WaitingForDeregistration__on_Event_Deregistered() {
beforeEach__Activation_state_machine__State_WaitingForDeregistration()

                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    var setAndPersistIdentityTokenDetailsCalled = false
                    let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                        setAndPersistIdentityTokenDetailsCalled = true
                    }
                    defer { hookDevice.remove() }

                    stateMachine.send(ARTPushActivationEventDeregistered())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                    // RSH3g2a
                    expect(stateMachine.rest.device.identityTokenDetails).to(beNil())
afterEach()

                }

                // RSH3g3
                func test__055__Activation_state_machine__State_WaitingForDeregistration__on_Event_DeregistrationFailed() {
beforeEach__Activation_state_machine__State_WaitingForDeregistration()

                    let expectedError = ARTErrorInfo(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)

                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_getArgument(from: NSSelectorFromString("callDeactivatedCallback:"), at: 0, callback: { arg0 in
                        deactivatedCallbackCalled = true
                        guard let error = arg0 as? ARTErrorInfo else {
                            fail("Error is missing"); return
                        }
                        expect(error) == expectedError
                    })
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventDeregistrationFailed(error: expectedError))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
afterEach()

                }

            // RSH4
            func test__005__Activation_state_machine__should_queue_event_that_has_no_transition_defined_for_it() {
beforeEach()

                // Start with WaitingForDeregistration state
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())

                stateMachine.transitions = { event, from, to in
                    fail("Should not handle the CalledActivate event because it should be queued")
                }

                stateMachine.send(ARTPushActivationEventCalledActivate())

                expect(stateMachine.pendingEvents).toEventually(haveCount(1), timeout: testTimeout)
                stateMachine.transitions = nil

                guard let pendingEvent = stateMachine.pendingEvents.firstObject else {
                    fail("Pending event is missing"); return
                }
                expect(pendingEvent).to(beAKindOf(ARTPushActivationEventCalledActivate.self))

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if previousState is ARTPushActivationStateWaitingForDeregistration, currentState is ARTPushActivationStateNotActivated {
                            // Handle Deregistered event
                            partialDone()
                        }
                        else if event is ARTPushActivationEventDeregistered, previousState is ARTPushActivationStateNotActivated, currentState is ARTPushActivationStateWaitingForPushDeviceDetails {
                            // Consume queued CalledActivate event
                            partialDone()
                        }
                    }
                    stateMachine.send(ARTPushActivationEventDeregistered())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
                }
                stateMachine.transitions = nil

                expect(stateMachine.pendingEvents).to(beEmpty())
afterEach()

            }

            // RSH5
            func test__006__Activation_state_machine__event_handling_sould_be_atomic_and_sequential() {
beforeEach()

                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate())
                stateMachine.send(ARTPushActivationEventCalledActivate())
                DispatchQueue(label: "QueueA").sync {
                    stateMachine.send(ARTPushActivationEventDeregistered())
                }
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
afterEach()

            }

        func test__001__should_remove_identityTokenDetails_from_cache_and_storage() {
beforeEach()

            let storage = MockDeviceStorage()
            rest.internal.storage = storage
            rest.device.setAndPersistIdentityTokenDetails(nil)
            rest.internal.resetDeviceSingleton()
            expect(rest.device.identityTokenDetails).to(beNil())
            expect(rest.device.isRegistered()) == false
            expect(storage.object(forKey: ARTDeviceIdentityTokenKey)).to(beNil())
afterEach()

        }
enum TestCase_ReusableTestsRsh3a2a {
case the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match
case the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync
case the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync
}


        func reusableTestsRsh3a2a(testCase: TestCase_ReusableTestsRsh3a2a, context: (beforeEach: (() -> ())?, afterEach: (() -> ())?)) {
                let testDeviceId = "aaaa"
                
                // RSH3a2a1
                func test__the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match() {
context.beforeEach?()

                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.clientId = "deviceClient"
                    let rest = ARTRest(options: options)
                    rest.internal.storage = storage
                    expect(rest.device.clientId).to(equal("deviceClient"))

                    let newOptions = ARTClientOptions(key: "xxxx:xxxx")
                    newOptions.clientId = "instanceClient"
                    let newRest = ARTRest(options: newOptions)
                    newRest.internal.storage = storage
                    let stateMachine = ARTPushActivationStateMachine(rest: newRest.internal, delegate: StateMachineDelegate())
                    
                    storage.simulateOnNextRead(string: testDeviceId, for: ARTDeviceIdKey)

                    let testDeviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "deviceClient")
                    stateMachine.rest.device.setAndPersistIdentityTokenDetails(testDeviceIdentityTokenDetails)
                    defer { stateMachine.rest.device.setAndPersistIdentityTokenDetails(nil) }
                    
                    waitUntil(timeout: testTimeout) { done in
                        stateMachine.transitions = { event, _, _ in
                            if let event = event as? ARTPushActivationEventSyncRegistrationFailed {
                                expect(event.error.code).to(equal(61002))
                                done()
                            }
                        }
                        stateMachine.send(ARTPushActivationEventCalledActivate())
                    }
context.afterEach?()

                }
                    func beforeEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID() {
context.beforeEach?()

print("START HOOK: PushActivationStateMachine.beforeEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID")

                        storage.simulateOnNextRead(string: testDeviceId, for: ARTDeviceIdKey)

                        let testDeviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                        stateMachine.rest.device.setAndPersistIdentityTokenDetails(testDeviceIdentityTokenDetails)
print("END HOOK: PushActivationStateMachine.beforeEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID")

                    }
                        
                    func afterEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID() {
print("START HOOK: PushActivationStateMachine.afterEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID")

                        stateMachine.rest.device.setAndPersistIdentityTokenDetails(nil)
print("END HOOK: PushActivationStateMachine.afterEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID")

context.afterEach?()

                    }
                    
                    // RSH3a2a2, RSH3a2a4
                    func test__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync() {
beforeEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID()

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledActivate {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventRegistrationSynced {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomRegister = { error, deviceDetails in
                                expect(error).to(beNil())
                                expect(deviceDetails).to(beIdenticalTo(rest.device))
                                partialDone()
                                return nil
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }

                        expect(httpExecutor.requests.count) == 0
afterEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID()

                    }
                    
                    // RSH3a2a3, RSH3a2a4, RSH3b3c
                    func test__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync() {
beforeEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID()

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledActivate {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventRegistrationSynced || event is ARTPushActivationEventSyncRegistrationFailed {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }
                        
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(rest.device.id)" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations/:deviceId\" request"); return
                        }
                        guard let url = request.url else {
                            fail("should have a URL"); return
                        }
                        guard let rawBody = request.httpBody else {
                            fail("should have a body"); return
                        }
                        let decodedBody: Any
                        do {
                            decodedBody = try stateMachine.rest.defaultEncoder.decode(rawBody)
                        }
                        catch {
                            fail("Decode failed: \(error)"); return
                        }
                        guard let body = decodedBody as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(url.host).to(equal(rest.internal.options.restUrl().host))
                        expect(request.httpMethod) == "PUT"
                        expect(body.value(forKey: "id") as? String).to(equal(rest.device.id))
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(expectedPushRecipient))
                        expect(body.value(forKey: "formFactor") as? String) == expectedFormFactor
                        expect(body.value(forKey: "platform") as? String) == expectedPlatform
afterEach__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID()

                    }

switch testCase  {
case .the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match:
    test__the_local_device_has_id_and_deviceIdentityToken__emits_a_SyncRegistrationFailed_event_with_code_61002_if_client_IDs_don_t_match()
case .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync:
    test__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__calls_registerCallback__transitions_to_WaitingForRegistrationSync()
case .the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync:
    test__the_local_device_has_id_and_deviceIdentityToken__the_local_DeviceDetails_matches_the_instance_s_client_ID__PUTs_device_registration__transitions_to_WaitingForRegistrationSync()
}

        }
enum TestCase_ReusableTestsRsh3d2 {
case should_use_custom_deregisterCallback_and_fire_Deregistered_event
case should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event
case should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header
case should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header
case should_fire_DeregistrationFailed_event
}


        func reusableTestsRsh3d2(testCase: TestCase_ReusableTestsRsh3d2, context: (beforeEach: (() -> ())?, afterEach: (() -> ())?)) {
            // RSH3d2a, RSH3d2c, RSH3d2d
            func test__should_use_custom_deregisterCallback_and_fire_Deregistered_event() {
context.beforeEach?()

                let delegate = StateMachineDelegateCustomCallbacks()
                stateMachine.delegate = delegate

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(3, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if event is ARTPushActivationEventCalledDeactivate {
                            // RSH3d2d
                            expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                            partialDone()
                        }
                        else if event is ARTPushActivationEventDeregistered {
                            stateMachine.transitions = nil
                            partialDone()
                        }
                    }
                    delegate.onPushCustomDeregister = { error, deviceId in
                        expect(error).to(beNil())
                        expect(deviceId) == rest.device.id
                        partialDone()
                        return nil
                    }
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                }

                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                expect(httpExecutor.requests.count) == 0
context.afterEach?()

            }

            // RSH3d2c
            func test__should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event() {
context.beforeEach?()

                let delegate = StateMachineDelegateCustomCallbacks()
                stateMachine.delegate = delegate

                waitUntil(timeout: testTimeout) { done in
                    let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                    let partialDone = AblyTests.splitDone(3, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if event is ARTPushActivationEventCalledDeactivate {
                            expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                            partialDone()
                        }
                        else if let event = event as? ARTPushActivationEventDeregistrationFailed {
                            expect(event.error.domain) == ARTAblyErrorDomain
                            expect(event.error.code) == simulatedError.code
                            stateMachine.transitions = nil
                            partialDone()
                        }
                    }
                    delegate.onPushCustomDeregister = { error, deviceId in
                        expect(error).to(beNil())
                        expect(deviceId) == rest.device.id
                        partialDone()
                        return simulatedError
                    }
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                }

                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                expect(httpExecutor.requests.count) == 0
context.afterEach?()

            }

            // RSH3d2b, RSH3d2c, RSH3d2d
            func test__should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header() {
context.beforeEach?()

                let delegate = StateMachineDelegate()
                stateMachine.delegate = delegate

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if event is ARTPushActivationEventCalledDeactivate {
                            // RSH3d2d
                            expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                            partialDone()
                        }
                        else if event is ARTPushActivationEventDeregistered {
                            stateMachine.transitions = nil
                            partialDone()
                        }
                    }
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                }

                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                expect(httpExecutor.requests.count) == 1
                let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(rest.device.id)" })
                expect(requests).to(haveCount(1))
                guard let request = httpExecutor.requests.first else {
                    fail("should have a \"/push/deviceRegistrations\" request"); return
                }
                guard let url = request.url else {
                    fail("should have a \"/push/deviceRegistrations\" URL"); return
                }
                expect(url.host).to(equal(rest.internal.options.restUrl().host))
                expect(request.httpMethod) == "DELETE"
                expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
                expect(deviceAuthorization).to(equal(rest.device.secret))
context.afterEach?()

            }

            // RSH3d2b, RSH3d2c, RSH3d2d
            func test__should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header() {
context.beforeEach?()

                let delegate = StateMachineDelegate()
                stateMachine.delegate = delegate

                let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
                    token: "123456",
                    issued: Date(),
                    expires: Date.distantFuture,
                    capability: "",
                    clientId: ""
                )

                expect(rest.device.identityTokenDetails).to(beNil())
                rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                defer { rest.device.setAndPersistIdentityTokenDetails(nil) }
                expect(rest.device.identityTokenDetails).toNot(beNil())

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if event is ARTPushActivationEventCalledDeactivate {
                            // RSH3d2d
                            expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                            partialDone()
                        }
                        else if event is ARTPushActivationEventDeregistered {
                            stateMachine.transitions = nil
                            partialDone()
                        }
                    }
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                }

                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                expect(httpExecutor.requests.count) == 1
                let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(rest.device.id)" })
                expect(requests).to(haveCount(1))
                guard let request = httpExecutor.requests.first else {
                    fail("should have a \"/push/deviceRegistrations\" request"); return
                }
                guard let url = request.url else {
                    fail("should have a \"/push/deviceRegistrations\" URL"); return
                }
                expect(url.host).to(equal(rest.internal.options.restUrl().host))
                expect(request.httpMethod) == "DELETE"
                expect(rest.device.identityTokenDetails).to(beNil())
                expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                expect(deviceAuthorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
context.afterEach?()

            }

            // RSH3d2c
            func test__should_fire_DeregistrationFailed_event() {
context.beforeEach?()

                let delegate = StateMachineDelegate()
                stateMachine.delegate = delegate

                let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    stateMachine.transitions = { event, previousState, currentState in
                        if event is ARTPushActivationEventCalledDeactivate {
                            expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                            partialDone()
                        }
                        else if let event = event as? ARTPushActivationEventDeregistrationFailed {
                            expect(event.error.domain) == ARTAblyErrorDomain
                            expect(event.error.code) == simulatedError.code
                            stateMachine.transitions = nil
                            partialDone()
                        }
                    }
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                }

                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                expect(httpExecutor.requests.count) == 1
                let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(rest.device.id)" })
                expect(requests).to(haveCount(1))
                guard let request = httpExecutor.requests.first else {
                    fail("should have a \"/push/deviceRegistrations\" request"); return
                }
                guard let url = request.url else {
                    fail("should have a \"/push/deviceRegistrations\" URL"); return
                }
                expect(url.host).to(equal(rest.internal.options.restUrl().host))
                expect(request.httpMethod) == "DELETE"
context.afterEach?()

            }

switch testCase  {
case .should_use_custom_deregisterCallback_and_fire_Deregistered_event:
    test__should_use_custom_deregisterCallback_and_fire_Deregistered_event()
case .should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event:
    test__should_use_custom_deregisterCallback_and_fire_DeregistrationFailed_event()
case .should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header:
    test__should_fire_Deregistered_event_and_include_DeviceSecret_HTTP_header()
case .should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header:
    test__should_fire_Deregistered_event_and_include_DeviceIdentityToken_HTTP_header()
case .should_fire_DeregistrationFailed_event:
    test__should_fire_DeregistrationFailed_event()
}

        }   

}

class StateMachineDelegate: NSObject, ARTPushRegistererDelegate {

    var onDidActivateAblyPush: ((ARTErrorInfo?) -> Void)?
    var onDidDeactivateAblyPush: ((ARTErrorInfo?) -> Void)?
    var onDidAblyPushRegistrationFail: ((ARTErrorInfo?) -> Void)?

    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        onDidActivateAblyPush?(error)
    }

    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        onDidDeactivateAblyPush?(error)
    }

    func didAblyPushRegistrationFail(_ error: ARTErrorInfo?) {
        onDidAblyPushRegistrationFail?(error)
    }

}

typealias ARTDeviceId = String

class StateMachineDelegateCustomCallbacks: StateMachineDelegate {

    var onPushCustomRegister: ((ARTErrorInfo?, ARTDeviceDetails?) -> NSError?)?
    var onPushCustomRegisterIdentity: ((ARTErrorInfo?, ARTDeviceDetails?) throws -> ARTDeviceIdentityTokenDetails)?
    var onPushCustomDeregister: ((ARTErrorInfo?, ARTDeviceId?) -> NSError?)?

    func ablyPushCustomRegister(_ error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails?, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void) {
        var registerError: NSError?
        var identity: ARTDeviceIdentityTokenDetails?
        if let register = onPushCustomRegister {
            registerError = register(error, deviceDetails)
            identity = ARTDeviceIdentityTokenDetails(token: "123456", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
        } else {
            do {
                identity = try onPushCustomRegisterIdentity!(error, deviceDetails)
            } catch {
                registerError = error as NSError
            }
        }
        delay(0) {
            callback(identity, registerError == nil ? nil : ARTErrorInfo.create(from: registerError!))
        }
    }

    func ablyPushCustomDeregister(_ error: ARTErrorInfo?, deviceId: String?, callback: ((ARTErrorInfo?) -> Void)? = nil) {
        let error = onPushCustomDeregister?(error, deviceId)
        delay(0) {
            callback?(error == nil ? nil : ARTErrorInfo.create(from: error!))
        }
    }

}
