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
            //TODO: not implemented

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
            
            // RSA5
            it("should use one hour default time to live") {
                let tokenParams = ARTAuthTokenParams()
                expect(tokenParams.ttl) == 60 * 60
            }
            
            // RSA6
            it("should allow all operations when capability is not specified") {
                let tokenParams = ARTAuthTokenParams()
                expect(tokenParams.capability) == "{\"*\":[\"*\"]}"
            }
            
            // RSA7
            fit("should encode the clientId with utf8") {
                let clientId = "🚀"
                
                //clientId.utf8
                //clientId.utf16
                
                let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                let params = ARTAuthTokenParams()
                params.clientId = clientId
                
                // ?!
                //options.clientId = clientId
                
                let client = ARTRest(options: options)
                client.httpExecutor = mockExecutor
                
                client.auth.requestToken(params, withOptions: nil) { tokenDetails, error in }
                
                expect(mockExecutor.requests.first).toEventuallyNot(beNil(), timeout: 5, description: "No request found")
                expect(mockExecutor.requests.first!.HTTPBody).toNot(beNil(), description: "No body")
                
                if let request = mockExecutor.requests.first,
                    body = request.HTTPBody,
                    json = try? NSJSONSerialization.JSONObjectWithData(body, options: .MutableLeaves),
                    httpBody = json as? NSDictionary {

                    print(httpBody["clientId"])
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
