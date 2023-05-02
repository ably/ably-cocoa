/**
 Represents an execution of a test case method.
 */
struct Test {
    var id = UUID()
    private var function: StaticString

    init(function: StaticString = #function) {
        self.function = function
        NSLog("Created test \(id) for function \(function)")
    }
}
