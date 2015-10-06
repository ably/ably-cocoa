//
//  Auth.swift
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import Runes

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
            fit("should send the API key in the Authorization header") {
                let client = ARTRest(options: AblyTests.setupOptions(AblyTests.jsonRestOptions))
                client.httpExecutor = mockExecutor

                publishTestMessage(client, failOnError: false)

                let key64 = NSString(string: "\(client.options.key)")
                    .dataUsingEncoding(NSUTF8StringEncoding)?
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                let expectedAuthorization = "Basic \(key64!)"
                
                // X7
                let Authorization = mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"] as? String ?? ""
                
                expect(Authorization).to(equal(expectedAuthorization))
            }

            // RSA2
            it("should be default when an API key is set") {
                let client = ARTRest(options: ARTClientOptions(key: "fake:key"))

                expect(client.auth.method).to(equal(ARTAuthMethod.Basic))
            }
        }

        describe("Token") {
            
            it("should send the token in the Authorization header") {
                let options = ARTClientOptions()
                options.token = getTestToken()
                let client = ARTRest(options: options)
                client.httpExecutor = mockExecutor

                publishTestMessage(client, failOnError: false)
                
                expect(client.options.token).toNot(beNil())
                
                if let currentToken = client.options.token {
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
                        caseSetter(options)

                        let client = ARTRest(options: options)

                        expect(client.auth.method).to(equal(ARTAuthMethod.Token))
                    }
                }
            }
        }
        
        // RSA8
        describe("requestToken") {
            context("arguments") {
                // RSA8e
                it("sould supersede matching client library configured params and options") {
                    let clientOptions = ARTClientOptions()
                    clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                    
                    let rest = ARTRest(options: clientOptions)
                    
                    let authOptions = ARTAuthOptions()
                    authOptions.authUrl = NSURL(string: "http://test.ably.io")
                    authOptions.authMethod = "POST"
                    let tokenParams = ARTAuthTokenParams()
                    tokenParams.ttl = 30.0
                    
                    // AuthOptions
                    let mergedOptions = rest.auth.mergeOptions(authOptions)
                    expect(mergedOptions.authUrl) == NSURL(string: "http://test.ably.io")
                    expect(mergedOptions.authMethod) == "POST"
                    // TokenParams
                    let mergedParams = rest.auth.mergeParams(tokenParams)
                    expect(mergedParams.ttl) == 30.0
                }
                
                // TODO: RSA8b
            }
            
            // RSA8c
            context("authUrl") {
                context("parameters") {
                    // RSA8c1a
                    it("should be added to the URL when auth method is GET") {
                        let clientOptions = ARTClientOptions()
                        clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                        let tokenParams = ARTAuthTokenParams()
                        
                        let rest = ARTRest(options: clientOptions)
                        
                        let url = rest.auth.buildURL(clientOptions, withParams: tokenParams)
                        expect(url) == NSURL(string: "http://auth.ably.io/")
                    }
                    
                    // RSA8c1b
                    it("should added on the body request when auth method is POST") {
                        let clientOptions = ARTClientOptions()
                        clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                        clientOptions.authMethod = "POST"
                        let tokenParams = ARTAuthTokenParams()
                        
                        let rest = ARTRest(options: clientOptions)
                        
                        let request = rest.auth.buildRequest(clientOptions, withParams: tokenParams)
                        
                        let httpBodyJSON = request.HTTPBody >>- JSONToDictionary
                        
                        expect(httpBodyJSON).toNot(beNil())
                        expect(httpBodyJSON!["timestamp"]).toNot(beNil())
                        
                        let expectedJSON = ["ttl":NSString(format: "%f", CGFloat(60*60)), "capability":"{ \"*\": [ \"*\" ] }", "timestamp":httpBodyJSON!["timestamp"]!]
                        
                        expect(httpBodyJSON) == expectedJSON
                    }
                }
                
                // RSA8c3
                it("should override previously configured parameters") {
                    let clientOptions = ARTClientOptions()
                    clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                    let rest = ARTRest(options: clientOptions)
                    
                    let authOptions = ARTAuthOptions()
                    authOptions.authUrl = NSURL(string: "http://auth.ably.io")
                    authOptions.authParams = [NSURLQueryItem(name: "ttl", value: "invalid")]
                    authOptions.authParams = [NSURLQueryItem(name: "test", value: "1")]
                    
                    let url = rest.auth.buildURL(authOptions, withParams: ARTAuthTokenParams())
                    expect(url) == NSURL(string: "http://auth.ably.io/")
                }
            }
            
            // RSA8d
            context("authCallback") {
                it("") {
                    // TODO
                }
            }
            
            // RSA8a
            it("implicitly creates a TokenRequest") {
                let options = ARTClientOptions(key: "6p6USg.CNwGdA:uwJU1qsSf_Qe9VDH")
                // Test
                options.authUrl = NSURL(string: "http://auth.ably.io")
                options.authParams = [NSURLQueryItem(name: "ttl", value: "aaa")]
                options.authParams = [NSURLQueryItem(name: "rp", value: "true")]
                options.authMethod = "POST"
                
                let rest = ARTRest(options: options)
                
                rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                    
                })
            }
        }
    }
}
