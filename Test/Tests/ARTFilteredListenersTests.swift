import XCTest
import Ably
import Ably.Private

class ARTFilteredListenersTests : XCTestCase {

    func test_itAddsAFilteredListener()
    {
        let listener = ARTEventListener();
        let filter = ARTMessageFilter();
        let filteredListeners = ARTFilteredListeners();

        filteredListeners.addFilteredListener(listener, filter:filter);

        let registeredListeners = filteredListeners.getFilteredListeners()
        XCTAssertEqual(1, registeredListeners.count)

        let pair = registeredListeners.object(at: 0) as! FilteredListenerFilterPair
        XCTAssertEqual(listener, pair.listener)
        XCTAssertEqual(filter, pair.filter)
    }

    func test_itClearsFilteredListeners()
    {
        let listener = ARTEventListener();
        let filter = ARTMessageFilter();
        let filteredListeners = ARTFilteredListeners();

        filteredListeners.addFilteredListener(listener, filter:filter);

        let registeredListeners = filteredListeners.getFilteredListeners()
        XCTAssertEqual(1, registeredListeners.count)
        filteredListeners.removeAllListeners()
        XCTAssertEqual(0, registeredListeners.count)
    }

    func test_itRemovesAListener()
    {
        let listener1 = ARTEventListener();
        let listener2 = ARTEventListener();
        let filter1 = ARTMessageFilter();
        let filter2 = ARTMessageFilter();
        let filteredListeners = ARTFilteredListeners();

        filteredListeners.addFilteredListener(listener1, filter:filter1);
        filteredListeners.addFilteredListener(listener2, filter:filter2);

        XCTAssertEqual(2, filteredListeners.getFilteredListeners().count);
        filteredListeners.removeFilteredListener(listener2)
        XCTAssertEqual(1, filteredListeners.getFilteredListeners().count)

        let retainedListener = filteredListeners.getFilteredListeners().object(at: 0) as! FilteredListenerFilterPair
        XCTAssertEqual(listener1, retainedListener.listener)
        XCTAssertEqual(filter1, retainedListener.filter)
    }

    func test_itDoesntRemoveAListener()
    {
        let listener1 = ARTEventListener();
        let listener2 = ARTEventListener();
        let filter1 = ARTMessageFilter();
        let filter2 = ARTMessageFilter();
        let filteredListeners = ARTFilteredListeners();

        filteredListeners.addFilteredListener(listener1, filter:filter1);
        filteredListeners.addFilteredListener(listener2, filter:filter2);

        XCTAssertEqual(2, filteredListeners.getFilteredListeners().count);
        filteredListeners.removeFilteredListener(ARTEventListener())
        XCTAssertEqual(2, filteredListeners.getFilteredListeners().count)
    }

    func test_itRemovesAllListenersForAFilter()
    {
        let listener1 = ARTEventListener();
        let listener2 = ARTEventListener();
        let listener3 = ARTEventListener();
        let listener4 = ARTEventListener();
        let listener5 = ARTEventListener();
        let listener6 = ARTEventListener();
        let listener7 = ARTEventListener();
        let filter1 = ARTMessageFilter();
        let filter2 = ARTMessageFilter();
        let filter3 = ARTMessageFilter();


        let filteredListeners = ARTFilteredListeners();

        filteredListeners.addFilteredListener(listener1, filter:filter1);
        filteredListeners.addFilteredListener(listener2, filter:filter2);
        filteredListeners.addFilteredListener(listener3, filter:filter1);
        filteredListeners.addFilteredListener(listener4, filter:filter1);
        filteredListeners.addFilteredListener(listener5, filter:filter2);
        filteredListeners.addFilteredListener(listener6, filter:filter3);
        filteredListeners.addFilteredListener(listener7, filter:filter1);

        XCTAssertEqual(7, filteredListeners.getFilteredListeners().count);
        let removedFilters = filteredListeners.remove(by: filter1)


        // Check the right listeners are leftover
        XCTAssertEqual(3, filteredListeners.getFilteredListeners().count)
        let retainedFilter1 = filteredListeners.getFilteredListeners().object(at: 0) as! FilteredListenerFilterPair
        XCTAssertEqual(listener2, retainedFilter1.listener)
        XCTAssertEqual(filter2, retainedFilter1.filter)
        let retainedFilter2 = filteredListeners.getFilteredListeners().object(at: 1) as! FilteredListenerFilterPair
        XCTAssertEqual(listener5, retainedFilter2.listener)
        XCTAssertEqual(filter2, retainedFilter2.filter)
        let retainedFilter3 = filteredListeners.getFilteredListeners().object(at: 2) as! FilteredListenerFilterPair
        XCTAssertEqual(listener6, retainedFilter3.listener)
        XCTAssertEqual(filter3, retainedFilter3.filter)


        // Check the right listeners are returned for removal
        XCTAssertEqual(4, removedFilters.count)
        XCTAssertEqual(listener1, removedFilters.object(at: 0) as! ARTEventListener)
        XCTAssertEqual(listener3, removedFilters.object(at: 1) as! ARTEventListener)
        XCTAssertEqual(listener4, removedFilters.object(at: 2) as! ARTEventListener)
        XCTAssertEqual(listener7, removedFilters.object(at: 3) as! ARTEventListener)
    }
}
