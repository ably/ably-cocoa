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
            rest.internal.httpExecutor = httpExecutor
            storage = MockDeviceStorage()
            rest.internal.storage = storage
            initialStateMachine = ARTPushActivationStateMachine(rest.internal)
        }

        describe("Activation state machine") {

            it("should set NotActivated state as current state when disk is empty") {
                expect(initialStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated.self))
            }

            it("should read the current state from disk") {
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest.internal)
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
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
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
                    context("the local device has id and deviceIdentityToken") {
                        let testDeviceId = "aaaa"
                        
                        // RSH3a2a1
                        it("emits a SyncRegistrationFailed event with code 61002 if client IDs don't match") {
                            let options = ARTClientOptions(key: "xxxx:xxxx")
                            options.clientId = "deviceClient"
                            let rest = ARTRest(options: options)
                            rest.internal.storage = storage
                            expect(rest.device.clientId).to(equal("deviceClient"))

                            let newOptions = ARTClientOptions(key: "xxxx:xxxx")
                            newOptions.clientId = "instanceClient"
                            let newRest = ARTRest(options: newOptions)
                            newRest.internal.storage = storage
                            let stateMachine = ARTPushActivationStateMachine(newRest.internal)
                            
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
                        }
                        
                        context("the local DeviceDetails matches the instance's client ID") {
                            beforeEach {
                                storage.simulateOnNextRead(string: testDeviceId, for: ARTDeviceIdKey)

                                let testDeviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "xxxx-xxxx-xxx", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
                                stateMachine.rest.device.setAndPersistIdentityTokenDetails(testDeviceIdentityTokenDetails)
                            }
                                
                            afterEach {
                                stateMachine.rest.device.setAndPersistIdentityTokenDetails(nil)
                            }
                            
                            // RSH3a2a2, RSH3a2a4
                            it("calls registerCallback, transitions to WaitingForRegistrationSync") {
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
                            }
                            
                            // RSH3a2a3, RSH3a2a4, RSH3b3c
                            it("PUTs device registration, transitions to WaitingForRegistrationSync") {
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
                                
                                let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(testDeviceId)" })
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
                            }
                        }
                    }

                    // RSH3a2b
                    context("local device") {
                        it("should have a generated id") {
                            rest.internal.resetDeviceSingleton()
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
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
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
                    }

                    // RSH3b3c
                    it("should use custom registerCallback and fire GettingDeviceRegistrationFailed event") {
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
                    }

                    // RSH3b3c
                    it("should fire GettingDeviceRegistrationFailed event") {
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
                    }

                }
                
                // https://github.com/ably/ably-cocoa/issues/966
                it("when initializing from persistent state with a deviceToken, GotPushDeviceDetails should be re-emitted") {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForPushDeviceDetails(machine: initialStateMachine))
                    rest.internal.storage = storage
                    rest.device.setAndPersistDeviceToken("foo")
                    defer { rest.device.setAndPersistDeviceToken(nil) }
                    
                    var registered = false

                    let delegate = StateMachineDelegateCustomCallbacks()
                    stateMachine = ARTPushActivationStateMachine(rest.internal, delegate: delegate)
                    delegate.onPushCustomRegister = { error, deviceDetails in
                        registered = true
                        return nil
                    }

                    expect(registered).toEventually(beTrue())
                }
            }

            // RSH3c
            context("State WaitingForDeviceRegistration") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeviceRegistration(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
                }

                // RSH3c1
                it("on Event CalledActivate") {
                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeviceRegistration.self))
                }

                // RSH3c2
                it("on Event GotDeviceRegistration") {
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
                }

                // RSH3c3
                it("on Event GettingDeviceRegistrationFailed") {
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
                }

            }

            // RSH3d
            context("State WaitingForNewPushDeviceDetails") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
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
                    }

                    // RSH3d2c
                    it("should use custom deregisterCallback and fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

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
                    }

                    // RSH3d2b, RSH3d2c, RSH3d2d
                    it("should fire Deregistered event and include DeviceSecret HTTP header") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

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
                    }

                    // RSH3d2c
                    it("should fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))

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
                    }

                }

            }

            // RSH3e
            context("State WaitingForRegistrationSync") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForRegistrationSync(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
                }

                // RSH3e1
                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethod(after: NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.send(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                // RSH3e2
                it("on Event RegistrationSynced") {
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

                    stateMachine.send(ARTPushActivationEventRegistrationSynced(identityTokenDetails: testIdentityTokenDetails))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                    expect(setAndPersistIdentityTokenDetailsCalled).to(beTrue())
                }

                // RSH3e3
                it("on Event SyncRegistrationFailed") {
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

                    stateMachine.send(ARTPushActivationEventSyncRegistrationFailed(error: expectedError))
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                    expect(updateFailedCallbackCalled).to(beTrue())
                }

            }

            // RSH3f
            context("State AfterRegistrationSyncFailed") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateAfterRegistrationSyncFailed(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
                }

                // RSH3f1
                context("on Event CalledActivate") {
                    it("should use custom registerCallback and fire RegistrationSynced event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

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

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should use custom registerCallback and fire SyncRegistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(3, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledActivate {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    partialDone()
                                }
                                else if let event = event as? ARTPushActivationEventSyncRegistrationFailed {
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
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should fire SyncRegistrationFailed event and include device auth") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let deviceIdentityToken = stateMachine.rest.device.identityTokenDetails?.token.base64Encoded()

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledActivate {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    partialDone()
                                }
                                else if let event = event as? ARTPushActivationEventSyncRegistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(stateMachine.rest.device.id)" })
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
                        expect(request.httpMethod) == "PATCH"
                        expect(body.value(forKey: "id")).to(beNil())
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(["recipient": ["transportType": "apns"]]))
                        expect(body.value(forKey: "formFactor")).to(beNil())
                        expect(body.value(forKey: "platform")).to(beNil())
                        expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                        let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                        expect(deviceAuthorization).to(equal(deviceIdentityToken))
                    }

                    it("should fire RegistrationSynced event and include device auth") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate
                        
                        let deviceIdentityToken = stateMachine.rest.device.identityTokenDetails?.token.base64Encoded()

                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            fail("'setAndPersistIdentityTokenDetails:' should not be called")
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
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
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }

                        expect(stateMachine.rest.device.identityTokenDetails).toNot(beNil())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(stateMachine.rest.device.id)" })
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
                        expect(request.httpMethod) == "PATCH"
                        expect(body.value(forKey: "id")).to(beNil())
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(["recipient": ["transportType": "apns"]]))
                        expect(body.value(forKey: "formFactor")).to(beNil())
                        expect(body.value(forKey: "platform")).to(beNil())
                        expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                        let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                        expect(request.allHTTPHeaderFields?["X-Ably-DeviceSecret"]).to(beNil())
                        expect(deviceAuthorization).to(equal(deviceIdentityToken))
                    }

                    it("should transition to WaitingForRegistrationSync") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            fail("'setAndPersistIdentityTokenDetails:' should not be called")
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledActivate {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledActivate())
                        }
                    }
                }

                // RSH3f1
                context("on Event GotPushDeviceDetails") {
                    it("should use custom registerCallback and fire RegistrationSynced event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventRegistrationSynced {
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
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should use custom registerCallback and fire SyncRegistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if let event = event as? ARTPushActivationEventSyncRegistrationFailed {
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
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should fire SyncRegistrationFailed event and include device auth") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let deviceIdentityToken = stateMachine.rest.device.identityTokenDetails?.token.base64Encoded()

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, previousState, currentState in
                                if let event = event as? ARTPushActivationEventSyncRegistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(stateMachine.rest.device.id)" })
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
                        expect(body.value(forKey: "id")).to(beNil())
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(["recipient": ["transportType": "apns"]]))
                        expect(body.value(forKey: "formFactor")).to(beNil())
                        expect(body.value(forKey: "platform")).to(beNil())
                        expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                        let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                        expect(deviceAuthorization).to(equal(deviceIdentityToken))
                    }

                    it("should fire RegistrationSynced event and include device auth") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        guard let deviceIdentityToken = stateMachine.rest.device.identityTokenDetails?.token else {
                            fail("Unexpected 'identityTokenDetails' is nil")
                            return
                        }

                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            fail("'setAndPersistIdentityTokenDetails:' should not be called")
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    partialDone()
                                }
                                else if event is ARTPushActivationEventRegistrationSynced {
                                    stateMachine.transitions = nil
                                    partialDone()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }

                        expect(stateMachine.rest.device.identityTokenDetails?.token).to(equal(deviceIdentityToken))
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails.self))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.compactMap({ $0.url?.path }).filter({ $0 == "/push/deviceRegistrations/\(stateMachine.rest.device.id)" })
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
                        expect(request.httpMethod) == "PATCH"
                        expect(body.value(forKey: "id")).to(beNil())
                        expect(body.value(forKey: "push") as? [String: [String: String]]).to(equal(["recipient": ["transportType": "apns"]]))
                        expect(body.value(forKey: "formFactor")).to(beNil())
                        expect(body.value(forKey: "platform")).to(beNil())
                        expect(request.allHTTPHeaderFields?["Authorization"]).toNot(beNil())
                        let deviceAuthorization = request.allHTTPHeaderFields?["X-Ably-DeviceToken"]
                        expect(deviceAuthorization).to(equal(deviceIdentityToken.base64Encoded()))
                    }

                    it("should transition to WaitingForRegistrationSync") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            fail("'setAndPersistIdentityTokenDetails:' should not be called")
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventGotPushDeviceDetails {
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForRegistrationSync.self))
                                    stateMachine.transitions = nil
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventGotPushDeviceDetails())
                        }
                    }
                }

                // RSH3f2
                context("on Event CalledDeactivate") {
                    it("should use custom deregisterCallback and fire Deregistered event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledDeactivate {
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
                    }

                    it("should use custom deregisterCallback and fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

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
                    }

                    it("should fire Deregistered event and include DeviceSecret HTTP header") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledDeactivate {
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
                    }

                    it("should fire Deregistered event and include DeviceIdentityToken HTTP header") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

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
                    }

                    it("should fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

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
                    }

                    it("should transition to WaitingForDeregistration") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateAfterRegistrationSyncFailed.self))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        var setAndPersistIdentityTokenDetailsCalled = false
                        let hookDevice = stateMachine.rest.device.testSuite_injectIntoMethod(after: NSSelectorFromString("setAndPersistIdentityTokenDetails:")) {
                            setAndPersistIdentityTokenDetailsCalled = true
                        }
                        defer { hookDevice.remove() }

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.transitions = { event, previousState, currentState in
                                if event is ARTPushActivationEventCalledDeactivate {
                                    stateMachine.transitions = nil
                                    expect(currentState).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration.self))
                                    done()
                                }
                            }
                            stateMachine.send(ARTPushActivationEventCalledDeactivate())
                        }

                        expect(stateMachine.lastEvent).toEventually(beAKindOf(ARTPushActivationEventDeregistered.self), timeout: testTimeout)
                        expect(setAndPersistIdentityTokenDetailsCalled) == true
                    }
                }

            }

            // RSH3g
            context("State WaitingForDeregistration") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                    rest.internal.storage = storage
                    stateMachine = ARTPushActivationStateMachine(rest.internal)
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
                    // RSH3g2a
                    expect(stateMachine.rest.device.identityTokenDetails).to(beNil())
                }

                // RSH3g3
                it("on Event DeregistrationFailed") {
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
                }

            }

            // RSH4
            it("should queue event that has no transition defined for it") {
                // Start with WaitingForDeregistration state
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest.internal)

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
            }

            // RSH5
            it("event handling sould be atomic and sequential") {
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                rest.internal.storage = storage
                let stateMachine = ARTPushActivationStateMachine(rest.internal)
                stateMachine.send(ARTPushActivationEventCalledActivate())
                DispatchQueue(label: "QueueA").sync {
                    stateMachine.send(ARTPushActivationEventDeregistered())
                }
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails.self))
            }

        }

        it("should remove identityTokenDetails from cache and storage") {
            let storage = MockDeviceStorage()
            rest.internal.storage = storage
            rest.device.setAndPersistIdentityTokenDetails(nil)
            rest.internal.resetDeviceSingleton()
            expect(rest.device.identityTokenDetails).to(beNil())
            expect(rest.device.isRegistered()) == false
            expect(storage.object(forKey: ARTDeviceIdentityTokenKey)).to(beNil())
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

private class StateMachineDelegateCustomCallbacks: StateMachineDelegate {

    var onPushCustomRegister: ((ARTErrorInfo?, ARTDeviceDetails?) -> NSError?)?
    var onPushCustomDeregister: ((ARTErrorInfo?, ARTDeviceId?) -> NSError?)?

    func ablyPushCustomRegister(_ error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails?, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void) {
        let error = onPushCustomRegister?(error, deviceDetails)
        delay(0) {
            let deviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: "123456", issued: Date(), expires: Date.distantFuture, capability: "", clientId: "")
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
