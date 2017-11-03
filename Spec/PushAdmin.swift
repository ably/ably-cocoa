//
//  PushAdmin.swift
//  Ably
//
//  Created by Ricardo Pereira on 25/10/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick

class PushAdmin : QuickSpec {

    private static var deviceDetails: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "testDeviceDetails")
        deviceDetails.platform = "ios"
        deviceDetails.formFactor = "phone"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "apns",
            "deviceToken": "foo"
        ]
        return deviceDetails
    }()

    private static var deviceDetails1ClientA: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails1ClientA")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientA"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "gcm",
            "registrationToken": "qux"
        ]
        return deviceDetails
    }()

    private static var deviceDetails2ClientA: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails2ClientA")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientA"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "gcm",
            "registrationToken": "qux"
        ]
        return deviceDetails
    }()

    private static var deviceDetails3ClientB: ARTDeviceDetails = {
        let deviceDetails = ARTDeviceDetails(id: "deviceDetails3ClientB")
        deviceDetails.platform = "android"
        deviceDetails.formFactor = "tablet"
        deviceDetails.clientId = "clientB"
        deviceDetails.metadata = NSMutableDictionary()
        deviceDetails.push.recipient = [
            "transportType": "gcm",
            "registrationToken": "qux"
        ]
        return deviceDetails
    }()

    private static var allDeviceDetails: [ARTDeviceDetails] = [
        deviceDetails,
        deviceDetails1ClientA,
        deviceDetails2ClientA,
        deviceDetails3ClientB,
    ]

    private static var subscriptionFooDevice1 = ARTPushChannelSubscription(deviceId: "deviceDetails1ClientA", channel: "pushenabled:foo")
    private static var subscriptionFooDevice2 = ARTPushChannelSubscription(deviceId: "deviceDetails2ClientA", channel: "pushenabled:foo")
    private static var subscriptionBarDevice2 = ARTPushChannelSubscription(deviceId: "deviceDetails2ClientA", channel: "pushenabled:bar")
    private static var subscriptionFooClientA = ARTPushChannelSubscription(clientId: "clientA", channel: "pushenabled:foo")
    private static var subscriptionFooClientB = ARTPushChannelSubscription(clientId: "clientB", channel: "pushenabled:foo")
    private static var subscriptionBarClientB = ARTPushChannelSubscription(clientId: "clientB", channel: "pushenabled:bar")

    private static var allSubscriptions: [ARTPushChannelSubscription] = [
        subscriptionFooDevice1,
        subscriptionFooDevice2,
        subscriptionBarDevice2,
        subscriptionFooClientA,
        subscriptionFooClientB,
        subscriptionBarClientB,
    ]

    private lazy var deviceDetails: ARTDeviceDetails = PushAdmin.deviceDetails
    private lazy var deviceDetails1ClientA: ARTDeviceDetails = PushAdmin.deviceDetails1ClientA
    private lazy var deviceDetails2ClientA: ARTDeviceDetails = PushAdmin.deviceDetails2ClientA
    private lazy var deviceDetails3ClientB: ARTDeviceDetails = PushAdmin.deviceDetails3ClientB

    private lazy var allDeviceDetails: [ARTDeviceDetails] = PushAdmin.allDeviceDetails

    private lazy var subscriptionFooDevice1: ARTPushChannelSubscription = PushAdmin.subscriptionFooDevice1
    private lazy var subscriptionFooDevice2: ARTPushChannelSubscription = PushAdmin.subscriptionFooDevice2
    private lazy var subscriptionBarDevice2: ARTPushChannelSubscription = PushAdmin.subscriptionBarDevice2
    private lazy var subscriptionFooClientA: ARTPushChannelSubscription = PushAdmin.subscriptionFooClientA
    private lazy var subscriptionFooClientB: ARTPushChannelSubscription = PushAdmin.subscriptionFooClientB
    private lazy var subscriptionBarClientB: ARTPushChannelSubscription = PushAdmin.subscriptionBarClientB

    private lazy var allSubscriptions: [ARTPushChannelSubscription] = PushAdmin.allSubscriptions

    override class func setUp() {
        super.setUp()
        let rest = ARTRest(options: AblyTests.commonAppSetup())
        let group = DispatchGroup()

        for device in allDeviceDetails {
            group.enter()
            rest.push.admin.deviceRegistrations.save(device) { error in
                defer {
                    group.leave()
                }
                assert(error == nil)
            }
        }

        for subscription in allSubscriptions {
            group.enter()
            rest.push.admin.channelSubscriptions.save(subscription) { error in
                defer {
                    group.leave()
                }
                assert(error == nil)
            }
        }

        group.wait()
    }

    override class func tearDown() {
        let rest = ARTRest(options: AblyTests.commonAppSetup())
        let group = DispatchGroup()

        for device in allDeviceDetails {
            group.enter()
            rest.push.admin.deviceRegistrations.remove(device.id) { _ in
                group.leave()
            }
        }

        for subscription in allSubscriptions {
            group.enter()
            rest.push.admin.channelSubscriptions.remove(subscription) { _ in
                group.leave()
            }
        }

        super.tearDown()
    }

    override func spec() {

        var rest: ARTRest!
        var httpExecutor: MockHTTPExecutor!

        let recipient = [
            "client_id": "bob"
        ]

        let payload = [
            "notification": [
                "title": "Welcome"
            ]
        ]

        beforeEach {
            rest = ARTRest(key: "xxxx:xxxx")
            httpExecutor = MockHTTPExecutor()
            rest.httpExecutor = httpExecutor
        }

        // RHS1a
        describe("publish") {

            fit("should perform an HTTP request to /push/publish") {
                waitUntil(timeout: testTimeout) { done in
                    rest.push.admin.publish(recipient, data: payload) { error in
                        expect(error).to(beNil())
                        done()
                    }
                }

                switch extractBodyAsMsgPack(httpExecutor.requests.first) {
                case .failure(let error):
                    XCTFail(error)
                case .success(let httpBody):
                    guard let bodyRecipient = httpBody.unbox["recipient"] as? [String: String]  else {
                        fail("recipient is missing"); return
                    }
                    expect(bodyRecipient).to(equal(recipient))

                    guard let bodyPayload = httpBody.unbox["notification"] as? [String: String] else {
                        fail("notification is missing"); return
                    }
                    expect(bodyPayload).to(equal(payload["notification"]))
                }
            }

            it("should reject empty values/data for recipient") {
                waitUntil(timeout: testTimeout) { done in
                    rest.push.admin.publish(["clientId": ""], data: payload) { error in
                        guard let error = error else {
                            fail("Error is missing"); done(); return
                        }
                        expect(error.message).to(contain("recipient is empty"))
                        done()
                    }
                }
            }

            it("should reject empty values/data for payload") {
                waitUntil(timeout: testTimeout) { done in
                    rest.push.admin.publish(recipient, data: ["notification": ""]) { error in
                        guard let error = error else {
                            fail("Error is missing"); done(); return
                        }
                        expect(error.message).to(contain("payload is empty"))
                        done()
                    }
                }
            }

            it("should reject an invalid recipient") {
                waitUntil(timeout: testTimeout) { done in
                    rest.push.admin.publish(["foo": "bar"], data: payload) { error in
                        guard let error = error else {
                            fail("Error is missing"); done(); return
                        }
                        expect(error.message).to(contain("invalid recipient"))
                        done()
                    }
                }
            }

            it("should reject an invalid notification payload") {
                waitUntil(timeout: testTimeout) { done in
                    rest.push.admin.publish(recipient, data: ["foo": "bar"]) { error in
                        guard let error = error else {
                            fail("Error is missing"); done(); return
                        }
                        expect(error.message).to(contain("invalid payload"))
                        done()
                    }
                }
            }

            it("should send a notification") {
                let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                let channel = realtime.channels.get("push-test")

                waitUntil(timeout: testTimeout) { done in
                    channel.subscribe { message in
                        guard let data = message.data as? NSDictionary else {
                            fail("Message data should be a dictionary"); done(); return
                        }
                        expect(data).to(equal(payload as NSDictionary))
                        done()
                    }

                    realtime.push.admin.publish(["ablyChannel": channel.name], data: payload) { error in
                        expect(error).to(beNil())
                    }
                }
            }

        }

        describe("Device Registrations") {

            // RHS1b1
            context("get") {
                it("should return a device") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.get("testDeviceDetails") { device, error in
                            guard let device = device else {
                                fail("Device is missing"); done(); return;
                            }
                            expect(device).to(equal(self.deviceDetails))
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should not return a device if it does not exist") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.get("madeup") { device, error in
                            expect(device).to(beNil())
                            guard let error = error else {
                                fail("Error should not be empty"); done(); return
                            }
                            expect(error.statusCode) == 404
                            expect(error.message).to(contain("not found"))
                            done()
                        }
                    }
                }
            }

            // RHS1b2
            context("list") {
                it("should list devices by id") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.list(["deviceId": "testDeviceDetails"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 1
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should list devices by client id") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.list(["clientId": "clientA"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 2
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should list devices sorted") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.list(["direction": "forwards"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                it("should return an empty list when id does not exist") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.list(["deviceId": "madeup"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1b4
            context("remove") {
                it("should unregister a device") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.remove(self.deviceDetails.id) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1b3
            context("save") {
                it("should register a device") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.save(self.deviceDetails) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1b5
            context("removeWhere") {
                it("should unregister a device") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.deviceRegistrations.removeWhere(["clientId": "clientA"]) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

        }

        describe("Channel Subscriptions") {

            let subscription = ARTPushChannelSubscription(clientId: "newClient", channel: "pushenabled:qux")

            // RHS1c3
            context("save") {
                it("should add a subscription") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.save(subscription) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1c1
            context("list") {
                it("should receive a list of subscriptions") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(["channel": "pushenabled:qux"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 1
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1c2
            context("listChannels") {
                it("should receive a list of subscriptions") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.listChannels() { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 1
                            expect(result.items.first) == "pushenabled:qux"
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1c4
            context("remove") {
                it("should remove a subscription") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.remove(subscription) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(["channel": "pushenabled:qux"]) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RHS1c5
            context("removeWhere") {
                it("should remove by cliendId") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())

                    let params = [
                        "clientId": "clientB"
                    ]

                    let expectedRemoved = [
                        self.subscriptionFooClientB,
                        self.subscriptionBarClientB
                    ]

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(params) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(expectedRemoved.count, done: done)
                        for removedSubscription in expectedRemoved {
                            realtime.push.admin.channelSubscriptions.save(removedSubscription) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }
                }

                it("should remove by cliendId and channel") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())

                    let params = [
                        "clientId": "clientB",
                        "channel": "pushenabled:foo"
                    ]

                    let expectedRemoved = [
                        self.subscriptionFooClientB,
                    ]

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(params) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(expectedRemoved.count, done: done)
                        for removedSubscription in expectedRemoved {
                            realtime.push.admin.channelSubscriptions.save(removedSubscription) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }
                }

                it("should remove by deviceId") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())

                    let params = [
                        "deviceId": "subscriptionBarDevice2.deviceId",
                    ]

                    let expectedRemoved = [
                        self.subscriptionFooDevice2,
                        self.subscriptionBarDevice2,
                    ]

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(params) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(expectedRemoved.count, done: done)
                        for removedSubscription in expectedRemoved {
                            realtime.push.admin.channelSubscriptions.save(removedSubscription) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }
                }

                it("should not remove by inexistent deviceId") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())

                    let params = [
                        "deviceId": "madeup",
                    ]

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.list(params) { result, error in
                            guard let result = result else {
                                fail("PaginatedResult should not be empty"); done(); return
                            }
                            expect(result.items.count) == 0
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtime.push.admin.channelSubscriptions.removeWhere(params) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
            }

        }

    }
}
