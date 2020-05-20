import XCTest
@testable import HeartRateKit

final class HeartRateKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HeartRateKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
