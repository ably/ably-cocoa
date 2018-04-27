//
//  PushActivationStateMachine.swift
//  Ably
//
//  Created by Ricardo Pereira on 18/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick

class PushActivationStateMachine : QuickSpec {
    override func spec() {

        var rest: ARTRest!
        var httpExecutor: MockHTTPExecutor!
        var storage: MockDeviceStorage!
        var initialStateMachine: ARTPushActivationStateMachine!

        let expectedFormFactor = "phone"
        let expectedPlatform = "ios"
        let expectedPushRecipient: [String: [String: String]] = ["recipient": ["transportType": "apns"]]

        beforeEach {
            rest = ARTRest(key: "xxxx:xxxx")
            httpExecutor = MockHTTPExecutor()
            rest.httpExecutor = httpExecutor
            storage = MockDeviceStorage()
            rest.storage = storage
            initialStateMachine = ARTPushActivationStateMachine(rest)
        }

        describe("Activation state machine") {

            it("should set NotActivated state as current state when disk is empty") {
                expect(initialStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
            }

            it("should read the current state from disk") {
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                rest.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest)
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                expect(storage.keysRead).to(haveCount(2))
                expect(storage.keysRead.filter({ $0.hasSuffix("CurrentState") })).to(haveCount(1))
                expect(storage.keysWritten).to(beEmpty())
            }

            // RSH3a
            context("State NotActivated") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateNotActivated(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3a1
                it("on Event CalledDeactivate, should transition to NotActivated") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledDeactivate())

                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                // RSH3a2
                context("on Event CalledActivate") {
                    // RSH3a2a
                    it("if the local device has id and deviceIdentityToken then should transition to WaitingForNewPushDeviceDetails") {
                        let testDeviceId = "aaaa"
                        storage.simulateOnNextRead(string: testDeviceId, for: ARTDeviceIdKey)

                        let testDeviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", deviceId: testDeviceId)
                        stateMachine.rest.device.setAndPersistIdentityTokenDetails(testDeviceIdentityTokenDetails)
                        defer { stateMachine.rest.device.setAndPersistIdentityTokenDetails(nil) }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventCalledActivate {
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    }

                    // RSH3a2b
                    context("local device") {
                        it("should have a generated id") {
                            rest.resetDeviceOnceToken()
                            expect(rest.device.id.lengthOfBytes(using: .utf8)) == 26 //ulid
                        }
                        it("should have a generated secret") {
                            guard let deviceSecret = rest.device.secret else {
                                fail("Device Secret should be available because it's loaded when the getter of the property is called"); return
                            }
                            guard let data = Data(base64Encoded: deviceSecret) else {
                                fail("Device Secret should be encoded with Base64"); return
                            }
                            expect(data.count) == 32 //32 bytes digest
                        }
                    }

                    // RSH3a2c
                    it("if the local device has the necessary push details should send event GotPushDeviceDetails") {
                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                        stateMachine.rest.device.setAndPersistDeviceToken(testDeviceToken)
                        defer { stateMachine.rest.device.setAndPersistDeviceToken(nil) }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventCalledActivate {
                                    partialDone()
                                }
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }
                    }

                    // RSH3a2d
                    it("none of them then should transition to WaitingForPushDeviceDetails") {
                        stateMachine.send(ARTPushActivationEventCalledActivate())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
                    }
                }

                // RSH3a3
                it("on Event GotPushDeviceDetails") {
                    stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                }

            }

            // RSH3b
            context("State WaitingForPushDeviceDetails") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForPushDeviceDetails(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3b1
                it("on Event CalledActivate") {
                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
                }

                // RSH3b2
                it("on Event CalledDeactivate") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                // RSH3b3
                context("on Event GotPushDeviceDetails") {

                    // TODO: The exception is raised but the `send:` method is doing an async call and the `expect` doesn't catch it
                    pending("should raise exception if ARTPushRegistererDelegate is not implemented") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
                        expect {
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }.to(raiseException { exception in
                            expect(exception.reason).to(contain("ARTPushRegistererDelegate must be implemented"))
                        })
                    }

                    // RSH3b3a, RSH3b3c
                    it("should use custom registerCallback and fire GotDeviceRegistration event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventGotDeviceRegistration {
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
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    // RSH3b3c
                    it("should use custom registerCallback and fire GettingDeviceRegistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, from, to in
                                if let event = event as? ARTPushActivationEventGettingDeviceRegistrationFailed {
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
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    // RSH3b3b, RSH3b3c
                    it("should fire GotDeviceRegistration event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        var setAndPersistIdentityTokenDetailsCalled = false
                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            setAndPersistIdentityTokenDetailsCalled = true
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventGotDeviceRegistration {
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
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
                        guard let body = stateMachine.rest.defaultEncoder.decode(rawBody, error: nil) as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(request.httpMethod) == "POST"
                        expect(body.value(forKey: "id") as? String).to(equal(rest.device.id))
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(expectedPushRecipient))
                        expect(body.value(forKey: "formFactor") as? String) == expectedFormFactor
                        expect(body.value(forKey: "platform") as? String) == expectedPlatform
                    }

                    // RSH3b3c
                    it("should fire GettingDeviceRegistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if let event = event as? ARTPushActivationEventGettingDeviceRegistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
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
                        guard let body = stateMachine.rest.defaultEncoder.decode(rawBody, error: nil) as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(body.value(forKey: "id") as? String).to(equal(rest.device.id))
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(expectedPushRecipient))
                        expect(body.value(forKey: "formFactor") as? String) == expectedFormFactor
                        expect(body.value(forKey: "platform") as? String) == expectedPlatform
                    }

                    // RSH3b3d
                    it("should transition to WaitingForDeviceRegistration") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        var setAndPersistIdentityTokenDetailsCalled = false
                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            setAndPersistIdentityTokenDetailsCalled = true
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventGotDeviceRegistration {
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                        }
                    }

                }

            }

            // RSH3c
            context("State WaitingForDeviceRegistration") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3c1
                it("on Event CalledActivate") {
                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                }

                // RSH3c2
                it("on Event GotDeviceRegistration") {
                    rest.resetDeviceOnceToken()

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
                        deviceId: rest.device.id
                    )

                    stateMachine.send(ARTPushActivationEventGotDeviceRegistration(identityTokenDetails: testIdentityTokenDetails))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(activatedCallbackCalled).to(beTrue())
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                    expect(storage.keysWritten).to(contain(["ARTDeviceId", "ARTDeviceSecret", "ARTDeviceIdentityToken"]))
                }

