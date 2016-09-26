//
//  Auth.swift
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import AblyRealtime
import Nimble
import Quick
import Aspects

class Auth : QuickSpec {
    override func spec() {
        
        struct ExpectedTokenParams {
            static let clientId = "client_from_params"
            static let ttl = 5.0
            static let capability = "{\"cansubscribe:*\":[\"subscribe\"]}"
        }
        
        var testHTTPExecutor: TestProxyHTTPExecutor!
        
        beforeEach {
            testHTTPExecutor = TestProxyHTTPExecutor()
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
                client.httpExecutor = testHTTPExecutor
                
                waitUntil(timeout: testTimeout) { done in
                    client.channels.get("test").publish(nil, data: "message") { error in
                        done()
                    }
                }

                let key64 = NSString(string: "\(client.options.key!)")
                    .dataUsingEncoding(NSUTF8StringEncoding)!
                    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                                
                let expectedAuthorization = "Basic \(key64)"
                
                guard let request = testHTTPExecutor.requests.first else {
                    fail("No request found")
                    return
                }
                
                let authorization = request.allHTTPHeaderFields?["Authorization"]
                
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
                it("should work over HTTP") {
                    let options = AblyTests.clientOptions(requestToken: true)
                    options.tls = false
                    let clientHTTP = ARTRest(options: options)
                    clientHTTP.httpExecutor = testHTTPExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        clientHTTP.channels.get("test").publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    guard let request = testHTTPExecutor.requests.first else {
                        fail("No request found")
                        return
                    }
                    guard let url = request.URL else {
                        fail("Request is invalid")
                        return
                    }
                    expect(url.scheme).to(equal("http"), description: "No HTTP support")
                }

                it("should work over HTTPS") {
                    let options = AblyTests.clientOptions(requestToken: true)
                    options.tls = true
                    let clientHTTPS = ARTRest(options: options)
                    clientHTTPS.httpExecutor = testHTTPExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        clientHTTPS.channels.get("test").publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    guard let request = testHTTPExecutor.requests.first else {
                        fail("No request found")
                        return
                    }
                    guard let url = request.URL else {
                        fail("Request is invalid")
                        return
                    }
                    expect(url.scheme).to(equal("https"), description: "No HTTPS support")
                }

                // RSA3b
                it("should send the token in the Authorization header") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken()

                    let client = ARTRest(options: options)
                    client.httpExecutor = testHTTPExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("test").publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    guard let currentToken = client.options.token else {
                        fail("No access token")
                        return
                    }

                    let expectedAuthorization = "Bearer \(encodeBase64(currentToken))"
                    
                    guard let request = testHTTPExecutor.requests.first else {
                        fail("No request found")
                        return
                    }

                    let authorization = request.allHTTPHeaderFields?["Authorization"]

                    expect(authorization).to(equal(expectedAuthorization))
                }
                
                // RSA3c
                it("should send the token in the Authorization header") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                        expect(query).to(haveParam("accessToken", withValue: client.auth.tokenDetails?.token ?? ""))
                    }
                    else {
                        XCTFail("MockTransport is not working")
                    }
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
                        client.httpExecutor = testHTTPExecutor

                        waitUntil(timeout: testTimeout) { done in
                            // Token
                            client.prepareAuthorisationHeader(ARTAuthMethod.Token) { token, error in
                                if let e = error {
                                    XCTFail(e.description)
                                }
                                expect(client.auth.clientId).to(equal(expectedClientId))
                                done()
                            }
                        }

