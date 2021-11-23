import Ably
import Nimble
import Quick
import SwiftyJSON
            private let key = "+/h4eHh4eHh4eHh4eHh4eA=="
            private let binaryKey = Data(base64Encoded: key, options: .ignoreUnknownCharacters)!
            private let longKey = binaryKey + binaryKey

class Crypto : XCTestCase {    

override class var defaultTestSuite : XCTestSuite {
    let _ = key
    let _ = binaryKey
    let _ = longKey

    return super.defaultTestSuite
}

        

            // RSE1
            
                // RSE1a, RSE1b
                func test__001__Crypto__getDefaultParams__returns_a_complete_CipherParams_instance__using_the_default_values_for_any_field_not_supplied() {
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
                
                    func test__004__Crypto__getDefaultParams__key_parameter__can_be_a_binary() {
                        let params = ARTCrypto.getDefaultParams(["key": binaryKey])
                        expect(params.key).to(equal(binaryKey as Data))
                    }

                    func test__005__Crypto__getDefaultParams__key_parameter__can_be_a_base64_encoded_string_with_standard_encoding() {
                        let params = ARTCrypto.getDefaultParams(["key": key])
                        expect(params.key).to(equal(binaryKey as Data))
                    }

                    func test__006__Crypto__getDefaultParams__key_parameter__can_be_a_base64_encoded_string_with_URL_encoding() {
                        let key = "-_h4eHh4eHh4eHh4eHh4eA=="
                        let params = ARTCrypto.getDefaultParams(["key": key])
                        expect(params.key).to(equal(binaryKey as Data))
                    }

                // RSE1d
                func test__002__Crypto__getDefaultParams__calculates_a_keyLength_from_the_key__its_size_in_bits_() {
                    var params = ARTCrypto.getDefaultParams(["key": binaryKey])
                    expect(params.keyLength).to(equal(128))

                    params = ARTCrypto.getDefaultParams(["key": longKey])
                    expect(params.keyLength).to(equal(256))
                }

                // RSE1e
                func test__003__Crypto__getDefaultParams__should_check_that_keyLength_is_valid_for_algorithm() {
                    expect{ARTCrypto.getDefaultParams([
                        "key": binaryKey.subdata(in: 0..<10)
                    ])}.to(raiseException())
                }

            // RSE2
            
                // RSE2a, RSE2b
                func test__007__Crypto__generateRandomKey__takes_a_single_length_argument_and_returns_a_binary() {
                    var key: NSData = ARTCrypto.generateRandomKey(128) as NSData
                    expect(key.length).to(equal(128 / 8))

                    key = ARTCrypto.generateRandomKey(256) as NSData
                    expect(key.length).to(equal(256 / 8))
                }

                // RSE2a, RSE2b
                func test__008__Crypto__generateRandomKey__takes_no_arguments_and_returns_the_default_algorithm_s_default_length() {
                    let key: NSData = ARTCrypto.generateRandomKey() as NSData
                    expect(key.length).to(equal(256 / 8))
                }

            
                func test__009__Crypto__generateHashSHA256__takes_data_and_returns_a_SHA256_digest() {
                    let string = "The quick brown fox jumps over the lazy dog"
                    let expectedHash = "D7A8FBB307D7809469CA9ABCB0082E4F8D5651E46D3CDB762D02D0BF37C9E592" //hex
                    let stringData = string.data(using: .utf8)!
                    let result = ARTCrypto.generateHashSHA256(stringData)
                    expect(result.hexString).to(equal(expectedHash))
                }

            
                func test__010__Crypto__encrypt__should_generate_a_new_IV_every_time_it_s_called__and_should_be_the_first_block_encrypted() {
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
enum TestCase_ReusableTestsTestFixture {
case should_encrypt_messages_as_expected_in_the_fixtures
case should_decrypt_messages_as_expected_in_the_fixtures
}


            func reusableTestsTestFixture(_ cryptoFixture: ( fileName: String, expectedEncryptedEncoding: String, keyLength: UInt), testCase: TestCase_ReusableTestsTestFixture, context: (beforeEach: (() -> ())?, afterEach: (() -> ())?)) {
                let (key, iv, items) = AblyTests.loadCryptoTestData(cryptoFixture.fileName)
                let decoder = ARTDataEncoder.init(cipherParams: nil, error: nil)
                let cipherParams = ARTCipherParams(algorithm: "aes", key: key as ARTCipherKeyCompatible, iv: iv)
                let encrypter = ARTDataEncoder.init(cipherParams: cipherParams, error: nil)
                
                func extractMessage(_ fixture: AblyTests.CryptoTestItem.TestMessage) -> ARTMessage {
                    let msg = ARTMessage(name: fixture.name, data: fixture.data)
                    msg.encoding = fixture.encoding
                    return msg
                }
                
                func test__should_encrypt_messages_as_expected_in_the_fixtures() {
context.beforeEach?()

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
context.afterEach?()

                }
                
                func test__should_decrypt_messages_as_expected_in_the_fixtures() {
context.beforeEach?()

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
context.afterEach?()

                }

switch testCase  {
case .should_encrypt_messages_as_expected_in_the_fixtures:
    test__should_encrypt_messages_as_expected_in_the_fixtures()
case .should_decrypt_messages_as_expected_in_the_fixtures:
    test__should_decrypt_messages_as_expected_in_the_fixtures()
}

            }

            
                func test__Crypto__with_fixtures_from_crypto_data_128_json__reusableTestsTestFixture(testCase: TestCase_ReusableTestsTestFixture) {
                reusableTestsTestFixture(("crypto-data-128",  "cipher+aes-128-cbc", 128), testCase: testCase, context: (beforeEach: nil, afterEach: nil))}
func test__011__Crypto__with_fixtures_from_crypto_data_128_json__should_encrypt_messages_as_expected_in_the_fixtures() {
test__Crypto__with_fixtures_from_crypto_data_128_json__reusableTestsTestFixture(testCase: .should_encrypt_messages_as_expected_in_the_fixtures)
}

func test__012__Crypto__with_fixtures_from_crypto_data_128_json__should_decrypt_messages_as_expected_in_the_fixtures() {
test__Crypto__with_fixtures_from_crypto_data_128_json__reusableTestsTestFixture(testCase: .should_decrypt_messages_as_expected_in_the_fixtures)
}


            
                func test__Crypto__with_fixtures_from_crypto_data_256_json__reusableTestsTestFixture(testCase: TestCase_ReusableTestsTestFixture) {
                reusableTestsTestFixture(("crypto-data-256",  "cipher+aes-256-cbc", 256), testCase: testCase, context: (beforeEach: nil, afterEach: nil))}
func test__013__Crypto__with_fixtures_from_crypto_data_256_json__should_encrypt_messages_as_expected_in_the_fixtures() {
test__Crypto__with_fixtures_from_crypto_data_256_json__reusableTestsTestFixture(testCase: .should_encrypt_messages_as_expected_in_the_fixtures)
}

func test__014__Crypto__with_fixtures_from_crypto_data_256_json__should_decrypt_messages_as_expected_in_the_fixtures() {
test__Crypto__with_fixtures_from_crypto_data_256_json__reusableTestsTestFixture(testCase: .should_decrypt_messages_as_expected_in_the_fixtures)
}

}
