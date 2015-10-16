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
                
                let key64 = NSString(string: "\(client.options.key!)")
                    .dataUsingEncoding(NSUTF8StringEncoding)?
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                                
                let expectedAuthorization = "Basic \(key64!)"
                
                expect(mockExecutor.requests.first).toNot(beNil(), description: "No request found")
                
                let authorization = mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"] ?? ""
                
                expect(authorization).to(equal(expectedAuthorization))
            }

            // RSA2
            it("should be default when an API key is set") {
                let client = ARTRest(options: ARTClientOptions(key: "fake:key"))

                expect(client.auth.method).to(equal(ARTAuthMethod.Basic))
            }
        }

        describe("Token") {
            
            // RSA3
            context("token auth") {
                // RSA3a
                it("should work over HTTPS or HTTP") {
                    let options = ARTClientOptions()
                    options.token = getTestToken()
                    
                    // Check HTTP
                    options.tls = false
                    let clientHTTP = ARTRest(options: options)
                    clientHTTP.httpExecutor = mockExecutor
                    
                    publishTestMessage(clientHTTP, failOnError: false)
                    
                    expect(mockExecutor.requests.first).toNot(beNil(), description: "No request found")
                    expect(mockExecutor.requests.first?.URL).toNot(beNil(), description: "Request is invalid")
                    
                    if let request = mockExecutor.requests.first, let url = request.URL {
                        expect(url.scheme).to(equal("http"), description: "No HTTP support")
                    }
                    
                    // Check HTTPS
                    options.tls = true
                    let clientHTTPS = ARTRest(options: options)
                    clientHTTPS.httpExecutor = mockExecutor
                    
                    publishTestMessage(clientHTTPS, failOnError: false)
                    
                    expect(mockExecutor.requests.last).toNot(beNil(), description: "No request found")
                    expect(mockExecutor.requests.last?.URL).toNot(beNil(), description: "Request is invalid")
                    
                    if let request = mockExecutor.requests.last, let url = request.URL {
                        expect(url.scheme).to(equal("https"), description: "No HTTPS support")
                    }
                }
                
                // RSA3b
                it("should send the token in the Authorization header") {
                    let options = ARTClientOptions()
                    options.token = getTestToken()
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    publishTestMessage(client, failOnError: false)
                    
                    expect(client.options.token).toNot(beNil(), description: "No access token")
                    
                    if let currentToken = client.options.token {
                        let token64 = NSString(string: currentToken)
                            .dataUsingEncoding(NSUTF8StringEncoding)?
                            .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                        
                        let expectedAuthorization = "Bearer \(token64!)"
                        
                        expect(mockExecutor.requests.first).toNot(beNil(), description: "No request found")
                        
                        let authorization = mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"] ?? ""
                        
                        expect(authorization).to(equal(expectedAuthorization))
                    }
                }
                
                // RSA3c
                // TODO: not implemented
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
            
            // RSA14
            context("options") {
                // Cases:
                //  - useTokenAuth is specified and thus a key is not provided
                //  - authCallback and authUrl are both specified
                let cases: [String: (ARTAuthOptions) -> ()] = [
                    "useTokenAuth and no key":{ $0.useTokenAuth = true },
                    "authCallback and authUrl":{ $0.authCallback = { params, callback in /*nothing*/ }; $0.authUrl = NSURL(string: "http://auth.ably.io") }
                ]
                
                for (caseName, caseSetter) in cases {
                    it("should stop client when \(caseName) occurs") {
                        let options = ARTClientOptions()
                        caseSetter(options)
                        
                        expect{ ARTRest(options: options) }.to(raiseException())
                    }
                }
            }

            // RSA15
            context("token auth and clientId") {
                // RSA15a
                it("should check clientId consistency") {
                    let expectedClientId = "client_string"
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = expectedClientId
                    
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: 10) { done in
                        // Token
                        client.authorise { tokenDetails, error in
                            expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                            expect(tokenDetails?.clientId).to(equal(expectedClientId))
                            done()
                        }
                    }
                    
                    switch extractBodyAsJSON(mockExecutor.requests.first) {
                    case .Failure(let error):
                        XCTFail(error)
                    case .Success(let httpBody):
                        guard let requestedClientId = httpBody.unbox["clientId"] as? String else { XCTFail("No clientId field in HTTPBody"); return }
                        expect(requestedClientId).to(equal(expectedClientId))
                    }
                    
                    // TODO: Realtime.connectionDetails of the CONNECTED ProtocolMessage
                }
                
                // RSA15b
                it("should permit to be unauthenticated") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = "*"
                    
                    waitUntil(timeout: 10) { done in
                        // Token
                        ARTRest(options: options).authorise { tokenDetails, error in
                            expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                            expect(tokenDetails?.clientId).to(equal(options.clientId))
                            options.tokenDetails = tokenDetails
                            done()
                        }
                    }

                    waitUntil(timeout: 10) { done in
                        // Token
                        ARTRest(options: options).authorise { tokenDetails, error in
                            expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                            expect(tokenDetails?.clientId).to(equal("*"))
                            done()
                        }
                    }

                    // TODO: Realtime.connectionDetails
                }
                
                // RSA15c
                it("should cancel request when clientId is invalid") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    
                    // Check unquoted
                    options.clientId = "\"client_string\""
                    waitUntil(timeout: 10) { done in
                        // Token
                        ARTRest(options: options).authorise { tokenDetails, error in
                            expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                            expect(tokenDetails?.clientId).to(equal(options.clientId))
                            done()
                        }
                    }
                    
                    // Check unescaped
                    options.clientId = "client_string\n"
                    waitUntil(timeout: 10) { done in
                        // Token
                        ARTRest(options: options).authorise { tokenDetails, error in
                            expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                            expect(tokenDetails?.clientId).to(equal(options.clientId))
                            done()
                        }
                    }
                }
            }
            
            // RSA5
            it("should use one hour default time to live") {
                let tokenParams = ARTAuthTokenParams()
                expect(tokenParams.ttl) == 60 * 60
            }
            
            // RSA6
            it("should allow all operations when capability is not specified") {
                let tokenParams = ARTAuthTokenParams()
                expect(tokenParams.capability) == "{\"*\":[\"*\"]}"
                
                let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                
                waitUntil(timeout: 10) { done in
                    // Token
                    ARTRest(options: options).auth.requestToken(tokenParams, withOptions: options) { tokenDetails, error in
                        expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                        expect(tokenDetails?.capability).to(equal(tokenParams.capability))
                        done()
                    }
                }
            }
            
            // RSA7
            context("clientId and authenticated clients") {
                // RAS7a1
                it("should use assigned clientId on all operations") {
                    let expectedClientId = "client_string"
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = expectedClientId

                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: 10) { done in
                        // Publish message
                        client.channels.get("test").publish("message") { error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            done()
                        }
                    }
                    
                    switch extractBodyAsJSON(mockExecutor.requests.last) {
                    case .Failure(let error):
                        XCTFail(error)
                    case .Success(let httpBody):
                        guard let requestedClientId = httpBody.unbox["clientId"] as? String else { XCTFail("No clientId field in HTTPBody"); return }
                        expect(requestedClientId).to(equal(expectedClientId))
                    }
                    
                    // TODO: add more operations
                }
                
                // RSA7a2
                fit("should obtain a token if clientId is assigned") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = "client_string"
                    
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: 10) { done in
                        client.channels.get("test").publish("message") { error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            done()
                        }
                    }
                    
                    let authorization = mockExecutor.requests.last?.allHTTPHeaderFields?["Authorization"] ?? ""
                    
                    expect(authorization).toNot(equal(""))
                }
                
                // RSA7a3
                it("should convenience clientId return a string") {
                    let clientOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    clientOptions.clientId = "String"
                    
                    expect(ARTRest(options: clientOptions).options.clientId).to(equal("String"))
                }
                
                // RSA12
                it("should accept any clientId") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions, debug: true)
                    //options.tokenDetails = ARTAuthTokenDetails(clientId: "*")
                    let client = ARTRest(options: options)
                    print(client.auth.tokenDetails?.clientId)
                    
                    // TODO: no way to test '*' from Ably staging server
                }
                
                // RSA7b
                context("auth.clientId not null") {
                    // RSA7b1
                    it("when clientId attribute is assigned on client options") {
                        let clientOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                        clientOptions.clientId = "Exist"
                        
                        expect(ARTRest(options: clientOptions).auth.clientId).to(equal("Exist"))
                    }
                    
                    // RSA7b2
                    it("when tokenRequest or tokenDetails has clientId not null or wildcard string") {
                        let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                        options.clientId = "client_string"
                        
                        let client = ARTRest(options: options)
                        client.httpExecutor = mockExecutor
                        
                        // TokenDetails
                        waitUntil(timeout: 10) { done in
                            // Token
                            client.authorise { tokenDetails, error in
                                expect(tokenDetails).toNot(beNil(), description: "TokenDetails is nil")
                                expect(client.auth.clientId).to(equal(tokenDetails?.clientId))
                                done()
                            }
                        }
                        
                        // TokenRequest
                        switch extractBodyAsJSON(mockExecutor.requests.last) {
                        case .Failure(let error):
                            XCTFail(error)
                        case .Success(let httpBody):
                            guard let requestedClientId = httpBody.unbox["clientId"] as? String else { XCTFail("No clientId field in HTTPBody"); return }
                            expect(client.auth.clientId).to(equal(requestedClientId))
                        }
                    }
                    
                    // RSA7b3
                    // TODO: Realtime.connection
                }
                
                // RSA7c
                it("should clientId be null or string") {
                    let clientOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    clientOptions.clientId = "*"
                    
                    expect{ ARTRest(options: clientOptions) }.to(raiseException())
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
                        
                        let httpBodyJSON = try! NSJSONSerialization.JSONObjectWithData(request.HTTPBody ?? NSData(), options: .MutableLeaves) as? NSDictionary
                        
                        expect(httpBodyJSON).toNot(beNil(), description: "HTTPBody is empty")
                        expect(httpBodyJSON!["timestamp"]).toNot(beNil(), description: "HTTPBody has no timestamp")
                        
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
