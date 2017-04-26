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

        beforeEach {
            rest = ARTRest(key: "xxxx:xxxx")
            httpExecutor = MockHTTPExecutor()
            rest.httpExecutor = httpExecutor
            storage = MockDeviceStorage()
            initialStateMachine = ARTPushActivationStateMachine(rest, storage: storage)
        }

        describe("Activation state machine") {

            it("should set NotActivated state is current state in disk is empty") {
                expect(initialStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
            }

            it("should read the current state in disk") {
                let storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForUpdateToken(machine: initialStateMachine))
                let stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                expect(storage.keysRead).to(haveCount(2))
                expect(storage.keysRead.filter({ $0.hasSuffix("CurrentState") })).to(haveCount(1))
                expect(storage.keysWrite).to(beEmpty())
            }

            context("State NotActivated") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateNotActivated(machine: initialStateMachine))
                    stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                }

                it("on Event CalledDeactivate, should transition to NotActivated") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())

                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                context("on Event CalledActivate") {
                    it("if the local device has id and updateToken then should transition to WaitingForNewPushDeviceDetails") {
                        let testDeviceId = "aaaa"
                        //testStorage.simulateOnNextRead(testDeviceId, for: ARTDeviceIdKey)

                        let testDeviceUpdateToken = "xxxx-xxxx-xxxx"
                        //testStorage.simulateOnNextRead(testDeviceUpdateToken, for: ARTDeviceUpdateTokenKey)
                        stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    }

                    it("if the local device has the necessary push details should send event GotPushDeviceDetails") {
                        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                        //testStorage.simulateOnNextRead(testDeviceToken, for: ARTDeviceTokenKey)
                        stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationEventGotPushDeviceDetails))
                    }

                    it("none of them then should transition to WaitingForPushDeviceDetails") {
                        stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    }
                }

            }

            // RSH3b
            context("State WaitingForPushDeviceDetails") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForPushDeviceDetails(machine: initialStateMachine))
                    stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                }

                it("on Event CalledActivate") {
                    stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                }

                it("on Event CalledDeactivate") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                // RSH3b3
                context("on Event GotPushDeviceDetails") {

                    it("should raise exception if ARTPushRegistererDelegate is not implemented") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails))
                        expect{ stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails()) }.to(raiseException { exception in
                            expect(exception.reason).to(contain("ARTPushRegistererDelegate must be implemented"))
                        })
                    }

                    it("should use custom registerCallback and fire GotUpdateToken event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if event is ARTPushActivationEventGotUpdateToken {
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomRegister = { error, deviceDetails in
                                expect(error).to(beNil())
                                expect(deviceDetails).to(beIdenticalTo(rest.device))
                                partialDone()
                                return nil
                            }
                            stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should use custom registerCallback and fire GettingUpdateTokenFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: "", code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if let event = event as? ARTPushActivationEventGettingUpdateTokenFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomRegister = { error, deviceDetails in
                                expect(error).to(beNil())
                                expect(deviceDetails).to(beIdenticalTo(rest.device))
                                partialDone()
                                return simulatedError
                            }
                            stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should fire GotUpdateToken event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if event is ARTPushActivationEventGotUpdateToken {
                                    done()
                                }
                            }
                            stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.URL else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        guard let rawBody = request.HTTPBody else {
                            fail("should have a body"); return
                        }
                        guard let body = stateMachine.rest.defaultEncoder.decode(rawBody) as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(body.valueForKey("id") as? String).to(equal(rest.device.id))
                        expect(body.valueForKey("push")).toNot(beNil())
                        expect(body.valueForKey("formFactor")).toNot(beNil())
                        expect(body.valueForKey("platform")).toNot(beNil())
                    }

                    fit("should fire GettingUpdateTokenFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForPushDeviceDetails))

                        let delegate = StateMachineDelegate()
                        stateMachine.delegate = delegate

                        let simulatedError = NSError(domain: "", code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if let event = event as? ARTPushActivationEventGettingUpdateTokenFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    done()
                                }
                            }
                            stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.URL else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        guard let rawBody = request.HTTPBody else {
                            fail("should have a body"); return
                        }
                        guard let body = stateMachine.rest.defaultEncoder.decode(rawBody) as? NSDictionary else {
                            fail("body is invalid"); return
                        }
                        expect(body.valueForKey("id") as? String).to(equal(rest.device.id))
                        expect(body.valueForKey("push")).toNot(beNil())
                        expect(body.valueForKey("formFactor")).toNot(beNil())
                        expect(body.valueForKey("platform")).toNot(beNil())
                    }

                }

            }

            context("State WaitingForUpdateToken") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForUpdateToken(machine: initialStateMachine))
                    stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                }

                it("on Event CalledActivate") {
                    stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                }

                it("on Event GotUpdateToken") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventGotUpdateToken())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                it("on Event GettingUpdateTokenFailed") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventGettingUpdateTokenFailed())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(activatedCallbackCalled).to(beTrue())
                }

            }

            // RSH3d
            context("State WaitingForNewPushDeviceDetails") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(machine: initialStateMachine))
                    stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                }

                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                // RSH3d2
                context("on Event CalledDeactivate") {

                    it("should use custom deregisterCallback and fire Deregistered event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if event is ARTPushActivationEventDeregistered {
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomDeregister = { error, deviceId in
                                expect(error).to(beNil())
                                expect(deviceId) == rest.device.id
                                partialDone()
                                return nil
                            }
                            stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should use custom deregisterCallback and fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))

                        let delegate = StateMachineDelegateCustomCallbacks()
                        stateMachine.delegate = delegate

                        waitUntil(timeout: testTimeout) { done in
                            let simulatedError = NSError(domain: "", code: 1234, userInfo: nil)
                            let partialDone = AblyTests.splitDone(2, done: done)
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if let event = event as? ARTPushActivationEventDeregistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    partialDone()
                                }
                            }
                            delegate.onPushCustomDeregister = { error, deviceId in
                                expect(error).to(beNil())
                                expect(deviceId) == rest.device.id
                                partialDone()
                                return simulatedError
                            }
                            stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        expect(httpExecutor.requests.count) == 0
                    }

                    it("should fire Deregistered event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if event is ARTPushActivationEventDeregistered {
                                    done()
                                }
                            }
                            stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.URL else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        expect(request.HTTPMethod) == "DELETE"
                        expect(url.query).to(contain(rest.device.id))
                    }

                    it("should fire DeregistrationFailed event") {
                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))

                        let simulatedError = NSError(domain: "", code: 1234, userInfo: nil)
                        httpExecutor.simulateIncomingErrorOnNextRequest(simulatedError)

                        waitUntil(timeout: testTimeout) { done in
                            stateMachine.testSuite_getArgumentFrom(NSSelectorFromString("handleEvent:"), atIndex: 0) { event in
                                if let event = event as? ARTPushActivationEventDeregistrationFailed {
                                    expect(event.error.domain) == ARTAblyErrorDomain
                                    expect(event.error.code) == simulatedError.code
                                    done()
                                }
                            }
                            stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                            expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        }

                        expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                        expect(httpExecutor.requests.count) == 1
                        let requests = httpExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations" })
                        expect(requests).to(haveCount(1))
                        guard let request = httpExecutor.requests.first else {
                            fail("should have a \"/push/deviceRegistrations\" request"); return
                        }
                        guard let url = request.URL else {
                            fail("should have a \"/push/deviceRegistrations\" URL"); return
                        }
                        expect(request.HTTPMethod) == "DELETE"
                        expect(url.query).to(contain(rest.device.id))
                    }

                }

            }

            context("State WaitingForRegistrationUpdate") {

            }

            context("State AfterRegistrationUpdateFailed") {

                it("on Event CalledActivate") {

                }

                it("on Event GotPushDeviceDetails") {

                }

                it("on Event CalledDeactivate") {

                }

            }

            context("State WaitingForDeregistration") {

                var stateMachine: ARTPushActivationStateMachine!
                var storage: MockDeviceStorage!

                beforeEach {
                    storage = MockDeviceStorage(startWith: ARTPushActivationStateWaitingForDeregistration(machine: initialStateMachine))
                    stateMachine = ARTPushActivationStateMachine(rest, storage: storage)
                }

                it("on Event CalledDeactivate") {
                    stateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                }

                it("on Event Deregistered") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventDeregistered())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                    expect(storage.keysWrite.filter({ $0 == ARTDeviceUpdateTokenKey })).to(haveCount(1))
                }

                it("on Event DeregistrationFailed") {
                    var deactivatedCallbackCalled = false
                    let hook = stateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    stateMachine.sendEvent(ARTPushActivationEventDeregistrationFailed())
                    expect(stateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
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

    func didActivateAblyPush(error: ARTErrorInfo?) {
        onDidActivateAblyPush?(error)
    }

    func didDeactivateAblyPush(error: ARTErrorInfo?) {
        onDidDeactivateAblyPush?(error)
    }

    func didAblyPushRegistrationFail(error: ARTErrorInfo?) {
        onDidAblyPushRegistrationFail?(error)
    }

}

class StateMachineDelegateCustomCallbacks: StateMachineDelegate {

    var onPushCustomRegister: ((ARTErrorInfo?, deviceDetails: ARTDeviceDetails?) -> NSError?)?
    var onPushCustomDeregister: ((ARTErrorInfo?, deviceId: String?) -> NSError?)?

    func ablyPushCustomRegister(error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails?, callback: (String, ARTErrorInfo?) -> Void) {
        let error = onPushCustomRegister?(error, deviceDetails: deviceDetails)
        delay(0) {
            callback("", error == nil ? nil : ARTErrorInfo.createWithNSError(error!))
        }
    }

    func ablyPushCustomDeregister(error: ARTErrorInfo?, deviceId: String?, callback: ((ARTErrorInfo?) -> Void)?) {
        let error = onPushCustomDeregister?(error, deviceId: deviceId)
        delay(0) {
            callback?(error == nil ? nil : ARTErrorInfo.createWithNSError(error!))
        }
    }
    
}
