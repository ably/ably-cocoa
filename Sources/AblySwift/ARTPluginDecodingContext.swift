import Foundation
import _AblyPluginSupportPrivate

// swift-migration: original location ARTPluginDecodingContext.h, line 6 and ARTPluginDecodingContext.m, line 3
internal class ARTPluginDecodingContext: NSObject, _AblyPluginSupportPrivate.DecodingContextProtocol {

    // swift-migration: original location ARTPluginDecodingContext.m, line 5
    internal var parentID: String? {
        return _parentID
    }
    
    // swift-migration: original location ARTPluginDecodingContext.m, line 6
    internal var parentConnectionID: String? {
        return _parentConnectionID
    }
    
    // swift-migration: original location ARTPluginDecodingContext.m, line 7
    internal var parentTimestamp: Date? {
        return _parentTimestamp
    }
    
    // swift-migration: original location ARTPluginDecodingContext.m, line 8
    internal var indexInParent: Int {
        return _indexInParent
    }

    // Private storage properties
    private let _parentID: String?
    private let _parentConnectionID: String?
    private let _parentTimestamp: Date?
    private let _indexInParent: Int

    // swift-migration: original location ARTPluginDecodingContext.h, line 8 and ARTPluginDecodingContext.m, line 10
    internal init(
        parentID: String?,
        parentConnectionID: String?,
        parentTimestamp: Date?,
        indexInParent: Int
    ) {
        // swift-migration: original location ARTPluginDecodingContext.m, line 16
        self._parentID = parentID
        self._parentConnectionID = parentConnectionID  
        self._parentTimestamp = parentTimestamp
        self._indexInParent = indexInParent
        super.init()
    }
    
    // swift-migration: original location ARTPluginDecodingContext.h, line 13
    @available(*, unavailable)
    override init() {
        fatalError("init() is not available, use designated initializer")
    }
}