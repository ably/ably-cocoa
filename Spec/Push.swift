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
            rest.httpExecutor = mockHttpExecutor
            storage = MockDeviceStorage()
            rest.storage = storage
        }

        // RSH2
        describe("activation") {

            // RSH2a
            it("activate method should send a CalledActivate event to the state machine") {
                defer { rest.push.activationMachine().transitions = nil }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.activationMachine().transitions = { event, _, _ in
                        if event is ARTPushActivationEventCalledActivate {
                            done()
                        }
                    }
                    rest.push.activate()
                }
            }

            // RSH2b
            it("deactivate method should send a CalledDeactivate event to the state machine") {
                defer { rest.push.activationMachine().transitions = nil }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.activationMachine().transitions = { event, _, _ in
                        if event is ARTPushActivationEventCalledDeactivate {
                            done()
                        }
                    }
                    rest.push.deactivate()
                }
            }

            // RSH2c
            it("should handle GotPushDeviceDetails event when platform’s APIs sends the details for push notifications") {
                let stateMachineDelegate = StateMachineDelegate()
                rest.push.activationMachine().delegate = stateMachineDelegate
                defer {
                    rest.push.activationMachine().transitions = nil
                    rest.push.activationMachine().delegate = nil
                }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.activationMachine().transitions = { event, _, _ in
                        if event is ARTPushActivationEventGotPushDeviceDetails {
                            done()
                        }
                    }
                    ARTPush.didRegisterForRemoteNotifications(withDeviceToken: Data(), rest: rest)
                    rest.push.activate()
                }
            }

        }

    }
}
