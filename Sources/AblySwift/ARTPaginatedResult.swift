import Foundation

// swift-migration: original location ARTPaginatedResult.h, line 12 and ARTPaginatedResult.m, line 11
public class ARTPaginatedResult<ItemType>: NSObject {
    private var initializedViaInit: Bool = false
    
    // All of the below instance variables are non-nil if and only if initializedViaInit is false
    private var restInternal: ARTRestInternal?
    private var userQueueInternal: DispatchQueue?
    private var queueInternal: DispatchQueue?
    private var relFirstInternal: URLRequest?
    private var relCurrentInternal: URLRequest?
    private var relNextInternal: URLRequest?
    private var responseProcessorInternal: ARTPaginatedResultResponseProcessor?
    private var deallocInternal: ARTQueuedDealloc?
    
    // swift-migration: original location ARTPaginatedResult.h, line 17 and ARTPaginatedResult.m, line 32
    /// Contains the current page of results; for example, an array of ARTMessage or ARTPresenceMessage objects for a channel history request.
    public private(set) var items: [ItemType] = []
    
    // swift-migration: original location ARTPaginatedResult.h, line 22 and ARTPaginatedResult.m, line 31
    /// Returns true if there are more pages available by calling next and returns false if this page is the last page available.
    public private(set) var hasNext: Bool = false
    
