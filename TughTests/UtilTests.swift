//
//  UtilTests.swift
//  Tugh
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class UtilTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBase64HMAC() {
        let str = "Encrypt the following thing okay, with 532 cows."
        let secret = "FiveHundredThirtyTwoCows"
        let encrypted = str.hmacSHA1Base64(secret)
        XCTAssertEqual("xeFWxerNU5imfCeWnJLDqd1Evu0=", encrypted)
    }
    
}
