//
//  ARTLocalDeviceTests.swift
//  Ably
//
//  Created by Lawrence Forooghian on 24/01/2022.
//  Copyright © 2022 Ably. All rights reserved.
//

import XCTest
import Ably

class ARTLocalDeviceTests: XCTestCase {
    struct ExampleError: Error, Equatable {}
    
    func test_load__errorWhenLoadingDeviceId__populatesIdLoadingError() {
        let storage = MockDeviceStorage(startWith: nil)
        let error = ExampleError()
        let logger = ARTLog()
        storage.simulateOnNextRead(.error(error), for: ARTDeviceIdKey)
        
        let device = ARTLocalDevice.load("someClientId", storage: storage, logger: logger)
        
        XCTAssertEqual(try XCTUnwrap(device.idLoadingError as? ExampleError), error)
    }

    func test_load__errorWhenLoadingDeviceSecret__populatesSecretLoadingError() {
        let storage = MockDeviceStorage(startWith: nil)
        storage.simulateOnNextRead(.string("someDeviceId"), for: ARTDeviceIdKey)
        let error = ExampleError()
        storage.simulateOnNextRead(.error(error), for: ARTDeviceSecretKey)
        let logger = ARTLog()
        
        let device = ARTLocalDevice.load("someClientId", storage: storage, logger: logger)
        
        XCTAssertEqual(try XCTUnwrap(device.secretLoadingError as? ExampleError), error)
    }
}