    // swift-migration: original location ARTPaginatedResult.h, line 27 and ARTPaginatedResult.m, line 32
    /// Returns true if this page is the last page and returns false if there are more pages available by calling next available.
    public private(set) var isLast: Bool = false
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 10
    internal var rest: ARTRestInternal {
        initializedViaInitCheck()
        return restInternal!
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 11
    internal var userQueue: DispatchQueue {
        initializedViaInitCheck()
        return userQueueInternal!
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 12
    internal var queue: DispatchQueue {
        initializedViaInitCheck()
        return queueInternal!
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 13
    internal var relFirst: URLRequest? {
        initializedViaInitCheck()
        return relFirstInternal
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 14
    internal var relCurrent: URLRequest? {
        initializedViaInitCheck()
        return relCurrentInternal
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 15
    internal var relNext: URLRequest? {
        initializedViaInitCheck()
        return relNextInternal
    }
    
    // swift-migration: original location ARTPaginatedResult+Subclass.h, line 8
    internal let wrapperSDKAgents: [String: String]?
    
    // swift-migration: original location ARTPaginatedResult+Subclass.h, line 9
    internal let logger: InternalLog
    
    // swift-migration: original location ARTPaginatedResult.h, line 30 and ARTPaginatedResult.m, line 35
    /// If you use this initializer, trying to call any of the methods or properties in ARTPaginatedResult will throw an exception; you must provide your own implementation in a subclass. This initializer exists purely to allow you to provide a mock implementation of this class in your tests.
    public override init() {
        self.initializedViaInit = true
        self.wrapperSDKAgents = nil
        self.logger = InternalLog(core: DefaultInternalLogCore(logger: LogAdapter(logger: ARTLog())))
        super.init()
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 19 and ARTPaginatedResult.m, line 43
    internal init(items: [Any], rest: ARTRestInternal, relFirst: URLRequest?, relCurrent: URLRequest?, relNext: URLRequest?, responseProcessor: @escaping ARTPaginatedResultResponseProcessor, wrapperSDKAgents: [String: String]?, logger: InternalLog) {
        self.initializedViaInit = false
        
        self.items = items as! [ItemType]
        
        self.relFirstInternal = relFirst
        self.relCurrentInternal = relCurrent
        self.relNextInternal = relNext
        self.hasNext = relNext != nil
        self.isLast = !hasNext
        
        self.restInternal = rest
        self.userQueueInternal = rest.userQueue
        self.queueInternal = rest.queue
        self.responseProcessorInternal = responseProcessor
        self.wrapperSDKAgents = wrapperSDKAgents
        self.logger = logger
        
        // ARTPaginatedResult doesn't need a internal counterpart, as other
        // public objects do. It basically acts as a proxy to a
        // strongly-referenced ARTRestInternal, so it can be thought as an
        // alternative public counterpart to ARTRestInternal.
        //
        // So, since it's owned by user code, it should dispatch its release of
        // its ARTRestInternal to the internal queue. We could take the common
        // ARTQueuedDealloc as an argument as other public objects do, but
        // that would just be bookkeeping since we know it will be initialized
        // from the ARTRestInternal we already have access to anyway, so we can
        // make our own.
        self.deallocInternal = ARTQueuedDealloc(ref: rest, queue: rest.queue)
        
        super.init()
    }
    
    // swift-migration: original location ARTPaginatedResult.m, line 88
    private func initializedViaInitCheck() {
        if initializedViaInit {
            fatalError("When initializing this class using -init, you need to override this method in a subclass")
        }
    }
    
    // swift-migration: original location ARTPaginatedResult.h, line 37 and ARTPaginatedResult.m, line 109
    /// Returns a new ARTPaginatedResult for the first page of results.
    public func first(_ callback: @escaping (ARTPaginatedResult<ItemType>?, ARTErrorInfo?) -> Void) {
        initializedViaInitCheck()
        
        let userCallback = callback
        let wrappedCallback: (ARTPaginatedResult<ItemType>?, ARTErrorInfo?) -> Void = { result, error in
            self.userQueueInternal!.async {
                userCallback(result, error)
            }
        }
        
        ARTPaginatedResult.executePaginated(restInternal!, withRequest: relFirstInternal!, andResponseProcessor: responseProcessorInternal!, wrapperSDKAgents: wrapperSDKAgents, logger: logger) { result, error in
            wrappedCallback(result, error)
        }
    }
    
    // swift-migration: original location ARTPaginatedResult.h, line 44 and ARTPaginatedResult.m, line 124
    /// Returns a new ARTPaginatedResult loaded with the next page of results. If there are no further pages, then nil is returned.
    public func next(_ callback: @escaping (ARTPaginatedResult<ItemType>?, ARTErrorInfo?) -> Void) {
        initializedViaInitCheck()
        
        let userCallback = callback
        let wrappedCallback: (ARTPaginatedResult<ItemType>?, ARTErrorInfo?) -> Void = { result, error in
            self.userQueueInternal!.async {
                userCallback(result, error)
            }
        }
        
        guard let relNext = relNextInternal else {
            // If there is no next page, we can't make a request, so we answer the callback
            // with a nil PaginatedResult. That's why the callback has the result as nullable
            // anyway. (That, and that it can fail.)
            wrappedCallback(nil, nil)
            return
        }
        
        ARTPaginatedResult.executePaginated(restInternal!, withRequest: relNext, andResponseProcessor: responseProcessorInternal!, wrapperSDKAgents: wrapperSDKAgents, logger: logger) { result, error in
            wrappedCallback(result, error)
        }
    }
    
    // swift-migration: original location ARTPaginatedResult+Private.h, line 28 and ARTPaginatedResult.m, line 146
    internal class func executePaginated(_ rest: ARTRestInternal, withRequest request: URLRequest, andResponseProcessor responseProcessor: @escaping ARTPaginatedResultResponseProcessor, wrapperSDKAgents: [String: String]?, logger: InternalLog, callback: @escaping (ARTPaginatedResult?, ARTErrorInfo?) -> Void) {
        ARTLogDebug(logger, "Paginated request: \(request)")
        
        _ = rest.execute(request, withAuthOption: ARTAuthentication.on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
            if let error = error {
                callback(nil, ARTErrorInfo.createFromNSError(error))
            } else {
                ARTLogDebug(logger, "Paginated response: \(String(describing: response))")
                if let data = data {
                    ARTLogDebug(logger, "Paginated response data: \(String(data: data, encoding: .utf8) ?? "")")
                }
                
                // swift-migration: Updated to use throws pattern instead of inout error parameter
                let items: [Any]?
                do {
                    items = try responseProcessor(response, data)
                } catch {
                    callback(nil, ARTErrorInfo.createFromNSError(error as NSError))
                    return
                }
                
                let links = response?.extractLinks() ?? [:]
                
                let firstRel = URLRequest.requestWithPath(links["first"], relativeTo: request)
                let currentRel = URLRequest.requestWithPath(links["current"], relativeTo: request)
                let nextRel = URLRequest.requestWithPath(links["next"], relativeTo: request)
                
                let result = ARTPaginatedResult(
                    items: items ?? [],
                    rest: rest,
                    relFirst: firstRel,
                    relCurrent: currentRel,
                    relNext: nextRel,
                    responseProcessor: responseProcessor,
                    wrapperSDKAgents: wrapperSDKAgents,
                    logger: logger
                )
                
                callback(result, nil)
            }
        }
    }
}
