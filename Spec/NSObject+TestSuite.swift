//
//  NSObject+TestSuite.swift
//  ably
//
//  Created by Ricardo Pereira on 17/02/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Aspects

extension NSObject {

    /// Inject a block of code to the identified class method.
    class func testSuite_injectIntoClassMethod(selector: Selector, code: ()->()) -> AspectToken? {
        let block: @convention(block) (AspectInfo) -> Void = { _ in
            code()
        }
        return try? self.aspect_hookSelector(selector, withOptions: .PositionAfter, usingBlock: unsafeBitCast(block, AnyObject.self))
    }

}
