//
//  TughTests.swift
//  TughTests
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest
@testable import Tugh


class TughTests: XCTestCase {
    func testTokenRequestHeader() {
        // TODO: Override simpleNonce() so we can test a consistent string
        
        let appKey = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
        let appSecret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
        
        let authHeader = Tugh.twitterOAuthTokenRequestHeader("https://api.twitter.com/oauth/request_token", appKey: appKey, appSecret: appSecret)
        debugPrint(authHeader)
        XCTAssertNotNil(authHeader)
    }
}
