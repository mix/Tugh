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
    func testTokenAuthHeader() {
        
        // Override random/timestamp stuff for testability
        class TughTest : Tugh {
            override private class func nonce() -> String {
                return "AlwaysTheSameNonceForTesting"
            }
            override private class func timestamp() -> String {
                return "1442358472"
            }
        }
        
        // These keys are from the example code in Twitter documentation, and are useless outside of that context
        let appKey = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
        let appSecret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
        
        let authHeader = TughTest.twitterOAuthTokenAuthHeader(
            "https://api.twitter.com/oauth/request_token",
            appKey: appKey,
            appSecret: appSecret,
            callbackURI: nil)
        
        let expectedHeaderValue = "OAuth oauth_signature_method=\"HMAC-SHA1\", oauth_version=\"1.0\", oauth_timestamp=\"1442358472\", oauth_signature=\"G1qKuDVd1VXDu5d1%2BBkM2IjTPtw%3D\", oauth_nonce=\"AlwaysTheSameNonceForTesting\", oauth_consumer_key=\"kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw\""

        debugPrint(authHeader)
        XCTAssertEqual(expectedHeaderValue, authHeader)
    }

}
