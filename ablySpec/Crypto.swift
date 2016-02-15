//
//  Crypto.swift
//  ably
//
//  Created by Toni Cárdenas on 12/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Nimble
import Quick
import SwiftyJSON

class Crypto : QuickSpec {
    override func spec() {
        describe("Crypto") {
            for keyLength in ["128", "256"] {
                context("with fixtures from crypto-data-\(keyLength).json") {
                    let (key, iv, items) = AblyTests.loadCryptoTestData("ably-common/test-resources/crypto-data-\(keyLength).json")
                    let logger = ARTLog.init()
                    let decoder = ARTDataEncoder.init(cipherParams: nil, logger: logger)
                    let cipherParams = ARTCipherParams.init(
                        algorithm: "aes",
                        keySpec: key,
                        ivSpec: ARTIvParameterSpec.init(iv: iv)
                    )

                    func extractMessage(fixture: AblyTests.CryptoTestItem.TestMessage) -> ARTMessage {
                        let msg = ARTMessage.init(data: fixture.data, name: fixture.name)
                        msg.encoding = fixture.encoding
                        return msg
                    }

                    it("should encrypt messages as expected in the fixtures") {
                        for item in items {
                            let encrypter = ARTDataEncoder.init(cipherParams: cipherParams, logger: logger)

                            let fixture = extractMessage(item.encoded)
                            let encryptedFixture = extractMessage(item.encrypted)

                            var error: NSError?
                            let decoded = fixture.decodeWithEncoder(decoder, error: &error) as! ARTMessage
                            expect(error).to(beNil())

                            let encrypted = decoded.encodeWithEncoder(encrypter, error: &error)
                            expect(error).to(beNil())

                            print("FIXTURE", fixture)
                            print("ENCRYPTED FIXTURE", encryptedFixture)
                            print("ENCRYPTED", encrypted)
                            expect(encrypted as? ARTMessage).to(equal(encryptedFixture))
                        }
                    }

                    it("should decrypt messages as expected in the fixtures") {
                        for item in items {
                            let encrypter = ARTDataEncoder.init(cipherParams: cipherParams, logger: logger)

                            let fixture = extractMessage(item.encoded)
                            let encryptedFixture = extractMessage(item.encrypted)

                            var error: NSError?
                            let decoded = fixture.decodeWithEncoder(decoder, error: &error) as! ARTMessage
                            expect(error).to(beNil())

                            let decrypted = encryptedFixture.decodeWithEncoder(encrypter, error: &error)
                            expect(error).to(beNil())

                            expect(decrypted as? ARTMessage).to(equal(decoded))
                        }
                    }
                }
            }
        }
    }
}