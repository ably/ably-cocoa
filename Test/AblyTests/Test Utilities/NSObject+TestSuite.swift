import AblyTestingObjC

extension NSObject {

    /// Inject a block of code to the identified class method.
    class func testSuite_injectIntoClassMethod(_ selector: Selector, code: @escaping ()->()) -> AspectToken? {
        let block: @convention(block) (AspectInfo) -> Void = { _ in
            code()
        }
        return try? self.aspect_hook(selector, with: AspectOptions(), usingBlock: unsafeBitCast(block, to: AnyObject.self))
    }

}
