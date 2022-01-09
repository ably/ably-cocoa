import Ably
import Nimble
import XCTest

private var rest: ARTRest!
private var mockHttpExecutor: MockHTTPExecutor!

private let recipient = [
    "clientId": "bob",
]

private let payload = [
    "notification": [
        "title": "Welcome",
    ],
]

class PushAdminTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        let options = AblyTests.commonAppSetup()
        options.pushFullWait = true
        options.dispatchQueue = AblyTests.userQueue
        let rest = ARTRest(options: options)
        rest.internal.storage = MockDeviceStorage()
    }

    override class func tearDown() {
        let options = AblyTests.commonAppSetup()
        options.dispatchQueue = AblyTests.userQueue
        let rest = ARTRest(options: options)
        rest.internal.storage = MockDeviceStorage()
        super.tearDown()
    }

    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = rest
        _ = mockHttpExecutor
        _ = recipient
        _ = payload

        return super.defaultTestSuite
    }

    override func setUp() {
        super.setUp()

        rest = ARTRest(key: "xxxx:xxxx")
        mockHttpExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHttpExecutor
    }

    // RSH1a

    func test__001__publish__should_perform_an_HTTP_request_to__push_publish() {
        waitUntil(timeout: testTimeout) { done in
            rest.push.admin.publish(recipient, data: payload) { error in
                expect(error).to(beNil())
                done()
            }
        }

        guard let request = mockHttpExecutor.requests.first else {
            fail("Request is missing"); return
        }
        guard let url = request.url else {
            fail("URL is missing"); return
        }

        expect(url.absoluteString).to(contain("/push/publish"))

        switch extractBodyAsMsgPack(request) {
        case let .failure(error):
            XCTFail(error)
        case let .success(httpBody):
            guard let bodyRecipient = httpBody.unbox["recipient"] as? [String: String] else {
                fail("recipient is missing"); return
            }
            expect(bodyRecipient).to(equal(recipient))

            guard let bodyPayload = httpBody.unbox["notification"] as? [String: String] else {
                fail("notification is missing"); return
            }
            expect(bodyPayload).to(equal(payload["notification"]))
        }
    }

    func skipped__test__002__publish__should_publish_successfully() {
        let options = AblyTests.commonAppSetup()
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:push_admin_publish-ok")
        let publishObject = ["transportType": "ablyChannel",
                             "channel": channel.name,
                             "ablyKey": options.key!,
                             "ablyUrl": "https://\(options.restHost)"]

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.subscribe("__ably_push__") { message in
                guard let data = message.data as? String else {
                    fail("Failure in reading returned data"); partialDone(); return
                }
                expect(data).to(contain("foo"))
                partialDone()
            }
            realtime.push.admin.publish(publishObject, data: ["data": ["foo": "bar"]]) { error in
                expect(error).to(beNil())
                partialDone()
            }
        }
    }

    func skipped__test__003__publish__should_fail_with_a_bad_recipient() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:push_admin_publish-bad-recipient")

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish(["foo": "bar"], data: ["data": ["foo": "bar"]]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.statusCode) == 400
                expect(error.message).to(contain("recipient must contain"))
                done()
            }
        }
    }

    func skipped__test__004__publish__should_fail_with_an_empty_recipient() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:push_admin_publish-empty-recipient")

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish([:], data: ["data": ["foo": "bar"]]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.message.lowercased()).to(contain("recipient is missing"))
                done()
            }
        }
    }

    func test__005__publish__should_fail_with_an_empty_payload() {
        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
        defer { realtime.dispose(); realtime.close() }
        let channel = realtime.channels.get("pushenabled:push_admin_publish-empty-payload")

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                expect(error).to(beNil())
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.subscribe("__ably_push__") { _ in
                fail("Should not be called")
            }
            realtime.push.admin.publish(["ablyChannel": channel.name], data: [:]) { error in
                guard let error = error else {
                    fail("Error is missing"); done(); return
                }
                expect(error.message.lowercased()).to(contain("data payload is missing"))
                done()
            }
        }
    }
}
