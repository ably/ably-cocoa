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
                let stateMachine = rest.push.activationMachine()
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

            // https://github.com/ably/ably-cocoa/issues/877
            it("should update LocalDevice.clientId when it's null with auth.clientId") {
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
                rest.httpExecutor = mockHttpExecutor
                let storage = MockDeviceStorage()
                rest.storage = storage
                
                rest.resetDeviceSingleton()
                rest.push.resetActivationStateMachineSingleton()

                let stateMachine = rest.push.activationMachine()
                let testDeviceToken = "xxxx-xxxx-xxxx-xxxx-xxxx"
                stateMachine.rest.device.setAndPersistDeviceToken(testDeviceToken)
                let stateMachineDelegate = StateMachineDelegate()
                stateMachine.delegate = stateMachineDelegate
                defer {
                    stateMachine.transitions = nil
                    stateMachine.delegate = nil
                    stateMachine.rest.device.setAndPersistDeviceToken(nil)
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
                            partialDone()
                        }
                    }
                    rest.push.activate()
                }

                expect(rest.device.clientId) == expectedClientId
                expect(rest.auth.clientId) == expectedClientId

                switch extractBodyAsMsgPack(mockHttpExecutor.requests.last) {
                case .failure(let error):
                    fail(error)
                case .success(let httpBody):
                    guard let requestedClientId = httpBody.unbox["clientId"] as? String else {
                        fail("No clientId field in HTTPBody"); return
                    }
                    expect(requestedClientId).to(equal(expectedClientId))
                }
            }

        }

    }
}
