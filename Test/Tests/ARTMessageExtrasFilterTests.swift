import XCTest
import Ably

class ARTMessageExtrasFilterTests: XCTestCase {

    private func getFilter(clientId: String?, name: String?, isRef: Bool?, refType: String?, refTimeserial: String?) -> ARTMessageFilter
    {
        let filter = ARTMessageFilter()
        filter.clientId = clientId
        filter.name = name
        filter.isRef = nil
        filter.refType = refType
        filter.refTimeserial = refTimeserial

        if (isRef != nil) {
            filter.isRef = NSNumber.init(booleanLiteral: isRef!)
        }

        return filter
    }

    func test_itPassesWithNoFilter() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.clientId = "client"
        message.name = "name"

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithAllTheFilters() {
        let filter = getFilter(clientId: "client", name: "name", isRef: true, refType: "refType", refTimeserial: "fooserial")
        let message = ARTMessage()
        message.clientId = "client"
        message.name = "name"
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithClientIdFilter() {
        let filter = getFilter(clientId: "client", name: nil, isRef: nil, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.clientId = "client"

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithClientIdFilter() {
        let filter = getFilter(clientId: "client2", name: nil, isRef: nil, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.clientId = "client"

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithNameFilter() {
        let filter = getFilter(clientId: nil, name: "name", isRef: nil, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.name = "name"

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithNameFilter() {
        let filter = getFilter(clientId: nil, name: "name", isRef: nil, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.name = "name2"

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithIsRefFilterTrue() {
        let filter = getFilter(clientId: nil, name: nil, isRef: true, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithIsRefFilterTrueNoTimeserial() {
        let filter = getFilter(clientId: nil, name: nil, isRef: true, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithIsRefFilterTrueNoType() {
        let filter = getFilter(clientId: nil, name: nil, isRef: true, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithIsRefFilterTrueNoRef() {
        let filter = getFilter(clientId: nil, name: nil, isRef: true, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = NSDictionary() as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithIsRefFilterTrueNoExtras() {
        let filter = getFilter(clientId: nil, name: nil, isRef: true, refType: nil, refTimeserial: nil)
        let message = ARTMessage()

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithIsRefFilterFalseNoTimeserial() {
        let filter = getFilter(clientId: nil, name: nil, isRef: false, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithIsRefFilterFalseNoType() {
        let filter = getFilter(clientId: nil, name: nil, isRef: false, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithIsRefFilterFalseNoRef() {
        let filter = getFilter(clientId: nil, name: nil, isRef: false, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = NSDictionary() as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithIsRefFilterFalseNoExtras() {
        let filter = getFilter(clientId: nil, name: nil, isRef: false, refType: nil, refTimeserial: nil)
        let message = ARTMessage()

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithIsRefFilterComplete() {
        let filter = getFilter(clientId: nil, name: nil, isRef: false, refType: nil, refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithTimeserialFilter() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTimeserialFilter() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial2"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTimeserialFilterNoTimeserial() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTimeserialFilterNoType() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()
        message.extras = ["ref": ["timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTimeserialFilterNoRef() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()
        message.extras = NSDictionary() as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTimeserialFilterNoExtras() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: nil, refTimeserial: "fooserial")
        let message = ARTMessage()

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itPassesWithTypeFilter() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType", "timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertTrue(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTyoeFilter() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType2", "timeserial": "fooserial2"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTypeFilterNoTimeserial() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["type": "refType"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTypeFilterNoType() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()
        message.extras = ["ref": ["timeserial": "fooserial"]] as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTypeFilterNoRef() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()
        message.extras = NSDictionary() as ARTJsonCompatible

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }

    func test_itFailsWithTypeFilterNoExtras() {
        let filter = getFilter(clientId: nil, name: nil, isRef: nil, refType: "refType", refTimeserial: nil)
        let message = ARTMessage()

        let messageExtrasFilter = ARTMessageExtrasFilter(filter: filter)
        XCTAssertFalse(messageExtrasFilter.onMessage(message))
    }
}
