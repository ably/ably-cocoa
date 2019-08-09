//
//  Push.swift
//  AblySpec
//
//  Created by Ricardo Pereira on 04/05/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick

class Push : QuickSpec {
    override func spec() {

        var rest: ARTRest!
        var mockHttpExecutor: MockHTTPExecutor!
        var storage: MockDeviceStorage!

        beforeEach {
            rest = ARTRest(key: "xxxx:xxxx")
            mockHttpExecutor = MockHTTPExecutor()
            rest.internal.httpExecutor = mockHttpExecutor
            storage = MockDeviceStorage()
            rest.internal.storage = storage
        }

        // RSH2
        describe("activation") {

            // RSH2a
            it("activate method should send a CalledActivate event to the state machine") {
                defer { rest.push.internal.activationMachine().transitions = nil }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.internal.activationMachine().transitions = { event, _, _ in
                        if event is ARTPushActivationEventCalledActivate {
                            done()
                        }
                    }
                    rest.push.activate()
                }
            }

            // RSH2b
            it("deactivate method should send a CalledDeactivate event to the state machine") {
                defer { rest.push.internal.activationMachine().transitions = nil }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.internal.activationMachine().transitions = { event, _, _ in
                        if event is ARTPushActivationEventCalledDeactivate {
                            done()
                        }
                    }
                    rest.push.deactivate()
                }
            }

            // RSH2c
            it("should handle GotPushDeviceDetails event when platform’s APIs sends the details for push notifications") {
                let stateMachine = rest.push.internal.activationMachine()
                let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                stateMachine.rest.device.setAndPersistDeviceToken(testDeviceToken)
                let stateMachineDelegate = StateMachineDelegate()
                stateMachine.delegate = stateMachineDelegate
                defer {
                    stateMachine.transitions = nil
                    stateMachine.delegate = nil
                    stateMachine.rest.device.setAndPersistDeviceToken(nil)
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

        }

    }
}