                        switch extractBodyAsMsgPack(testHTTPExecutor.requests.first) {
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
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .Connected && error == nil {
                                    let currentChannel = client.channels.get("test")
                                    currentChannel.subscribe({ message in
                                        done()
                                    })
                                    currentChannel.publish(nil, data: "ping", callback:nil)
                                }
                            }
                        }

                        let transport = client.transport as! TestProxyTransport
                        guard let connectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .Connected }).last else {
                            XCTFail("No CONNECTED protocol action received"); return
                        }

                        // CONNECTED ProtocolMessage
                        expect(connectedMessage.connectionDetails!.clientId).to(equal(expectedClientId))
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
                        clientBasic.prepareAuthorisationHeader(ARTAuthMethod.Basic) { token, error in
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
                        clientToken.prepareAuthorisationHeader(ARTAuthMethod.Token) { token, error in
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
                context("Incompatible client") {

                    it("with Realtime, it should change the connection state to FAILED and emit an error") {
                        let options = AblyTests.commonAppSetup()
                        let wrongTokenDetails = getTestTokenDetails(clientId: "wrong")

                        options.clientId = "john"
                        options.autoConnect = false
                        options.authCallback = { tokenParams, completion in
                            completion(wrongTokenDetails, nil)
                        }
                        let realtime = ARTRealtime(options: options)
                        defer { realtime.close() }

                        waitUntil(timeout: testTimeout) { done in
                            realtime.connection.once(.Failed) { stateChange in
                                expect(stateChange!.reason!.code).to(equal(40102))
                                expect(stateChange!.reason!.description).to(contain("incompatible credentials"))
                                done()
                            }
                            realtime.connect()
                        }
                    }

                    it("with Rest, it should result in an appropriate error response") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "john"
                        let rest = ARTRest(options: options)

                        waitUntil(timeout: testTimeout) { done in
                            rest.auth.requestToken(ARTTokenParams(clientId: "wrong"), withOptions: nil) { tokenDetails, error in
                                expect(error!.code).to(equal(40102))
                                expect(error!.description).to(contain("incompatible credentials"))
                                expect(tokenDetails).to(beNil())
                                done()
                            }
                        }
                    }
                }
            }
            
            // RSA5
            it("should use one hour default time to live") {
                let tokenParams = ARTTokenParams()
                expect(tokenParams.ttl) == 60 * 60
            }
            
            // RSA6
            it("should allow all operations when capability is not specified") {
                let tokenParams = ARTTokenParams()
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
                    client.httpExecutor = testHTTPExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("test").publish(nil, data: "message") { error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            done()
                        }
                    }
                    
                    switch extractBodyAsMsgPack(testHTTPExecutor.requests.last) {
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
                    client.httpExecutor = testHTTPExecutor
                    
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("test").publish(nil, data: "message") { error in
                            if let e = error {
                                XCTFail(e.description)
                            }
                            done()
                        }
                    }
                    
                    let authorization = testHTTPExecutor.requests.last?.allHTTPHeaderFields?["Authorization"] ?? ""
                    
                    expect(authorization).toNot(equal(""))
                }
                
                // RSA7a3
                it("should convenience clientId return a string") {
                    let clientOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    clientOptions.clientId = "String"
                    
                    expect(ARTRest(options: clientOptions).options.clientId).to(equal("String"))
                }

                // RSA7a4
                it("ClientOptions#clientId takes precendence when a clientId value is provided in both ClientOptions#clientId and ClientOptions#defaultTokenParams") {
                    let options = AblyTests.clientOptions()
                    options.clientId = "john"
                    options.authCallback = { tokenParams, completion in
                        expect(tokenParams.clientId).to(equal(options.clientId))
                        completion(getTestToken(clientId: tokenParams.clientId), nil)
                    }
                    options.defaultTokenParams = ARTTokenParams(clientId: "tester")
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    expect(client.auth.clientId).to(equal("john"))
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            channel.history() { paginatedResult, error in
                                let message = paginatedResult!.items.first as! ARTMessage
                                expect(message.clientId).to(equal("john"))
                                done()
                            }
                        }
                    }
                }
                
                // RSA12
                context("Auth#clientId attribute is null") {

                    // RSA12a
                    it("identity should be anonymous for all operations") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let realtime = AblyTests.newRealtime(options)
                        defer { realtime.close() }
                        expect(realtime.auth.clientId).to(beNil())

                        waitUntil(timeout: testTimeout) { done in
                            realtime.connection.once(.Connected) { stateChange in
                                expect(stateChange!.reason).to(beNil())
                                expect(realtime.auth.clientId).to(beNil())
                                done()
                            }
                            realtime.connect()
                            
                            let transport = realtime.transport as! TestProxyTransport
                            transport.beforeProcessingReceivedMessage = { message in
                                if message.action == .Connected {
                                    if let details = message.connectionDetails {
                                        details.clientId = nil
                                    }
                                }
                            }
                        }
                    }

                    // RSA12b
                    it("identity may change and become identified") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.token = getTestToken(clientId: "tester")
                        let realtime = ARTRealtime(options: options)
                        defer { realtime.close() }
                        expect(realtime.auth.clientId).to(beNil())

                        waitUntil(timeout: testTimeout) { done in
                            realtime.connection.once(.Connecting) { stateChange in
                                expect(stateChange!.reason).to(beNil())
                                expect(realtime.auth.clientId).to(beNil())
                            }
                            realtime.connection.once(.Connected) { stateChange in
                                expect(stateChange!.reason).to(beNil())
                                expect(realtime.auth.clientId).to(equal("tester"))
                                done()
                            }
                            realtime.connect()
                        }
                    }

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
                        client.httpExecutor = testHTTPExecutor
                        
                        // TokenDetails
                        waitUntil(timeout: 10) { done in
                            // Token
                            client.prepareAuthorisationHeader(ARTAuthMethod.Token) { token, error in
                                if let e = error {
                                    XCTFail(e.description)
                                }
                                expect(client.auth.clientId).to(equal(options.clientId))
                                done()
                            }
                        }
                        
                        // TokenRequest
                        switch extractBodyAsMsgPack(testHTTPExecutor.requests.last) {
                        case .Failure(let error):
                            XCTFail(error)
                        case .Success(let httpBody):
                            guard let requestedClientId = httpBody.unbox["clientId"] as? String else { XCTFail("No clientId field in HTTPBody"); return }
                            expect(client.auth.clientId).to(equal(requestedClientId))
                        }
                    }
                    
                    // RSA7b3
                    it("should CONNECTED ProtocolMessages contain a clientId") {
                        let options = AblyTests.clientOptions()
                        options.token = getTestToken(clientId: "john")
                        expect(options.clientId).to(beNil())
                        options.autoConnect = false
                        let realtime = AblyTests.newRealtime(options)
                        defer { realtime.close() }

                        waitUntil(timeout: testTimeout) { done in
                            realtime.connection.once(.Connected) { stateChange in
                                expect(stateChange!.reason).to(beNil())
                                expect(realtime.auth.clientId).to(equal("john"))

                                let transport = realtime.transport as! TestProxyTransport
                                let connectedProtocolMessage = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0]
                                expect(connectedProtocolMessage.connectionDetails!.clientId).to(equal("john"))
                                done()
                            }
                            realtime.connect()
                        }
                    }

                    // RSA7b4
                    it("client does not have an identity when a wildcard string '*' is present") {
                        let options = AblyTests.clientOptions()
                        options.token = getTestToken(clientId: "*")
                        let realtime = ARTRealtime(options: options)
                        defer { realtime.close() }
                        waitUntil(timeout: testTimeout) { done in
                            realtime.connection.on(.Connected) { _ in
                                expect(realtime.auth.clientId).to(equal("*"))
                                done()
                            }
                        }
                    }

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
                it("should not merge with the configured params and options but instead replace all corresponding values, even when @null@") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "сlientId"
                    let rest = ARTRest(options: options)
                    
                    let tokenParams = ARTTokenParams()
                    tokenParams.ttl = 2000
                    tokenParams.capability = "{\"cansubscribe:*\":[\"subscribe\"]}"
                    
                    let precedenceOptions = AblyTests.commonAppSetup()
                    
                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(tokenParams, withOptions: precedenceOptions) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            expect(tokenDetails!.capability).to(equal("{\"cansubscribe:*\":[\"subscribe\"]}"))
                            expect(tokenDetails!.clientId).to(beNil())
                            expect(tokenDetails!.expires!.timeIntervalSince1970 - tokenDetails!.issued!.timeIntervalSince1970).to(equal(tokenParams.ttl))
                            done()
                        }
                    }
                    
                    let options2 = AblyTests.commonAppSetup()
                    options2.clientId = nil
                    let rest2 = ARTRest(options: options2)

                    let precedenceOptions2 = AblyTests.commonAppSetup()
                    precedenceOptions2.clientId = nil
                    
                    waitUntil(timeout: testTimeout) { done in
                        rest2.auth.requestToken(nil, withOptions: precedenceOptions2) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let aTokenDetails = tokenDetails else {
                                XCTFail("tokenDetails is nil"); done(); return
                            }
                            expect(aTokenDetails.clientId).to(beNil())
                            done()
                        }
                    }
                }
            }

            // RSA8c
            context("authUrl") {

                it("query will provide a token string") {
                    let testToken = getTestToken()

                    let options = ARTClientOptions()
                    options.authUrl = NSURL(string: "http://echo.ably.io")
                    expect(options.authUrl).toNot(beNil())
                    // Plain text
                    options.authParams = [NSURLQueryItem]()
                    options.authParams!.append(NSURLQueryItem(name: "type", value: "text"))
                    options.authParams!.append(NSURLQueryItem(name: "body", value: testToken))

                    let rest = ARTRest(options: options)
                    rest.httpExecutor = testHTTPExecutor

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                            expect(testHTTPExecutor.requests.last?.URL?.host).to(equal("echo.ably.io"))
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            expect(tokenDetails?.token).to(equal(testToken))
                            done()
                        })
                    }
                }

                it("query will provide a TokenDetails") {
                    guard let testTokenDetails = getTestTokenDetails(clientId: "tester") else {
                        fail("TokenDetails is empty")
                        return
                    }

                    let encoder = ARTJsonLikeEncoder()
                    encoder.delegate = ARTJsonEncoder()
                    guard let jsonTokenDetails = encoder.encodeTokenDetails(testTokenDetails) else {
                        fail("Invalid TokenDetails")
                        return
                    }

                    let options = ARTClientOptions()
                    options.authUrl = NSURL(string: "http://echo.ably.io")
                    expect(options.authUrl).toNot(beNil())
                    // JSON with TokenDetails
                    options.authParams = [NSURLQueryItem]()
                    options.authParams?.append(NSURLQueryItem(name: "type", value: "json"))
                    options.authParams?.append(NSURLQueryItem(name: "body", value: jsonTokenDetails.toUTF8String))

                    let rest = ARTRest(options: options)
                    rest.httpExecutor = testHTTPExecutor

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                            expect(testHTTPExecutor.requests.last?.URL?.host).to(equal("echo.ably.io"))
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            expect(tokenDetails?.clientId) == testTokenDetails.clientId
                            expect(tokenDetails?.capability) == testTokenDetails.capability
                            expect(tokenDetails?.issued).toNot(beNil())
                            expect(tokenDetails?.expires).toNot(beNil())
                            if let issued = tokenDetails?.issued, let testIssued = testTokenDetails.issued {
                                expect(issued.compare(testIssued)) == NSComparisonResult.OrderedSame
                            }
                            if let expires = tokenDetails?.expires, let testExpires = testTokenDetails.expires {
                                expect(expires.compare(testExpires)) == NSComparisonResult.OrderedSame
                            }
                            done()
                        })
                    }
                }

                it("query will provide a TokenRequest") {
                    let tokenParams = ARTTokenParams()
                    tokenParams.capability = "{\"test\":[\"subscribe\"]}"

                    let options = AblyTests.commonAppSetup()
                    options.authUrl = NSURL(string: "http://echo.ably.io")
                    expect(options.authUrl).toNot(beNil())

                    var rest = ARTRest(options: options)

                    var tokenRequest: ARTTokenRequest?
                    waitUntil(timeout: testTimeout) { done in
                        // Sandbox and valid TokenRequest
                        rest.auth.createTokenRequest(tokenParams, options: nil, callback: { newTokenRequest, error in
                            expect(error).to(beNil())
                            tokenRequest = newTokenRequest
                            done()
                        })
                    }

                    guard let testTokenRequest = tokenRequest else {
                        fail("TokenRequest is empty")
                        return
                    }

                    let encoder = ARTJsonLikeEncoder()
                    encoder.delegate = ARTJsonEncoder()
                    guard let jsonTokenRequest = encoder.encodeTokenRequest(testTokenRequest) else {
                        fail("Invalid TokenRequest")
                        return
                    }

                    // JSON with TokenRequest
                    options.authParams = [NSURLQueryItem]()
                    options.authParams?.append(NSURLQueryItem(name: "type", value: "json"))
                    options.authParams?.append(NSURLQueryItem(name: "body", value: jsonTokenRequest.toUTF8String))

                    rest = ARTRest(options: options)
                    rest.httpExecutor = testHTTPExecutor

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(nil, withOptions: nil, callback: { tokenDetails, error in
                            expect(testHTTPExecutor.requests.first?.URL?.host).to(equal("echo.ably.io"))
                            expect(testHTTPExecutor.requests.last?.URL?.host).toNot(equal("echo.ably.io"))
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is empty"); done()
                                return
                            }
                            expect(tokenDetails.token).toNot(beNil())
                            expect(tokenDetails.capability) == tokenParams.capability
                            done()
                        })
                    }
                }

                context("parameters") {
                    // RSA8c1a
                    it("should be added to the URL when auth method is GET") {
                        let clientOptions = ARTClientOptions()
                        clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                        var authParams = [
                            "param1": "value",
                            "param2": "value",
                            "clientId": "should not be overwritten",
                        ]
                        clientOptions.authParams = authParams.map {
                             NSURLQueryItem(name: $0, value: $1)
                        }
                        clientOptions.authHeaders = ["X-Header-1": "foo", "X-Header-2": "bar"]
                        let tokenParams = ARTTokenParams()
                        tokenParams.clientId = "test"

                        let rest = ARTRest(options: clientOptions)
                        let request = rest.auth.buildRequest(clientOptions, withParams: tokenParams)

                        for (header, expectedValue) in clientOptions.authHeaders! {
                            if let value = request.allHTTPHeaderFields?[header] {
                                expect(value).to(equal(expectedValue))
                            } else {
                                fail("Missing header in request: \(header), expected: \(expectedValue)")
                            }
                        }
                        
                        guard let url = request.URL else {
                            fail("Request is invalid")
                            return
                        }
                        guard let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
                            fail("invalid URL: \(url)")
                            return
                        }
                        expect(urlComponents.scheme).to(equal("http"))
                        expect(urlComponents.host).to(equal("auth.ably.io"))
                        guard let queryItems = urlComponents.queryItems else {
                            fail("URL without query: \(url)")
                            return
                        }
                        for queryItem in queryItems {
                            if var expectedValue = authParams[queryItem.name] {
                                if queryItem.name == "clientId" {
                                    expectedValue = "test"
                                }
                                expect(queryItem.value!).to(equal(expectedValue))
                                authParams.removeValueForKey(queryItem.name)
                            }
                        }
                        expect(authParams).to(beEmpty())
                    }
                    
                    // RSA8c1b
                    it("should added on the body request when auth method is POST") {
                        let clientOptions = ARTClientOptions()
                        clientOptions.authUrl = NSURL(string: "http://auth.ably.io")
                        clientOptions.authMethod = "POST"
                        clientOptions.authHeaders = ["X-Header-1": "foo", "X-Header-2": "bar"]
                        let tokenParams = ARTTokenParams()
                        
                        let rest = ARTRest(options: clientOptions)
                        
                        let request = rest.auth.buildRequest(clientOptions, withParams: tokenParams)
                        
                        let httpBodyJSON = try! NSJSONSerialization.JSONObjectWithData(request.HTTPBody ?? NSData(), options: .MutableLeaves) as? NSDictionary
                        
                        expect(httpBodyJSON).toNot(beNil(), description: "HTTPBody is empty")
                        expect(httpBodyJSON!["timestamp"]).toNot(beNil(), description: "HTTPBody has no timestamp")
                        
                        let expectedJSON = ["ttl":NSString(format: "%f", CGFloat(60*60)), "capability":"{\"*\":[\"*\"]}", "timestamp":httpBodyJSON!["timestamp"]!]
                        
                        expect(httpBodyJSON) == expectedJSON

                        for (header, expectedValue) in clientOptions.authHeaders! {
                            if let value = request.allHTTPHeaderFields?[header] {
                                expect(value).to(equal(expectedValue))
                            } else {
                                fail("Missing header in request: \(header), expected: \(expectedValue)")
                            }
                        }
                    }
                }

                // RSA8c2
                it("TokenParams should take precedence over any configured authParams when a name conflict occurs") {
                    let options = ARTClientOptions()
                    options.clientId = "john"
                    options.authUrl = NSURL(string: "http://auth.ably.io")
                    options.authMethod = "GET"
                    options.authHeaders = ["X-Header-1": "foo1", "X-Header-2": "foo2"]
                    let authParams = [
                        "key": "secret",
                        "clientId": "should be overridden"
                    ]
                    options.authParams = authParams.map { NSURLQueryItem(name: $0, value: $1) }

                    let tokenParams = ARTTokenParams()
                    tokenParams.clientId = "tester"

                    let client = ARTRest(options: options)
                    client.httpExecutor = testHTTPExecutor

                    waitUntil(timeout: testTimeout) { done in
                        client.auth.requestToken(tokenParams, withOptions: nil) { tokenDetails, error in
                            let query = testHTTPExecutor.requests[0].URL!.query
                            expect(query).to(haveParam("clientId", withValue: tokenParams.clientId!))
                            done()
                        }
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
                    
                    let url = rest.auth.buildURL(authOptions, withParams: ARTTokenParams())
                    expect(url.absoluteString).to(contain(NSURL(string: "http://auth.ably.io")?.absoluteString ?? ""))
                }
            }

            // RSA8a
            it("implicitly creates a TokenRequest and requests a token") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                var createTokenRequestMethodWasCalled = false

                let block: @convention(block) (AspectInfo, tokenParams: ARTTokenParams?) -> Void = { _, _ in
                    createTokenRequestMethodWasCalled = true
                }

                let hook = ARTAuth.aspect_hookSelector(rest.auth)
                // Adds a block of code after `createTokenRequest` is triggered
                let token = try? hook(#selector(ARTAuth.createTokenRequest(_:options:callback:)), withOptions: .PositionAfter, usingBlock:  unsafeBitCast(block, ARTAuth.self))

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
                let currentClientId = "client_string"
                options.clientId = currentClientId

                let rest = ARTRest(options: options)

                it("using defaults") {
                    // Default values
                    let defaultTokenParams = ARTTokenParams(clientId: currentClientId)

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
                    let expectedTtl = 4800.0
                    let expectedCapability = "{\"canpublish:*\":[\"publish\"]}"

                    let tokenParams = ARTTokenParams(clientId: currentClientId)
                    tokenParams.ttl = expectedTtl
                    tokenParams.capability = expectedCapability

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(tokenParams, withOptions: nil, callback: { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails?.clientId).to(equal(options.clientId))
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

            // RSA8d
            context("When authCallback option is set, it will invoke the callback") {

                it("with a token string") {
                    let options = AblyTests.clientOptions()
                    let expectedTokenParams = ARTTokenParams()

                    options.authCallback = { tokenParams, completion in
                        expect(tokenParams.clientId).to(beNil())
                        completion("token_string", nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.requestToken(expectedTokenParams, withOptions: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails!.token).to(equal("token_string"))
                            done()
                        }
                    }
                }

                it("with a TokenDetails") {
                    let expectedTokenParams = ARTTokenParams()

                    let options = AblyTests.clientOptions()
                    options.authCallback = { tokenParams, completion in
                        expect(tokenParams.clientId).to(beNil())
                        completion(ARTTokenDetails(token: "token_from_details"), nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.requestToken(expectedTokenParams, withOptions: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails!.token).to(equal("token_from_details"))
                            done()
                        }
                    }
                }

                it("with a TokenRequest") {
                    let options = AblyTests.commonAppSetup()
                    let expectedTokenParams = ARTTokenParams()
                    expectedTokenParams.clientId = "foo"
                    var rest: ARTRest!

                    options.authCallback = { tokenParams, completion in
                        expect(tokenParams.clientId).to(beIdenticalTo(expectedTokenParams.clientId))
                        rest.auth.createTokenRequest(tokenParams, options: options) { tokenRequest, error in
                            completion(tokenRequest, error)
                        }
                    }

                    rest = ARTRest(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(expectedTokenParams, withOptions: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("tokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails.clientId).to(equal(expectedTokenParams.clientId))
                            done()
                        }
                    }
                }
            }

            // RSA8f1
            it("ensure the message published does not have a clientId") {
                let options = AblyTests.commonAppSetup()
                options.token = getTestToken(clientId: nil)
                let rest = ARTRest(options: options)
                rest.httpExecutor = testHTTPExecutor
                let channel = rest.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    let message = ARTMessage(name: nil, data: "message without an explicit clientId")
                    expect(message.clientId).to(beNil())
                    channel.publish([message]) { error in
                        expect(error).to(beNil())
                        switch extractBodyAsMessages(testHTTPExecutor.requests.first) {
                        case .Failure(let error):
                            fail(error)
                        case .Success(let httpBody):
                            expect(httpBody.unbox.first!["clientId"]).to(beNil())
                        }
                        channel.history { page, error in
                            expect(error).to(beNil())
                            expect(page!.items).to(haveCount(1))
                            expect((page!.items[0] as! ARTMessage).clientId).to(beNil())
                            done()
                        }
                    }
                }
                expect(rest.auth.clientId).to(beNil())
            }

            // RSA8f2
            it("ensure that the message is rejected") {
                let options = AblyTests.commonAppSetup()
                options.token = getTestToken(clientId: nil)
                let rest = ARTRest(options: options)
                let channel = rest.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    let message = ARTMessage(name: nil, data: "message with an explicit clientId", clientId: "john")
                    channel.publish([message]) { error in
                        expect(error!.message).to(contain("mismatched clientId"))
                        done()
                    }
                }
                expect(rest.auth.clientId).to(beNil())
            }

            // RSA8f3
            it("ensure the message published with a wildcard '*' does not have a clientId") {
                let options = AblyTests.commonAppSetup()
                let rest = ARTRest(options: options)

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(ARTTokenParams(clientId: "*"), options: nil) { _, error in
                        expect(error).to(beNil())
                        done()
                    }
                }

                rest.httpExecutor = testHTTPExecutor
                let channel = rest.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    let message = ARTMessage(name: nil, data: "no client")
                    expect(message.clientId).to(beNil())
                    channel.publish([message]) { error in
                        expect(error).to(beNil())
                        switch extractBodyAsMessages(testHTTPExecutor.requests.first) {
                        case .Failure(let error):
                            fail(error)
                        case .Success(let httpBody):
                            expect(httpBody.unbox.first!["clientId"]).to(beNil())
                        }
                        channel.history { page, error in
                            expect(error).to(beNil())
                            expect(page!.items).to(haveCount(1))
                            expect((page!.items[0] as! ARTMessage).clientId).to(beNil())
                            done()
                        }
                    }
                }
                expect(rest.auth.clientId).to(equal("*"))
            }

            // RSA8f4
            it("ensure the message published with a wildcard '*' has the provided clientId") {
                let options = AblyTests.commonAppSetup()
                // Request a token with a wildcard '*' value clientId
                options.token = getTestToken(clientId: "*")
                let rest = ARTRest(options: options)
                let channel = rest.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    let message = ARTMessage(name: nil, data: "message with an explicit clientId", clientId: "john")
                    channel.publish([message]) { error in
                        expect(error).to(beNil())
                        channel.history { page, error in
                            expect(error).to(beNil())
                            let item = page!.items[0] as! ARTMessage
                            expect(item.clientId).to(equal("john"))
                            done()
                        }
                    }
                }
                expect(rest.auth.clientId).to(beNil())
            }
        }

        // RSA9
        describe("createTokenRequest") {
            // RSA9h
            it("should supersede any configured params and options when TokenParams and AuthOptions were provided") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "client_string"
                let rest = ARTRest(options: options)

                let tokenParams = ARTTokenParams()
                let defaultTtl = tokenParams.ttl
                let defaultCapability = tokenParams.capability

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.createTokenRequest(nil, options: nil) { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("tokenRequest is nil"); done(); return
                        }
                        expect(tokenRequest.clientId).to(equal(options.clientId))
                        expect(tokenRequest.ttl).to(equal(defaultTtl))
                        expect(tokenRequest.capability).to(equal(defaultCapability))
                        done()
                    }
                }

                tokenParams.ttl = ExpectedTokenParams.ttl
                tokenParams.capability = ExpectedTokenParams.capability
                tokenParams.clientId = nil

                let authOptions = ARTAuthOptions()
                authOptions.force = true
                authOptions.queryTime = true

                var serverDate = NSDate()
                waitUntil(timeout: testTimeout) { done in
                    rest.time { date, error in
                        expect(error).to(beNil())
                        guard let date = date else {
                            XCTFail("No server time"); done(); return
                        }
                        serverDate = date
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.createTokenRequest(tokenParams, options: authOptions) { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenRequest.clientId).to(beNil())
                        expect(tokenRequest.timestamp).to(beCloseTo(serverDate, within: 1.0)) //1 Second
                        expect(tokenRequest.ttl).to(equal(ExpectedTokenParams.ttl))
                        expect(tokenRequest.capability).to(equal(ExpectedTokenParams.capability))
                        done()
                    }
                }
            }

            // RSA9a
            it("should create and sign a TokenRequest") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())
                let expectedClientId = "client_string"
                let tokenParams = ARTTokenParams(clientId: expectedClientId)

                rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                    expect(error).to(beNil())
                    guard let tokenRequest = tokenRequest else {
                        XCTFail("TokenRequest is nil"); return
                    }
                    expect(tokenRequest).to(beAnInstanceOf(ARTTokenRequest))
                    expect(tokenRequest.clientId).to(equal(expectedClientId))
                    expect(tokenRequest.mac).toNot(beNil())
                    expect(tokenRequest.nonce).toNot(beNil())
                })
            }

            // RSA9b
            it("should support AuthOptions") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())
                let auth: ARTAuth = rest.auth

                let authOptions = ARTAuthOptions(key: "key:secret")

                auth.createTokenRequest(nil, options: authOptions, callback: { tokenRequest, error in
                    expect(error).to(beNil())
                    guard let tokenRequest = tokenRequest else {
                        XCTFail("TokenRequest is nil"); return
                    }
                    expect(tokenRequest.keyName).to(equal("key"))
                })
            }

            // RSA9c
            it("should generate a unique 16+ character nonce if none is provided") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                waitUntil(timeout: testTimeout) { done in
                    // First
                    rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest1 = tokenRequest else {
                            XCTFail("TokenRequest1 is nil"); done(); return
                        }
                        expect(tokenRequest1.nonce.characters).to(haveCount(16))

                        // Second
                        rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                            expect(error).to(beNil())
                            guard let tokenRequest2 = tokenRequest else {
                                XCTFail("TokenRequest2 is nil"); done(); return
                            }
                            expect(tokenRequest2.nonce.characters).to(haveCount(16))

                            // Uniqueness
                            expect(tokenRequest1.nonce).toNot(equal(tokenRequest2.nonce))
                            done()
                        })
                    })
                }
            }

            // RSA9d
            context("should generate a timestamp") {

                it("from current time if not provided") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())

                    rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("TokenRequest is nil"); return
                        }
                        expect(tokenRequest.timestamp).to(beCloseTo(NSDate(), within: 1.0))
                    })
                }

                it("will retrieve the server time if queryTime is true") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())

                    var serverTimeRequestWasMade = false
                    let block: @convention(block) (AspectInfo) -> Void = { _ in
                        serverTimeRequestWasMade = true
                    }

                    let hook = ARTRest.aspect_hookSelector(rest)
                    // Adds a block of code after `time` is triggered
                    let _ = try? hook(#selector(ARTRest.time(_:)), withOptions: .PositionAfter, usingBlock:  unsafeBitCast(block, ARTRest.self))

                    let authOptions = ARTAuthOptions()
                    authOptions.queryTime = true

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.createTokenRequest(nil, options: authOptions, callback: { tokenRequest, error in
                            expect(error).to(beNil())
                            guard let tokenRequest = tokenRequest else {
                                XCTFail("TokenRequest is nil"); return
                            }
                            expect(tokenRequest.timestamp).toNot(beNil())
                            expect(serverTimeRequestWasMade).to(beTrue())
                            done()
                        })
                    }
                }
            }

            // RSA9e
            context("TTL") {

                it("should be optional") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())

                    rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("TokenRequest is nil"); return
                        }
                        //In Seconds because TTL property is a NSTimeInterval but further it does the conversion to milliseconds
                        expect(tokenRequest.ttl).to(equal(ARTDefault.ttl()))
                    })

                    let tokenParams = ARTTokenParams()
                    expect(tokenParams.ttl).to(equal(ARTDefault.ttl()))

                    let expectedTtl = NSTimeInterval(10)
                    tokenParams.ttl = expectedTtl

                    rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("TokenRequest is nil"); return
                        }
                        expect(tokenRequest.ttl).to(equal(expectedTtl))
                    })
                }

                it("should be specified in milliseconds") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())

                    rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest = tokenRequest else {
                            XCTFail("TokenRequest is nil"); return
                        }
                        expect(tokenRequest.ttl).to(equal(ARTDefault.ttl()))
                        // Check if the encoder changes the TTL to milliseconds
                        let encoder = rest.defaultEncoder as! ARTJsonLikeEncoder
                        let data = encoder.encodeTokenRequest(tokenRequest)
                        let jsonObject = encoder.delegate!.decode(data!) as! NSDictionary
                        let ttl = jsonObject["ttl"] as! NSNumber
                        expect(ttl).to(equal(60 * 60 * 1000))
                    })
                }

                it("should be valid to request a token for 24 hours") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())
                    let tokenParams = ARTTokenParams()
                    tokenParams.ttl *= 24

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.requestToken(tokenParams, withOptions: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            let dayInSeconds = 24 * 60 * 60
                            expect(tokenDetails.expires!.timeIntervalSinceDate(tokenDetails.issued!)).to(beCloseTo(dayInSeconds))
                            done()
                        }
                    }
                }

            }

            // RSA9f
            it("should provide capability has json text") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                let tokenParams = ARTTokenParams()
                tokenParams.capability = "{ - }"

                rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                    guard let error = error else {
                        XCTFail("Error is nil"); return
                    }
                    expect(error.description).to(contain("Capability"))
                    expect(tokenRequest?.capability).to(beNil())
                })

                let expectedCapability = "{ \"cansubscribe:*\":[\"subscribe\"] }"
                tokenParams.capability = expectedCapability

                rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                    expect(error).to(beNil())
                    guard let tokenRequest = tokenRequest else {
                        XCTFail("TokenRequest is nil"); return
                    }
                    expect(tokenRequest.capability).to(equal(expectedCapability))
                })
            }

            // RSA9g
            it("should generate a valid HMAC") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                let tokenParams = ARTTokenParams(clientId: "client_string")

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                        expect(error).to(beNil())
                        guard let tokenRequest1 = tokenRequest else {
                            XCTFail("TokenRequest is nil"); done(); return
                        }
                        let signed = tokenParams.sign(rest.options.key!, withNonce: tokenRequest1.nonce)
                        expect(tokenRequest1.mac).to(equal(signed.mac))

                        rest.auth.createTokenRequest(tokenParams, options: nil, callback: { tokenRequest, error in
                            expect(error).to(beNil())
                            guard let tokenRequest2 = tokenRequest else {
                                XCTFail("TokenRequest is nil"); done(); return
                            }
                            expect(tokenRequest2.nonce).toNot(equal(tokenRequest1.nonce))
                            expect(tokenRequest2.mac).toNot(equal(tokenRequest1.mac))
                            done()
                        })
                    })
                }
            }

            // RSA9i
            it("should respect all requirements") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())
                let expectedClientId = "client_string"
                let tokenParams = ARTTokenParams(clientId: expectedClientId)
                let expectedTtl = 6.0
                tokenParams.ttl = expectedTtl
                let expectedCapability = "{}"
                tokenParams.capability = expectedCapability

                let authOptions = ARTAuthOptions()
                authOptions.queryTime = true

                var serverTime: NSDate?
                waitUntil(timeout: testTimeout) { done in
                    rest.time({ date, error in
                        serverTime = date
                        done()
                    })
                }
                expect(serverTime).toNot(beNil(), description: "Server time is nil")

                rest.auth.createTokenRequest(tokenParams, options: authOptions, callback: { tokenRequest, error in
                    expect(error).to(beNil())
                    guard let tokenRequest = tokenRequest else {
                        XCTFail("TokenRequest is nil"); return
                    }
                    expect(tokenRequest.clientId).to(equal(expectedClientId))
                    expect(tokenRequest.mac).toNot(beNil())
                    expect(tokenRequest.nonce.characters).to(haveCount(16))
                    expect(tokenRequest.ttl).to(equal(expectedTtl))
                    expect(tokenRequest.capability).to(equal(expectedCapability))
                    expect(tokenRequest.timestamp).to(beCloseTo(serverTime!, within: 6.0))
                })
            }

        }

        // RSA10
        describe("authorise") {

            // RSA10a
            it("should create a token if needed and use it") {
                let options = AblyTests.clientOptions(requestToken: true)
                waitUntil(timeout: testTimeout) { done in
                    // Client with Token
                    let rest = ARTRest(options: options)
                    publishTestMessage(rest, completion: { error in
                        expect(error).to(beNil())
                        expect(rest.auth.method).to(equal(ARTAuthMethod.Token))

                        // Reuse the valid token
                        rest.auth.authorise(nil, options: nil, callback: { tokenDetails, error in
                            expect(rest.auth.method).to(equal(ARTAuthMethod.Token))
                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails.token).to(equal(options.token))

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
                    rest.auth.authorise(ARTTokenParams(), options: ARTAuthOptions(), callback: { tokenDetails, error in
                        expect(error).to(beNil())
                        done()
                    })
                }
            }

            // RSA10c
            it("should create a new token when no token exists or current token has expired") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                let tokenParams = ARTTokenParams()
                tokenParams.ttl = 3.0 //Seconds

                // FIXME: buffer of 15s for token expiry

                // No token exists
                expect(rest.auth.tokenDetails?.token).to(beNil())

                waitUntil(timeout: testTimeout) { done in
                    // Create token
                    rest.auth.authorise(tokenParams, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        expect(tokenDetails?.token).toNot(beEmpty())

                        let expiredToken = tokenDetails?.token
                        // New token
                        delay(tokenParams.ttl + 1.0) {
                            rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                                expect(error).to(beNil())
                                guard let tokenDetails = tokenDetails else {
                                    XCTFail("TokenDetails is nil"); done(); return
                                }
                                expect(tokenDetails.token).toNot(equal(expiredToken))
                                done()
                            }
                        }
                    }
                }
            }

            // RSA10d
            it("should issue a new token even if an existing token exists when AuthOption.force is true") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                let authOptions = ARTAuthOptions()
                authOptions.force = true

                // Current token
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails?.token).toNot(beNil())

                        let currentToken = tokenDetails?.token

                        rest.auth.authorise(nil, options: authOptions) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails.token).toNot(equal(currentToken))
                            done()
                        }
                    }
                }
            }

            // RSA10e
            it("should use the requestToken implementation") {
                let rest = ARTRest(options: AblyTests.commonAppSetup())

                var requestMethodWasCalled = false
                let block: @convention(block) (AspectInfo) -> Void = { _ in
                    requestMethodWasCalled = true
                }

                let hook = ARTAuth.aspect_hookSelector(rest.auth)
                // Adds a block of code after `requestToken` is triggered
                let token = try? hook(#selector(ARTAuth.requestToken(_:withOptions:callback:)), withOptions: .PositionAfter, usingBlock:  unsafeBitCast(block, ARTAuth.self))

                expect(token).toNot(beNil())

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil, callback: { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails.token).toNot(beEmpty())
                        done()
                    })
                }

                expect(requestMethodWasCalled).to(beTrue())
            }

            // RSA10f
            it("should return TokenDetails with valid token metadata") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "client_string"
                let rest = ARTRest(options: options)

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails).to(beAnInstanceOf(ARTTokenDetails))
                        expect(tokenDetails.token).toNot(beEmpty())
                        expect(tokenDetails.expires!.timeIntervalSinceNow).to(beGreaterThan(tokenDetails.issued!.timeIntervalSinceNow))
                        expect(tokenDetails.clientId).to(equal(options.clientId))
                        done()
                    }
                }
            }

            // RSA10g
            context("on subsequent authorisations") {

                it("should store the AuthOptions with authUrl") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())
                    rest.httpExecutor = testHTTPExecutor
                    let auth = rest.auth

                    let token = getTestToken()
                    let authOptions = ARTAuthOptions()
                    // Use authUrl for authentication with plain text token response
                    authOptions.authUrl = NSURL(string: "http://echo.ably.io")!
                    authOptions.authParams = [NSURLQueryItem]()
                    authOptions.authParams?.append(NSURLQueryItem(name: "type", value: "text"))
                    authOptions.authParams?.append(NSURLQueryItem(name: "body", value: token))
                    authOptions.authHeaders = ["X-Ably":"Test"]
                    authOptions.force = true

                    waitUntil(timeout: testTimeout) { done in
                        auth.authorise(nil, options: authOptions) { tokenDetails, error in
                            expect(error).to(beNil())

                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails.token).to(equal(token))

                            auth.authorise(nil, options: nil) { tokenDetails, error in
                                expect(error).to(beNil())

                                guard let tokenDetails = tokenDetails else {
                                    XCTFail("TokenDetails is nil"); done(); return
                                }
                                expect(testHTTPExecutor.requests.last?.URL?.host).to(equal("echo.ably.io"))
                                expect(auth.options.force).to(beFalse())
                                expect(auth.options.authUrl!.host).to(equal("echo.ably.io"))
                                expect(auth.options.authHeaders!["X-Ably"]).to(equal("Test"))
                                expect(tokenDetails.token).to(equal(token))
                                done()
                            }
                        }
                    }
                }

                it("should store the AuthOptions with authCallback") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())
                    let auth = rest.auth

                    var authCallbackHasBeenInvoked = false

                    let authOptions = ARTAuthOptions()
                    authOptions.authCallback = { tokenParams, completion in
                        authCallbackHasBeenInvoked = true
                        completion(ARTTokenDetails(token: "token"), nil)
                    }
                    authOptions.useTokenAuth = true
                    authOptions.queryTime = true

                    waitUntil(timeout: testTimeout) { done in
                        auth.authorise(nil, options: authOptions) { tokenDetails, error in
                            expect(authCallbackHasBeenInvoked).to(beTrue())

                            authCallbackHasBeenInvoked = false
                            let options = ARTAuthOptions()
                            options.force = true
                            auth.authorise(nil, options: options) { tokenDetails, error in
                                expect(authCallbackHasBeenInvoked).to(beTrue())
                                expect(auth.options.useTokenAuth).to(beTrue())
                                expect(auth.options.queryTime).to(beTrue())
                                done()
                            }
                        }
                    }
                }

                it("should store the TokenParams") {
                    let rest = ARTRest(options: AblyTests.commonAppSetup())

                    let tokenParams = ARTTokenParams()
                    tokenParams.clientId = ExpectedTokenParams.clientId
                    tokenParams.ttl = ExpectedTokenParams.ttl
                    tokenParams.capability = ExpectedTokenParams.capability

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.authorise(tokenParams, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        delay(tokenParams.ttl + 1.0) {
                            rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                                expect(error).to(beNil())
                                guard let tokenDetails = tokenDetails else {
                                    XCTFail("TokenDetails is nil"); done(); return
                                }
                                expect(tokenDetails.clientId).to(equal(ExpectedTokenParams.clientId))
                                expect(tokenDetails.issued!.dateByAddingTimeInterval(ExpectedTokenParams.ttl)).to(beCloseTo(tokenDetails.expires))
                                expect(tokenDetails.capability).to(equal(ExpectedTokenParams.capability))
                                done()
                            }
                        }
                    }
                }

            }

            // RSA10h
            it("should use the configured Auth#clientId, if not null, by default") {
                let options = AblyTests.commonAppSetup()

                // ClientId null
                waitUntil(timeout: testTimeout) { done in
                    ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails.clientId).to(beNil())
                        done()
                    }
                }

                options.clientId = "client_string"

                // ClientId not null
                waitUntil(timeout: testTimeout) { done in
                    ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails.clientId).to(equal(options.clientId))
                        done()
                    }
                }
            }

            // RSA10i
            context("should adhere to all requirements relating to") {

                it("TokenParams") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    let rest = ARTRest(options: options)

                    let tokenParams = ARTTokenParams()
                    tokenParams.clientId = ExpectedTokenParams.clientId
                    tokenParams.ttl = ExpectedTokenParams.ttl
                    tokenParams.capability = ExpectedTokenParams.capability

                    waitUntil(timeout: testTimeout) { done in
                        rest.auth.authorise(tokenParams, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails).to(beAnInstanceOf(ARTTokenDetails))
                            expect(tokenDetails.token).toNot(beEmpty())
                            expect(tokenDetails.clientId).to(equal(ExpectedTokenParams.clientId))
                            expect(tokenDetails.issued!.dateByAddingTimeInterval(ExpectedTokenParams.ttl)).to(beCloseTo(tokenDetails.expires))
                            expect(tokenDetails.capability).to(equal(ExpectedTokenParams.capability))
                            done()
                        }
                    }
                }

                it("authCallback") {
                    var currentTokenRequest: ARTTokenRequest? = nil

                    let rest = ARTRest(options: AblyTests.commonAppSetup())
                    rest.auth.createTokenRequest(nil, options: nil, callback: { tokenRequest, error in
                        currentTokenRequest = tokenRequest
                    })
                    expect(currentTokenRequest).toEventuallyNot(beNil(), timeout: testTimeout)

                    if currentTokenRequest == nil {
                        return
                    }

                    let options = AblyTests.clientOptions()
                    options.authCallback = { tokenParams, completion in
                        completion(currentTokenRequest!, nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                XCTFail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails).to(beAnInstanceOf(ARTTokenDetails))
                            expect(tokenDetails.token).toNot(beEmpty())
                            expect(tokenDetails.expires!.timeIntervalSinceNow).to(beGreaterThan(tokenDetails.issued!.timeIntervalSinceNow))
                            done()
                        }
                    }
                }

                it("authUrl") {
                    let options = ARTClientOptions()
                    options.authUrl = NSURL(string: "http://echo.ably.io")!

                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            expect(error?.code).to(equal(400)) //Bad request
                            expect(tokenDetails).to(beNil())
                            done()
                        }
                    }
                }

                it("authUrl with json") {
                    guard let tokenDetails = getTestTokenDetails() else {
                        XCTFail("TokenDetails is empty")
                        return
                    }

                    let encoder = ARTJsonLikeEncoder()
                    encoder.delegate = ARTJsonEncoder()
                    guard let tokenDetailsJSON = NSString(data: encoder.encodeTokenDetails(tokenDetails) ?? NSData(), encoding: NSUTF8StringEncoding) else {
                        XCTFail("JSON TokenDetails is empty")
                        return
                    }

                    let options = ARTClientOptions()
                    // Use authUrl for authentication with JSON TokenDetails response
                    options.authUrl = NSURL(string: "http://echo.ably.io")!
                    options.authParams = [NSURLQueryItem]()
                    options.authParams?.append(NSURLQueryItem(name: "type", value: "json"))
                    options.authParams?.append(NSURLQueryItem(name: "body", value: "[]"))

                    // Invalid TokenDetails
                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.code).to(equal(Int(ARTState.AuthUrlIncompatibleContent.rawValue)))
                            expect(tokenDetails).to(beNil())
                            done()
                        }
                    }

                    options.authParams?.removeLast()
                    options.authParams?.append(NSURLQueryItem(name: "body", value: tokenDetailsJSON as String))

                    // Valid token
                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            done()
                        }
                    }
                }

                it("authUrl with plain text") {
                    let token = getTestToken()
                    let options = ARTClientOptions()
                    // Use authUrl for authentication with plain text token response
                    options.authUrl = NSURL(string: "http://echo.ably.io")!
                    options.authParams = [NSURLQueryItem]()
                    options.authParams?.append(NSURLQueryItem(name: "type", value: "text"))
                    options.authParams?.append(NSURLQueryItem(name: "body", value: ""))

                    // Invalid token
                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            expect(error).toNot(beNil())
                            expect(tokenDetails).to(beNil())
                            done()
                        }
                    }

                    options.authParams?.removeLast()
                    options.authParams?.append(NSURLQueryItem(name: "body", value: token))

                    // Valid token
                    waitUntil(timeout: testTimeout) { done in
                        ARTRest(options: options).auth.authorise(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())
                            done()
                        }
                    }
                }
                
            }

            // RSA10j
            it("should supersede any configured params and options when TokenParams and AuthOptions were provided") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "client_string"
                let rest = ARTRest(options: options)

                let tokenParams = ARTTokenParams(clientId: options.clientId)
                let defaultTtl = tokenParams.ttl
                let defaultCapability = tokenParams.capability

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(nil, options: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails.clientId).to(equal(options.clientId))
                        expect(tokenDetails.issued!.dateByAddingTimeInterval(defaultTtl)).to(beCloseTo(tokenDetails.expires))
                        expect(tokenDetails.capability).to(equal(defaultCapability))
                        done()
                    }
                }

                tokenParams.ttl = ExpectedTokenParams.ttl
                tokenParams.capability = ExpectedTokenParams.capability
                tokenParams.clientId = nil

                let authOptions = ARTAuthOptions()
                authOptions.force = true
                authOptions.queryTime = true

                var serverDate = NSDate()
                waitUntil(timeout: testTimeout) { done in
                    rest.time { date, error in
                        expect(error).to(beNil())
                        guard let date = date else {
                            XCTFail("No server time"); done(); return
                        }
                        serverDate = date
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    rest.auth.authorise(tokenParams, options: authOptions) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            XCTFail("TokenDetails is nil"); done(); return
                        }
                        expect(tokenDetails.issued).to(beCloseTo(serverDate, within: 1.0)) //1 Second
                        expect(tokenDetails.issued!.dateByAddingTimeInterval(ExpectedTokenParams.ttl)).to(beCloseTo(tokenDetails.expires))
                        expect(tokenDetails.capability).to(equal(ExpectedTokenParams.capability))
                        done()
                    }
                }
            }
        }

        describe("TokenParams") {
            context("timestamp") {
                it("if explicitly set, should be returned by the getter") {
                    let params = ARTTokenParams()
                    params.timestamp = NSDate(timeIntervalSince1970: 123)
                    expect(params.timestamp).to(equal(NSDate(timeIntervalSince1970: 123)))
                }

                it("if not explicitly set, should be generated at the getter and stick") {
                    let params = ARTTokenParams()

                    waitUntil(timeout: testTimeout) { done in
                        delay(0.25) {
                            let now = NSDate().artToIntegerMs()
                            let firstParamsTimestamp = params.timestamp.artToIntegerMs()
                            expect(firstParamsTimestamp).to(beCloseTo(now, within: 1.5))
                            delay(0.25) {
                                expect(params.timestamp.artToIntegerMs()).to(equal(firstParamsTimestamp))
                                done()
                            }
                        }
                    }
                }
            }
        }
        
        describe("Reauth") {
            // RTC8
            pending("should use authorise({force: true}) to reauth with a token with a different set of capabilities") {
                // init ARTRest
                let restOptions = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                let rest = ARTRest(options: restOptions)
                
                // get first token
                let tokenParams = ARTTokenParams()
                tokenParams.capability = "{\"wrongchannel\": [\"*\"]}"
                tokenParams.clientId = "testClientId"
                
                var firstToken = ""
                
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.requestToken(tokenParams, withOptions: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        firstToken = tokenDetails!.token
                        done()
                    }
                }
                expect(firstToken).toNot(beNil())
                expect(firstToken.characters.count > 0).to(beTrue())
                
                // init ARTRealtime
                let realtimeOptions = AblyTests.commonAppSetup()
                realtimeOptions.token = firstToken
                realtimeOptions.clientId = "testClientId"
                
                let realtime = ARTRealtime(options:realtimeOptions)
                defer { realtime.dispose(); realtime.close() }
                
                // wait for connected state
                waitUntil(timeout: testTimeout) { done in
                    realtime.connection.once(.Connected) { stateChange in
                        expect(stateChange!.reason).to(beNil())
                        expect(stateChange?.current).to(equal(realtime.connection.state))
                        done()
                    }
                    realtime.connect()
                }
                
                // create a `rightchannel` channel and check can't attach to it
                let channel = realtime.channels.get("rightchannel")
                
                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { error in
                        expect(error).toNot(beNil())
                        expect(error!.code).to(equal(40160))
                        done()
                    }
                }
                
                // get second token
                let secondTokenParams = ARTTokenParams()
                secondTokenParams.capability = "{\"wrongchannel\": [\"*\"], \"rightchannel\": [\"*\"]}"
                secondTokenParams.clientId = "testClientId"
                
                var secondToken = ""
                var secondTokenDetails: ARTTokenDetails?
                
                waitUntil(timeout: testTimeout) { done in
                    rest.auth.requestToken(secondTokenParams, withOptions: nil) { tokenDetails, error in
                        expect(error).to(beNil())
                        expect(tokenDetails).toNot(beNil())
                        
                        secondToken = tokenDetails!.token
                        secondTokenDetails = tokenDetails
                        done()
                    }
                }
                expect(secondToken).toNot(beNil())
                expect(secondToken.characters.count > 0).to(beTrue())
                expect(secondToken).toNot(equal(firstToken))
                
                // reauthorise
                let reauthOptions = ARTAuthOptions();
                reauthOptions.tokenDetails = secondTokenDetails
                reauthOptions.force = true
                
                waitUntil(timeout: testTimeout) { done in
                    realtime.auth.authorise(nil, options: reauthOptions) { reauthTokenDetails, error in
                        expect(error).to(beNil())
                        expect(reauthTokenDetails?.token).toNot(beNil())
                        done()
                    }
                }
                
                // re-attach to the channel
                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { error in
                        expect(error).to(beNil())
                        done()
                    }
                }
            }
        }
    }
}
