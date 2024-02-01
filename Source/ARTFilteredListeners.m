#import "ARTFilteredListeners.h"


// Convenience struct for storing filter/listener pairs
@implementation FilteredListenerFilterPair

- (instancetype) initWithListenerAndFilter:(ARTEventListener *) listener withFilter:(ARTMessageFilter *)filter {
    self = [super init];
    if (self) {
        _listener = listener;
        _filter = filter;
    }

    return self;
}

@end

#pragma mark ARTFilteredListeners
@implementation ARTFilteredListeners {
    NSMutableArray<FilteredListenerFilterPair *> * _filteredListeners;
}


- (instancetype) init {
    self = [super init];
    if (self) {
        _filteredListeners = [[NSMutableArray alloc] init];
    }

    return self;
}

- (NSMutableArray<FilteredListenerFilterPair *> *) getFilteredListeners {
    @synchronized (self) {
        return _filteredListeners;
    }
}

- (void) removeAllListeners {
    @synchronized (self) {
        [_filteredListeners removeAllObjects];
    }
}

- (void) addFilteredListener:(ARTEventListener *) listener filter:(ARTMessageFilter *) filter {
    @synchronized (self) {
        FilteredListenerFilterPair * pair = [[FilteredListenerFilterPair alloc] initWithListenerAndFilter:listener withFilter:filter];
        [_filteredListeners addObject:pair];
    }
}

- (NSMutableArray<ARTEventListener *> *) removeFilteredListenersByFilter:(ARTMessageFilter *) filter {

    NSMutableArray<ARTEventListener *> *discardedListeners = [[NSMutableArray alloc] init];

    if (filter == nil) {
        return discardedListeners;
    }

    @synchronized (self) {
        // Find all the pairs that match the filter, and note them and their listeners
        NSMutableArray *discardedPairs = [[NSMutableArray alloc] init];
        for (FilteredListenerFilterPair * pair in _filteredListeners) {
            if (pair.filter == filter) {
                [discardedListeners addObject:pair.listener];
                [discardedPairs addObject:pair];
            }
        }

        // Remove the pairs from the array
        [_filteredListeners removeObjectsInArray:discardedPairs];

        // Return the discarded listeners
        return discardedListeners;
    }

}

- (void) removeFilteredListener:(ARTEventListener *) listener {

    if (listener == nil) {
        return;
    }

    @synchronized (self) {
        int index = 0;
        for (FilteredListenerFilterPair * pair in _filteredListeners) {
            if (pair.listener == listener) {
                [_filteredListeners removeObjectAtIndex:index];
                return;
            }

            index++;
        }
    }
}

@end