                // RSH3c3
                it("on Event GettingDeviceRegistrationFailed") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventGettingDeviceRegistrationFailed())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                    expect(activatedCallbackCalled).to(beTrue())
                }

            }

            // RSH3d
            context("State WaitingForNewPushDeviceDetails") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3d1
                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                // RSH3d2
                context("on Event CalledDeactivate") {

                    // RSH3d2a, RSH3d2c, RSH3d2d
                    it("should use custom deregisterCallback and fire Deregistered event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventDeregistered {
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
                            // RSH3d2d
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    // RSH3d2c
                    it("should use custom deregisterCallback and fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, from, to in
                                if let event = event as? ARTPushActivationEventDeregistrationFailed {
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
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    // RSH3d2b, RSH3d2c, RSH3d2d
                    it("should fire Deregistered event and include DeviceSecret HTTP header") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventDeregistered {
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledDeactivate())
                            // RSH3d2d
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.url else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        expect(request.httpMethod) == "DELETE"
                        expect(url.query).to(contain(rest.device.id))
                        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]
                        expect(authorization).to(equal(rest.device.secret))
                    }

                    // RSH3d2b, RSH3d2c, RSH3d2d
                    it("should fire Deregistered event and include DeviceIdentityToken HTTP header") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let testIdentityTokenDetails = ARTDeviceIdentityTokenDetails(
                            token: "123456",
                            issued: Date(),
                            expires: Date.distantFuture,
                            capability: "",
                            deviceId: rest.device.id
                        )

                        expect(rest.device.identityTokenDetails).to(beNil())
                        rest.device.setAndPersistIdentityTokenDetails(testIdentityTokenDetails)
                        defer { rest.device.setAndPersistIdentityTokenDetails(nil) }
                        expect(rest.device.identityTokenDetails).toNot(beNil())

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if event is ARTPushActivationEventDeregistered {
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledDeactivate())
                            // RSH3d2d
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.url else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        expect(request.httpMethod) == "DELETE"
                        expect(url.query).to(contain(rest.device.id))
                        expect(rest.device.identityTokenDetails).to(beNil())
                        let authorization = request.allHTTPHeaderFields?["X-Ably-DeviceIdentityToken"]
                        expect(authorization).to(equal(testIdentityTokenDetails.token.base64Encoded()))
                    }

                    // RSH3d2c
                    it("should fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, from, to in
                                if let event = event as? ARTPushActivationEventDeregistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledDeactivate())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.url else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        expect(request.httpMethod) == "DELETE"
                        expect(url.query).to(contain(rest.device.id))
                    }

                }

            }

            // RSH3e
            context("State WaitingForRegistrationUpdate") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForRegistrationUpdate(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3e1
                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationUpdate.self))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                // RSH3e2
                it("on Event RegistrationUpdated") {
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
                        deviceId: rest.device.id
                    )

                    stateMachine.send(ARTPushActivationEventRegistrationUpdated(identityTokenDetails: testIdentityTokenDetails))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationUpdate.self))
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                }

                // RSH3e3
                it("on Event UpdatingRegistrationFailed") {
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

                    stateMachine.send(ARTPushActivationEventUpdatingRegistrationFailed(error: expectedError))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationUpdateFailed.self))
                    expect(updateFailedCallbackCalled).to(beTrue())
                }

            }

            // RSH3f
            context("State AfterRegistrationUpdateFailed") {

                it("on Event CalledActivate") {
                    // Doesn't happen in iOS
                }

                it("on Event GotPushDeviceDetails") {
                    // Doesn't happen in iOS
                }

                it("on Event CalledDeactivate") {
                    // Doesn't happen in iOS
                }

            }

            // RSH3g
            context("State WaitingForDeregistration") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                    rest.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest)
                }

                // RSH3g1
                it("on Event CalledDeactivate") {
                    stateMachine.send(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                }

                // RSH3g2
                it("on Event Deregistered") {
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
                }

                // RSH3g3
                it("on Event DeregistrationFailed") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventDeregistrationFailed())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

            }

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
    var onPushCustomDeregister: ((ARTErrorInfo?, ARTDeviceId?) -> NSError?)?

    func ablyPushCustomRegister(_ error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails?, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void) {
        let error = onPushCustomRegister?(error, deviceDetails)
        delay(0) { [deviceId = deviceDetails?.id] in
            let deviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "123456", issued: Date(), expires: Date.distantFuture, capability: "", deviceId: deviceId ?? "unknown")
            callback(deviceIdentityTokenDetails, error == nil ? nil : ARTErrorInfo.create(from: error!))
        }
    }

    func ablyPushCustomDeregister(_ error: ARTErrorInfo?, deviceId: String?, callback: ((ARTErrorInfo?) -> Void)? = nil) {
        let error = onPushCustomDeregister?(error, deviceId)
        delay(0) {
            callback?(error == nil ? nil : ARTErrorInfo.create(from: error!))
        }
    }

}
