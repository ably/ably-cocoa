#import <Foundation/Foundation.h>
#include <Ably/ARTTypes.h>
#include <Ably/ARTMessageFilter.h>

NS_ASSUME_NONNULL_BEGIN

/// Convenience struct for storing filter/listener pairs
@interface FilteredListenerFilterPair : NSObject

@property (readonly) ARTEventListener* listener;
@property (readonly) ARTMessageFilter* filter;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithListenerAndFilter:(ARTEventListener *) listener withFilter:(ARTMessageFilter *) filter;

@end



/// A collection of filtered listeners to their filter object. Used for storing client-filtered subscriptions to message interaction.
/// Use of methods on this object is thread-safe.
@interface ARTFilteredListeners : NSObject

/// Get all the filtered listeners - for testing purposes.
- (NSMutableArray<FilteredListenerFilterPair *> *) getFilteredListeners;

/// :nodoc:
- (instancetype)init;

- (void) removeAllListeners;

/// Add a filtered listener and filter pair to the collection
- (void) addFilteredListener:(ARTEventListener *) listener filter:(ARTMessageFilter *) filter;

/// Remove all the listeners currently registered for a given filter, returns the removed listeners so that they can be removed from the channel subscriptions
- (NSMutableArray<ARTEventListener *> *) removeFilteredListenersByFilter:(ARTMessageFilter *) filter;

/// Remove the specific filtered listener from the collection. There will only be one instance of each.
- (void) removeFilteredListener:(ARTEventListener *) listener;

@end

NS_ASSUME_NONNULL_END
