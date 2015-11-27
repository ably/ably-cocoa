//
//  Auth.swift
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import Aspects

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
                
                waitUntil(timeout: testTimeout) { done in
                    client.channels.get("test").publish("message") { error in
                        done()
                    }
                }

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
                    let options = AblyTests.clientOptions(requestToken: true)
                    
                    // Check HTTP
                    options.tls = false
                    let clientHTTP = ARTRest(options: options)
                    clientHTTP.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        clientHTTP.channels.get("test").publish("message") { error in
                            done()
                        }
                    }
                    
                    expect(mockExecutor.requests.first).toNot(beNil(), description: "No request found")
                    expect(mockExecutor.requests.first?.URL).toNot(beNil(), description: "Request is invalid")
                    
                    if let request = mockExecutor.requests.first, let url = request.URL {
                        expect(url.scheme).to(equal("http"), description: "No HTTP support")
                    }

                    // Check HTTPS
                    options.tls = true
                    let clientHTTPS = ARTRest(options: options)
                    clientHTTPS.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        clientHTTPS.channels.get("test").publish("message") { error in
                            done()
                        }
                    }
                    
                    expect(mockExecutor.requests.last).toNot(beNil(), description: "No request found")
                    expect(mockExecutor.requests.last?.URL).toNot(beNil(), description: "Request is invalid")
                    
                    if let request = mockExecutor.requests.last, let url = request.URL {
                        expect(url.scheme).to(equal("https"), description: "No HTTPS support")
                    }
                }
                
                // RSA3b
                it("should send the token in the Authorization header") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken()

                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("test").publish("message") { error in
                            done()
                        }
                    }

                    expect(client.options.token).toNot(beNil(), description: "No access token")

                    if let currentToken = client.options.token {
                        let expectedAuthorization = "Bearer \(encodeBase64(currentToken))"
                        
                        expect(mockExecutor.requests.first).toNot(beNil(), description: "No request found")
                        
                        let authorization = mockExecutor.requests.first?.allHTTPHeaderFields?["Authorization"] ?? ""
                        
                        expect(authorization).to(equal(expectedAuthorization))
                    }
                }
                
                // RSA3c
                it("should send the token in the Authorization header") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                        expect(query).to(haveParam("accessToken", withValue: client.auth().tokenDetails?.token ?? ""))
                    }
                    else {
                        XCTFail("MockTransport is not working")
                    }

                    client.close()
                }
            }

            // RSA4
            context("authentication method") {
                for (caseName, caseSetter) in AblyTests.authTokenCases {
                    it("should be default auth method when \(caseName) is set") {
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
                context("should check clientId consistency") {

                    it("on rest") {
                        let expectedClientId = "client_string"
                        let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                        options.clientId = expectedClientId

                        let client = ARTRest(options: options)
                        client.httpExecutor = mockExecutor

                        waitUntil(timeout: testTimeout) { done in
                            // Token
                            client.calculateAuthorization(ARTAuthMethod.Token) { token, error in
                                if let e = error {
                                    XCTFail(e.description)
                                }
                                expect(client.auth.clientId).to(equal(expectedClientId))
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
                    }

                    it("on realtime") {
                        let expectedClientId = "client_string"
                        let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                        options.clientId = expectedClientId
                        options.autoConnect = false

                        let client = ARTRealtime(options: options)
                        defer {
                            client.close()
                        }
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()

                        waitUntil(timeout: testTimeout) { done in
                            client.eventEmitter.on({ state, error in
                                if state == .Connected && error == nil {
                                    let currentChannel = client.channel("test")
                                    currentChannel.subscribe({ message, errorInfo in
                                        done()
                                    })
                                    currentChannel.publish("ping", cb:nil)
                                }
                            })
                        }

                        let transport = client.transport as! TestProxyTransport
                        guard let connectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .Connected }).last else {
                            XCTFail("No CONNECTED protocol action received"); return
                        }

                        // CONNECTED ProtocolMessage
                        expect(connectedMessage.connectionDetails.clientId).to(equal(expectedClientId))
                    }

                    it("with wildcard") {
                        let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                        options.clientId = "*"
                        expect{ ARTRest(options: options) }.to(raiseException())
                        expect{ ARTRealtime(options: options) }.to(raiseException())
                    }
                }
                
                // RSA15b
                it("should permit to be unauthenticated") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = nil
                    
                    let clientBasic = ARTRest(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        // Basic
                        clientBasic.calculateAuthorization(ARTAuthMethod.Basic) { token, error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            expect(clientBasic.auth.clientId).to(beNil())
                            options.tokenDetails = clientBasic.auth.tokenDetails
                            done()
                        }
                    }

                    let clientToken = ARTRest(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        // Last TokenDetails
                        clientToken.calculateAuthorization(ARTAuthMethod.Token) { token, error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            expect(clientToken.auth.clientId).to(beNil())
                            done()
                        }
                    }

                    // TODO: Realtime.connectionDetails
                }
                
                // RSA15c
                it("should cancel request when clientId is invalid") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)

                    let client = ARTRest(options: options)

                    // FIXME: Implemented validation of invalid chars
                    
                    // Check unquoted
                    let clientIdQuoted = "\"client_string\""
                    options.clientId = clientIdQuoted

                    waitUntil(timeout: testTimeout) { done in
                        // Token
                        client.calculateAuthorization(ARTAuthMethod.Token) { token, error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            expect(client.auth.clientId).to(beNil())
                            done()
                        }
                    }
                    
                    // Check unescaped
                    let clientIdBreaklined = "client_string\n"
                    options.clientId = clientIdBreaklined

                    waitUntil(timeout: testTimeout) { done in
                        // Token
                        client.calculateAuthorization(ARTAuthMethod.Token) { token, error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            expect(client.auth.clientId).to(beNil())
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
                
                waitUntil(timeout: testTimeout) { done in
                    // Token
                    ARTRest(options: options).auth.requestToken(tokenParams, withOptions: options) { tokenDetails, error in
                        if let e = error {
                            XCTFail(e.description)
                        }
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
                    
                    waitUntil(timeout: testTimeout) { done in
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
                it("should obtain a token if clientId is assigned") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    options.clientId = "client_string"
                    
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
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
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
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
                            client.calculateAuthorization(ARTAuthMethod.Token) { token, error in
                                if let e = error {
                                    XCTFail(e.description)
                                }
                                expect(client.auth.clientId).to(equal(options.clientId))
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
                        expect(url.absoluteString).to(contain(NSURL(string: "http://auth.ably.io")?.absoluteString ?? ""))
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
                        
                        let expectedJSON = ["ttl":NSString(format: "%f", CGFloat(60*60)), "capability":"{\"*\":[\"*\"]}", "timestamp":httpBodyJSON!["timestamp"]!]
                        
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
                    expect(url.absoluteString).to(contain(NSURL(string: "http://auth.ably.io")?.absoluteString ?? ""))
                }
            }

            // RSA8a
            it("implicitly creates a TokenRequest and requests a token") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                var createTokenRequestMethodWasCalled = false

                let block: @convention(block) (AspectInfo, tokenParams: ARTAuthTokenParams?) -> Void = { _, _ in
                    createTokenRequestMethodWasCalled = true
                }

                let hook = ARTAuth.aspect_hookSelector(rest.auth)
                // Adds a block of code after `createTokenRequest` is triggered
                let token = try? hook("createTokenRequest:options:callback:", withOptions: .PositionAfter, usingBlock:  unsafeBitCast(block, ARTAuth.self))

                expect(token).toNot(beNil())

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails?.token).toNot(beEmpty())
                        done()
                    })
                }

                expect(createTokenRequestMethodWasCalled).to(beTrue())
            }

            // RSA8b
            context("should support all TokenParams") {

                let options = AblyTests.commonAppSetup()
                let currentCliend = "client_string"
                options.clientId = currentCliend

                let rest = ARTRest(options: options)

                it("using defaults") {
                    // Default values
                    let defaultTokenParams = ARTAuthTokenParams(clientId: currentCliend)

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                            expect(tokenDetails?.clientId).to(equal(defaultTokenParams.clientId))
                            expect(tokenDetails?.capability).to(equal(defaultTokenParams.capability))
                            expect(tokenDetails?.issued).toNot(beNil())
                            expect(tokenDetails?.expires).toNot(beNil())
                            if let issued = tokenDetails?.issued, let expires = tokenDetails?.expires {
                                expect(expires.timeIntervalSinceDate(issued)).to(equal(defaultTokenParams.ttl))
                            }
                            done()
                        })
                    }
                }

                it("overriding defaults") {
                    // Custom values
                    let expectedClientId = "token_client"
                    let expectedTtl = 4800.0
                    let expectedCapability = "{\"canpublish:*\":[\"publish\"]}"

                    let tokenParams = ARTAuthTokenParams(clientId: expectedClientId)
                    tokenParams.ttl = expectedTtl
                    tokenParams.capability = expectedCapability

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(tokenParams, withOptions: nil, callback: { tokenDetails, error in
                            expect(tokenDetails?.clientId).to(equal(expectedClientId))
                            expect(tokenDetails?.capability).to(equal(expectedCapability))
                            expect(tokenDetails?.issued).toNot(beNil())
                            expect(tokenDetails?.expires).toNot(beNil())
                            if let issued = tokenDetails?.issued, let expires = tokenDetails?.expires {
                                expect(expires.timeIntervalSinceDate(issued)).to(equal(expectedTtl))
                            }
                            done()
                        })
                    }
                }

            }
        }

        // RSA10
        describe("authorise") {

            // RSA10a
            it("should create a token if needed and use it") {
                let options = AblyTests.commonAppSetup()
                var validToken: String?

                // Create a new token
                waitUntil(timeout: testTimeout) { done in
                    let rest = ARTRest(options: options)

                    rest.auth.authorise(nil, options: nil, callback: { tokenDetails, error in
                        expect(rest.auth.method).to(equal(ARTAuthMethod.Token))
                        expect(tokenDetails).toNot(beNil())
                        expect(tokenDetails?.token).toNot(beEmpty())

                        if let token = tokenDetails?.token {
                            validToken = token
                        }

                        publishTestMessage(rest, completion: { error in
                            expect(error).to(beNil())
                            done()
                        })
                    })
                }

                guard let currentToken = validToken else { return }

                waitUntil(timeout: testTimeout) { done in
                    // New client with Basic auth
                    let rest = ARTRest(options: options)
                    publishTestMessage(rest, completion: { error in
                        expect(error).to(beNil())
                        expect(rest.auth.method).to(equal(ARTAuthMethod.Basic))

                        // Reuse the valid token
                        rest.auth.setTokenDetails(ARTAuthTokenDetails(token: currentToken))
                        rest.auth.authorise(nil, options: nil, callback: { tokenDetails, error in
                            expect(rest.auth.method).to(equal(ARTAuthMethod.Token))
                            expect(tokenDetails?.token).to(equal(currentToken))

                            publishTestMessage(rest, completion: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        })
                    })
                }
            }

            // RSA10b
            it("should supports all TokenParams and AuthOptions") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(ARTAuthTokenParams(), options: ARTAuthOptions(), callback: { tokenDetails, error in
                        expect(error).to(beNil())
                        done()
                    })
                }
            }

            // RSA10c
            it("should create a new token when no token exists or current token has expired") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                let tokenParams = ARTAuthTokenParams()
                tokenParams.ttl = 3.0 //Seconds

                // FIXME: buffer of 15s for token expiry

                var expiredToken: String?

                // No token exists
                expect(rest.auth.tokenDetails?.token).to(beNil())

                // Created token
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(tokenParams, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        expect(tokenDetails?.token).toNot(beEmpty())

                        if let token = tokenDetails?.token {
                            // Delay for token expiration
                            delay(tokenParams.ttl) {
                                expiredToken = token
                                done()
                            }
                        }
                        else {
                            done()
                        }
                    }
                }

                // Token exists
                expect(rest.auth.tokenDetails?.token).toNot(beNil())

                // New token
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        expect(tokenDetails?.token).toNot(equal(expiredToken))
                        done()
                    }
                }
            }

            // RSA10d
            it("should issue a new token even if an existing token exists when AuthOption.force is true") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())
                var validToken: String?

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails?.token).toNot(beEmpty())
                        if let token = tokenDetails?.token {
                            validToken = token
                        }
                        done()
                    }
                }

                guard let currentToken = validToken else { return }

                // Current token
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails?.token).to(equal(currentToken))
                        done()
                    }
                }

                let authOptions = ARTAuthOptions()
                authOptions.force = true

                // Force new token
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: authOptions) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails?.token).toNot(equal(currentToken))
                        done()
                    }
                }
            }

            // RSA10f
            it("should return TokenDetails with valid token metadata") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "client_string"
                let rest = ARTRest(options: options)

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        expect(tokenDetails).to(beAnInstanceOf(ARTAuthTokenDetails))
                        expect(tokenDetails?.token).toNot(beEmpty())
                        expect(tokenDetails?.issued).toNot(beNil())
                        expect(tokenDetails?.expires).toNot(beNil())
                        expect(tokenDetails?.expires?.timeIntervalSince1970).to(beGreaterThan(tokenDetails?.issued?.timeIntervalSince1970))
                        expect(tokenDetails?.clientId).to(equal(options.clientId))
                        done()
                    }
                }
            }


        }
    }
}
