//
//  Crypto.swift
//  ably
//
//  Created by Toni Cárdenas on 12/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick
import SwiftyJSON

class Crypto : QuickSpec {    
    override func spec() {
        describe("Crypto") {
            let key = "+/h4eHh4eHh4eHh4eHh4eA=="
            let binaryKey = Data(base64Encoded: key, options: .ignoreUnknownCharacters)!
            let longKey = NSMutableData(data: binaryKey)
            longKey.append(binaryKey)

            // RSE1
            context("getDefaultParams") {
                // RSE1a, RSE1b
                it("returns a complete CipherParams instance, using the default values for any field not supplied") {
                    expect{ARTCrypto.getDefaultParams(["nokey":"nokey"])}.to(raiseException())

                    var params: ARTCipherParams = ARTCrypto.getDefaultParams([
                        "key": key
                    ])
                    expect(params.algorithm).to(equal("AES"))
                    expect(params.key).to(equal(binaryKey as Data))
                    expect(params.keyLength).to(equal(128))
                    expect(params.mode).to(equal("CBC"))

                    params = ARTCrypto.getDefaultParams([
                        "key": longKey,
                        "algorithm": "DES"
                    ])
                    expect(params.algorithm).to(equal("DES"))
                    expect(params.key).to(equal(longKey as Data))
                    expect(params.keyLength).to(equal(256))
                    expect(params.mode).to(equal("CBC"))
                }

                // RSE1c
                context("key parameter") {
                    it("can be a binary") {
                        let params = ARTCrypto.getDefaultParams(["key": binaryKey])
                        expect(params.key).to(equal(binaryKey as Data))
                    }

                    it("can be a base64-encoded string with standard encoding") {
                        let params = ARTCrypto.getDefaultParams(["key": key])
                        expect(params.key).to(equal(binaryKey as Data))
                    }

                    it("can be a base64-encoded string with URL encoding") {
                        let key = "-_h4eHh4eHh4eHh4eHh4eA=="
                        let params = ARTCrypto.getDefaultParams(["key": key])
                        expect(params.key).to(equal(binaryKey as Data))
                    }
                }

                // RSE1d
                it("calculates a keyLength from the key (its size in bits)") {
                    var params = ARTCrypto.getDefaultParams(["key": binaryKey])
                    expect(params.keyLength).to(equal(128))

                    params = ARTCrypto.getDefaultParams(["key": longKey])
                    expect(params.keyLength).to(equal(256))
                }

                // RSE1e
                it("should check that keyLength is valid for algorithm") {
                    expect{ARTCrypto.getDefaultParams([
                        "key": binaryKey.subdata(in: 0..<10)
                    ])}.to(raiseException())
                }

            }

            // RSE2
            context("generateRandomKey") {
                // RSE2a, RSE2b
                it("takes a single length argument and returns a binary") {
                    var key: NSData = ARTCrypto.generateRandomKey(128) as NSData
                    expect(key.length).to(equal(128 / 8))

                    key = ARTCrypto.generateRandomKey(256) as NSData
                    expect(key.length).to(equal(256 / 8))
                }

                // RSE2a, RSE2b
                it("takes no arguments and returns the default algorithm's default length") {
                    let key: NSData = ARTCrypto.generateRandomKey() as NSData
                    expect(key.length).to(equal(256 / 8))
                }
            }

            context("generateHashSHA256") {
                it("takes data and returns a SHA256 digest") {
                    let string = "The quick brown fox jumps over the lazy dog"
                    let expectedHash = "D7A8FBB307D7809469CA9ABCB0082E4F8D5651E46D3CDB762D02D0BF37C9E592" //hex
                    let stringData = string.data(using: .utf8)!
                    let result = ARTCrypto.generateHashSHA256(stringData)
                    expect(result.hexString).to(equal(expectedHash))
                }
            }

            context("encrypt") {
                it("should generate a new IV every time it's called, and should be the first block encrypted") {
                    let params = ARTCipherParams(algorithm: "aes", key: key as ARTCipherKeyCompatible)
                    let cipher = ARTCrypto.cipher(with: params)
                    let data = "data".data(using: String.Encoding.utf8)!

                    var distinctOutputs = Set<NSData>()
                    var output: NSData?

                    for _ in 0..<3 {
                        cipher.encrypt(data, output:&output)
                        distinctOutputs.insert(output!)

                        let firstBlock = output!.subdata(with: NSMakeRange(0, Int((cipher as! ARTCbcCipher).blockLength)))
                        let paramsWithIV = ARTCipherParams(algorithm: "aes", key: key as ARTCipherKeyCompatible, iv: firstBlock)
                        var sameOutput: NSData?
                        ARTCrypto.cipher(with: paramsWithIV).encrypt(data, output:&sameOutput)

                        expect(output!).to(equal(sameOutput!))
                    }

                    expect(distinctOutputs.count).to(equal(3))
                }
            }

            for cryptoFixture in CryptoTest.fixtures {
                context("with fixtures from \(cryptoFixture.fileName).json") {
                    let (key, iv, items) = AblyTests.loadCryptoTestData(cryptoFixture.fileName)
                    let decoder = ARTDataEncoder.init(cipherParams: nil, error: nil)
                    let cipherParams = ARTCipherParams(algorithm: "aes", key: key as ARTCipherKeyCompatible, iv: iv)
                    let encrypter = ARTDataEncoder.init(cipherParams: cipherParams, error: nil)

                    func extractMessage(_ fixture: AblyTests.CryptoTestItem.TestMessage) -> ARTMessage {
                        let msg = ARTMessage(name: fixture.name, data: fixture.data)
                        msg.encoding = fixture.encoding
                        return msg
                    }

                    it("should encrypt messages as expected in the fixtures") {
                        for item in items {
                            let fixture = extractMessage(item.encoded)
                            let encryptedFixture = extractMessage(item.encrypted)
                            expect(encryptedFixture.encoding).to(endWith("\(cryptoFixture.expectedEncryptedEncoding)/base64"))

                            var error: NSError?
                            let decoded = fixture.decode(with: decoder, error: &error) as! ARTMessage
                            expect(error).to(beNil())
                            expect(decoded).notTo(beNil())

                            let encrypted = decoded.encode(with: encrypter, error: &error)
                            expect(error).to(beNil())
                            expect(encrypted).notTo(beNil())

                            expect((encrypted as! ARTMessage)).to(equal(encryptedFixture))
                        }
                    }

                    it("should decrypt messages as expected in the fixtures") {
                        for item in items {
                            let fixture = extractMessage(item.encoded)
                            let encryptedFixture = extractMessage(item.encrypted)
                            expect(encryptedFixture.encoding).to(endWith("\(cryptoFixture.expectedEncryptedEncoding)/base64"))

                            var error: NSError?
                            let decoded = fixture.decode(with: decoder, error: &error) as! ARTMessage
                            expect(error).to(beNil())
                            expect(decoded).notTo(beNil())

                            let decrypted = encryptedFixture.decode(with: encrypter, error: &error)
                            expect(error).to(beNil())
                            expect(decrypted).notTo(beNil())
                            
                            expect((decrypted as! ARTMessage)).to(equal(decoded))
                        }
                    }
                }
            }
        }
    }
}
