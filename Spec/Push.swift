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
        var stateMachineDelegate: StateMachineDelegate!

        beforeEach {
            rest = ARTRest(key: "xxxx:xxxx")
            rest.internal.resetDeviceSingleton()
            mockHttpExecutor = MockHTTPExecutor()
            rest.internal.httpExecutor = mockHttpExecutor
            storage = MockDeviceStorage()
            rest.internal.storage = storage
            stateMachineDelegate = StateMachineDelegate()
            rest.push.internal.createActivationStateMachine(withDelegate: stateMachineDelegate!)
        }

        // RSH2
        describe("activation") {

            // RSH2a
            it("activate method should send a CalledActivate event to the state machine") {
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
            it("deactivate method should send a CalledDeactivate event to the state machine") {
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
            it("should handle GotPushDeviceDetails event when platform’s APIs sends the details for push notifications") {
                let stateMachine = rest.push.internal.activationMachine
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
            
            // RSH2d / RSH8h
            it("sends GettingPushDeviceDetailsFailed when push registration fails") {
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
            it("should store the device token data as string") {
                let deviceTokenBase64 = "HYRXxPSQdt1pnxqtDAvc6PTTLH7N6okiBhYyLClJdmQ="
                let deviceTokenData = Data(base64Encoded: deviceTokenBase64, options: [])!
                let expectedDeviceToken = "1d8457c4f49076dd699f1aad0c0bdce8f4d32c7ecdea89220616322c29497664"
                defer { rest.push.internal.activationMachine.transitions = nil }
                waitUntil(timeout: testTimeout) { done in
                    rest.push.internal.activationMachine.onEvent = { event, _ in
                        if event is ARTPushActivationEventGotPushDeviceDetails {
                            done()
                        }
                    }
                    ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceTokenData, rest: rest)
                }
                expect(storage.keysWritten.keys).to(contain(["ARTDeviceToken"]))
                expect(storage.keysWritten.at("ARTDeviceToken")?.value as? String).to(equal(expectedDeviceToken))
            }

            // https://github.com/ably/ably-cocoa/issues/888
            it("should not sync the local device dispatched in internal queue") {
                let deviceTokenBase64 = "HYRXxPSQdt1pnxqtDAvc6PTTLH7N6okiBhYyLClJdmQ="
                let deviceTokenData = Data(base64Encoded: deviceTokenBase64, options: [])!
                expect { ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceTokenData, rest: rest) }.toNot(raiseException())
            }

        }

        context("LocalDevice") {
            // RSH8
            it("has a device method that returns a LocalDevice") {
                let _: ARTLocalDevice = ARTRest(key: "fake:key").device
                let _: ARTLocalDevice = ARTRealtime(key: "fake:key").device
            }
            
            // RSH8a
            it("the device is lazily populated from the persisted state") {
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
                storage.simulateOnNextRead(string: testToken, for: ARTDeviceTokenKey)
                storage.simulateOnNextRead(data: testIdentity.archive(), for: ARTDeviceIdentityTokenKey)

                let device = rest.device
                
                expect(device.deviceToken()).to(equal(testToken))
                expect(device.identityTokenDetails?.token).to(equal(testIdentity.token))
            }
            
            // RSH8d
            context("when using token authentication") {
                it("new clientID is set") {
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
            }
            
            // RSH8d
            context("when getting a client ID from CONNECTED message") {
                it("new clientID is set") {
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
            }
            
            // RSH8e
            it("authentication on registered device sends a GotPushDeviceDetails with new clientID") {
                let testToken = "testDeviceToken"
                let testIdentity = ARTDeviceIdentityTokenDetails(
                    token: "123456",
                    issued: Date(),
                    expires: Date.distantFuture,
                    capability: "",
                    clientId: ""
                )

                let options = ARTClientOptions(key: "fake:key")
                options.autoConnect = false
                options.authCallback = { _, callback in
                    delay(0.1) {
                        callback(ARTTokenDetails(token: "fake:token", expires: nil, issued: nil, capability: nil, clientId: "testClient"), nil)
                    }
                }

                let realtime = ARTRealtime(options: options)

                let storage = MockDeviceStorage(
                    startWith: ARTPushActivationStateWaitingForNewPushDeviceDetails(
                        machine: ARTPushActivationStateMachine(rest.internal)
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

                storage.simulateOnNextRead(string: testToken, for: ARTDeviceTokenKey)
                storage.simulateOnNextRead(data: testIdentity.archive(), for: ARTDeviceIdentityTokenKey)

                waitUntil(timeout: testTimeout) { done in
                    stateMachine.transitions = { event, _, _ in
                        if event is ARTPushActivationEventGotPushDeviceDetails {
                            done()
                        }
                    }
                    realtime.auth.authorize { _, _ in }
                }

                expect(realtime.device.clientId).to(equal("testClient"))
            }

            // RSH8f
            it("sets device's client ID from registration response") {
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
        }
    }
}
