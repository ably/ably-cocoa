//
//  Push.swift
//  Ably
//
//  Created by Ricardo Pereira on 18/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick

class Push : QuickSpec {
    override func spec() {

        var activationStateMachine: ARTPushActivationStateMachine!
        var testHTTPExecutor: MockHTTPExecutor!
        var testStorage: MockDeviceStorage!

        beforeEach {
            testHTTPExecutor = MockHTTPExecutor()
            testStorage = MockDeviceStorage()
            activationStateMachine = ARTPushActivationStateMachine(testHTTPExecutor, storage: testStorage)
        }

        describe("Activation state machine") {

            context("State NotActivated") {

                it("should be the initial state") {
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                }

                it("should read the current state in disk") {
                    let storage = MockDeviceStorage()

                    let state = ARTPushActivationStateWaitingForUpdateToken(machine: activationStateMachine)
                    let data = NSKeyedArchiver.archivedDataWithRootObject(state)
                    storage.simulateOnNextRead(data, for: ARTPushActivationCurrentStateKey)

                    let activationStateMachine = ARTPushActivationStateMachine(MockHTTPExecutor(), storage: storage)

                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                    expect(storage.keysRead).to(haveCount(2))
                    expect(storage.keysRead.filter({ $0.hasSuffix("CurrentState") })).to(haveCount(1))
                    expect(storage.keysWrite).to(beEmpty())
                }

                it("on Event CalledDeactivate, should transition to NotActivated") {
                    var deactivatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())

                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                context("on Event CalledActivate") {
                    it("if the local device has id and updateToken then should transition to WaitingForNewPushDeviceDetails") {
                        let testDeviceId = "aaaa"
                        testStorage.simulateOnNextRead(testDeviceId, for: ARTDeviceIdKey)

                        let testDeviceUpdateToken = "xxxx-xxxx-xxxx"
                        testStorage.simulateOnNextRead(testDeviceUpdateToken, for: ARTDeviceUpdateTokenKey)
                        activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    }

                    it("if the local device has the necessary push details should send event GotPushDeviceDetails") {
                        let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                        testStorage.simulateOnNextRead(testDeviceToken, for: ARTDeviceTokenKey)
                        activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationEventGotPushDeviceDetails))
                    }

                    it("none of them then should transition to WaitingForPushDeviceDetails") {
                        activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                        expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    }
                }

            }

            context("State WaitingForPushDeviceDetails") {

                it("on Event CalledActivate") {
                    activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationEventCalledActivate))
                }

                it("on Event CalledDeactivate") {
                    var deactivatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

                context("on Event GotPushDeviceDetails") {
                    it("should make an asynchronous HTTP request to /push/deviceRegistrations") {
                        activationStateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                        expect(testHTTPExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations" })).to(haveCount(1))
                        waitUntil(timeout: testTimeout) { done in
                            activationStateMachine.on(ARTPushActivationEventGotUpdateToken) {
                                expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                                done()
                            }
                        }
                    }
                }

            }

            context("State WaitingForUpdateToken") {

                it("on Event CalledActivate") {
                    activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                }

                it("on Event GotUpdateToken") {
                    var activatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventGotUpdateToken())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                it("on Event GettingUpdateTokenFailed") {
                    var activatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventGettingUpdateTokenFailed())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(activatedCallbackCalled).to(beTrue())
                }

            }

            context("State WaitingForNewPushDeviceDetails") {

                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    expect(activatedCallbackCalled).to(beTrue())
                }

                it("on Event CalledDeactivate") {
                    activationStateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
                    expect(testHTTPExecutor.requests.flatMap({ $0.URL?.path }).filter({ $0 == "/push/deviceRegistrations " })).to(haveCount(1))
                    waitUntil(timeout: testTimeout) { done in
                        activationStateMachine.on(ARTPushActivationEventDeregistered) {
                            expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                            done()
                        }
                    }
                }

            }

            context("State WaitingForRegistrationUpdate") {

                it("on Event CalledActivate") {
                    var activatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callActivatedCallback:")) {
                        activatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventCalledActivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForNewPushDeviceDetails))
                    expect(activatedCallbackCalled).to(beTrue())
                }

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

                it("on Event CalledDeactivate") {
                    activationStateMachine.sendEvent(ARTPushActivationEventCalledDeactivate())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                }

                it("on Event Deregistered") {
                    var deactivatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventDeregistered())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateNotActivated))
                    expect(deactivatedCallbackCalled).to(beTrue())
                    expect(testStorage.keysWrite.filter({ $0 == ARTDeviceUpdateTokenKey })).to(haveCount(1))
                }

                it("on Event DeregistrationFailed") {
                    var deactivatedCallbackCalled = false
                    let hook = activationStateMachine.testSuite_injectIntoMethodAfter(NSSelectorFromString("callDeactivatedCallback:")) {
                        deactivatedCallbackCalled = true
                    }
                    defer { hook.remove() }

                    activationStateMachine.sendEvent(ARTPushActivationEventDeregistrationFailed())
                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForDeregistration))
                    expect(deactivatedCallbackCalled).to(beTrue())
                }

            }

        }
    }
}
