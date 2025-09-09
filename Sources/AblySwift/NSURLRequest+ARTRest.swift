import Foundation

// swift-migration: original location NSURLRequest+ARTRest.h, line 7 and NSURLRequest+ARTRest.m, line 5
internal extension URLRequest {
    
    // swift-migration: original location NSURLRequest+ARTRest.h, line 9 and NSURLRequest+ARTRest.m, line 7
    func settingAcceptHeader(defaultEncoder: ARTEncoder, encoders: [String: ARTEncoder]) -> URLRequest {
        var allEncoders = encoders.values.map { $0.mimeType() }
        let defaultMimeType = defaultEncoder.mimeType()
        
        // swift-migration: Make the mime type of the default encoder the first element of the Accept header field
        if let index = allEncoders.firstIndex(of: defaultMimeType) {
            allEncoders.remove(at: index)
        }
        allEncoders.insert(defaultMimeType, at: 0)
        
        let accept = allEncoders.joined(separator: ",")
        var mutableRequest = self
        mutableRequest.setValue(accept, forHTTPHeaderField: "Accept")
        return mutableRequest
    }
}