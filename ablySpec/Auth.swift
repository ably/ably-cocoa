//
//  Auth.swift
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import ably.Private

class Auth : QuickSpec {
    override func spec() {
        var mockExecutor: MockHTTPExecutor!
        beforeEach {
            mockExecutor = MockHTTPExecutor()
        }

        describe("Basic") {
            // RSA1
            it("should work over HTTPS only") {
                let clientOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                clientOptions.tls = false

                expect{ ARTRest(options: clientOptions) }.to(raiseException())
            }

            // RSA11
            it("should send the API key in the Authorization header") {
                let client = ARTRest(options: AblyTests.setupOptions(AblyTests.jsonRestOptions))
                client.httpExecutor = mockExecutor

                publishTestMessage(client, failOnError: false)

                let key64 = NSString(string: "\(client.options.authOptions.keyName):\(client.options.authOptions.keySecret)")
                    .dataUsingEncoding(NSUTF8StringEncoding)?
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                let Authorization = "Basic \(key64!)"
                expect(mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"]).to(equal(Authorization))
            }

            // RSA2
            it("should be default when an API йеъ is set") {
                let client = ARTRest(options: ARTClientOptions(key: "fake:key"))

                expect(client.auth.getAuthMethod()).to(equal(ARTAuthMethod.Basic))
            }
        }

        describe("Token") {

            fit("should send the token in the Authorization header") {
                let options = ARTClientOptions()
                options.authOptions.token = getTestToken()
                let client = ARTRest(options: options)
                client.httpExecutor = mockExecutor

                publishTestMessage(client, failOnError: false)

                let token64 = NSString(string: client.options.authOptions.token)
                    .dataUsingEncoding(NSUTF8StringEncoding)?
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                let Authorization = "Bearer \(token64!)"
                expect(mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"]).to(equal(Authorization))
            }

            // RSA4
            context("auhentication method") {
                let cases: [String: (ARTAuthOptions) -> ()] = [
                    "useTokenAuth": { $0.useTokenAuth = true; $0.key = "fake:key" },
                    "clientId": { $0.clientId = "clientId" },
                    "authUrl": { $0.authUrl = NSURL(string: "http://test.com") },
                    "authCallback": { $0.authCallback = { _ in return nil } },
                    "token": { $0.token = "" }
                ]

                for (caseName, caseSetter) in cases {
                    it("should be default when \(caseName) is set") {
                        let options = ARTClientOptions()
                        caseSetter(options.authOptions)

                        let client = ARTRest(options: options)

                        expect(client.auth.getAuthMethod()).to(equal(ARTAuthMethod.Token))
                    }
                }
            }
        }
    }
}
