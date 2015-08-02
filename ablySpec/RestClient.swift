//
//  RestClient.swift
//  ably
//
//  Created by Yavor Georgiev on 2.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import ably.Private

class PublishTestMessage {
    var status: ARTStatus?

    init(client: ARTRest, failOnError: Bool) {
        client.channel("test").publish("message") { status in
            self.status = status
            if failOnError && status.status != .StatusOk {
                XCTFail("Got status \(status.status.rawValue) with error '\(status.errorInfo?.message)'")
            }
        }
    }
}

func publishTestMessage(client: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: client, failOnError: failOnError)
}

func getTestToken() -> String {
    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
    options.authOptions.useTokenAuth = true
    options.authOptions.clientId = "testToken"
    let client = ARTRest(options: options)

    var token: String?
    client.auth().requestToken() { tokenDetails in
        token = tokenDetails.token
        return nil
    }

    while token == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
    }

    return token!
}

class RestClient: QuickSpec {
    override func spec() {
        describe("RestClient") {
            beforeEach {
                ARTClientOptions.getDefaultRestHost("sandbox-rest.ably.io", modify: true)
            }

            // RSC1
            context("initializer") {
                it("should accept an API key") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    let client = ARTRest(key: "\(options.authOptions.keyName):\(options.authOptions.keySecret)")

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should throw when provided an invalid key") {
                    expect{ ARTRest(key: "invalid_key") }.to(raiseException())
                }

                it("should result in error status when provided a bad key") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    let client = ARTRest(key: "badName:\(options.authOptions.keySecret)")

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusError), timeout: testTimeout)
                    expect(publishTask.status?.errorInfo.code).toEventually(equal(40005))
                }

                it("should accept an options object") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should accept an options object with token authentication") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.authOptions.useTokenAuth = true
                    options.authOptions.token = getTestToken()
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(client.auth().getAuthMethod()).to(equal(ARTAuthMethod.Token))
                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should result in error status when provided a bad token") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.authOptions.useTokenAuth = true
                    options.authOptions.token = "invalid_token"
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(client.auth().getAuthMethod()).to(equal(ARTAuthMethod.Token))
                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusError), timeout: testTimeout)
                    expect(publishTask.status?.errorInfo.code).toEventually(equal(40005))
                }
            }

            // RSC11
            context("endpoint") {
                it("should accept an options object with an environment set") {
                    // reset the default host in order to force ARTClientOptions to compute it
                    ARTClientOptions.getDefaultRestHost("rest.ably.io", modify: true)
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    let newOptions = ARTClientOptions()
                    newOptions.authOptions.keyName = options.authOptions.keyName
                    newOptions.authOptions.keySecret = options.authOptions.keySecret
                    newOptions.environment = "sandbox"
                    let client = ARTRest(options: newOptions)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }
            }
        }
    }
}