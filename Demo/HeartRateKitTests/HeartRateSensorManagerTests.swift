//
//  HeartRateSensorManagerTests.swift
//  HeartRateKitTests
//
//  Created by Sergii Kostanian on 3/2/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import XCTest
@testable import HeartRateKit

class HeartRateSensorManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDeinitIssues() {
        let expectation = XCTestExpectation(description: "Wait manager deinit")
        let deiniter = Deiniter(reference: HeartRateSensorManager())
        deiniter.runDeinit(after: 2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
}

private class Deiniter<T> {
    private var reference: T?
    
    init(reference: T) {
        self.reference = reference
    }
    
    func runDeinit(after timeout: TimeInterval, _ completionHandler: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(timeout * 1000))) {
            self.reference = nil
            completionHandler()
        }
    }
}
