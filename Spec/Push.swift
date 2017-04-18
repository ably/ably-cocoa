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
                    storage.simulateOnNextRead(data)

                    let activationStateMachine = ARTPushActivationStateMachine(MockHTTPExecutor(), storage: storage)

                    expect(activationStateMachine.current).to(beAKindOf(ARTPushActivationStateWaitingForUpdateToken))
                    expect(storage.keysRead).to(haveCount(2))
                    expect(storage.keysRead.filter({ $0.hasSuffix("CurrentState") })).to(haveCount(1))
                    expect(storage.keysWrite).to(beEmpty())
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

            }

        }
    }
}
