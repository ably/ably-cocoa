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

                let key64 = NSString(string: "\(client.options.authOptions.key)")
                    .dataUsingEncoding(NSUTF8StringEncoding)?
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                let Authorization = "Basic \(key64!)"
                
                // X7
                //expect(mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"]).to(equal(Authorization))
            }

            // RSA2
            it("should be default when an API йеъ is set") {
                let client = ARTRest(options: ARTClientOptions(key: "fake:key"))

                expect(client.auth.authMethod).to(equal(ARTAuthMethod.Basic))
            }
        }

        describe("Token") {
            
            fit("implicitly creates a TokenRequest") {
                // WIP
                let options = ARTClientOptions(key: "6p6USg.CNwGdA:uwJU1qsSf_Qe9VDH")
                // Test
                options.authOptions.authUrl = NSURL(string: "http://auth.ably.io")
                options.authOptions.authParams = [NSURLQueryItem(name: "ttl", value: "aaa")]
                options.authOptions.authMethod = "POST"
                
                let rest = ARTRest(options: options)

                rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                    
                })
            }

            it("should send the token in the Authorization header") {
                let options = ARTClientOptions()
                options.authOptions.token = getTestToken()
                let client = ARTRest(options: options)
                client.httpExecutor = mockExecutor

                publishTestMessage(client, failOnError: false)
                
                expect(client.options.authOptions.token).toNot(beNil())
                
                if let currentToken = client.options.authOptions.token {
                    let token64 = NSString(string: currentToken)
                        .dataUsingEncoding(NSUTF8StringEncoding)?
                        .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                    let Authorization = "Bearer \(token64!)"
                    
                    // X7
                    //expect(mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"]).to(equal(Authorization))
                }
            }

            // RSA4
            context("authentication method") {
                let cases: [String: (ARTAuthOptions) -> ()] = [
                    "useTokenAuth": { $0.useTokenAuth = true; $0.key = "fake:key" },
                    "authUrl": { $0.authUrl = NSURL(string: "http://test.com") },
                    "authCallback": { $0.authCallback = { _, _ in return } },
                    "token": { $0.token = "" }
                ]

                for (caseName, caseSetter) in cases {
                    it("should be default when \(caseName) is set") {
                        let options = ARTClientOptions()
                        caseSetter(options.authOptions)

                        let client = ARTRest(options: options)

                        expect(client.auth.authMethod).to(equal(ARTAuthMethod.Token))
                    }
                }
            }
        }
    }
}
