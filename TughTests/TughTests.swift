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
    
    class TughTest : Tugh {
        // Override random/timestamp stuff for testability, only use when you really need it in the tests
        override internal class func nonce() -> String {
            return "AlwaysTheSameNonceForTesting"
        }
        override internal class func timestamp() -> String {
            return "1442358472"
        }
    }
    
    func testTokenAuthHeader() {
        // These keys are from the example code in Twitter documentation, and are useless outside of that context
        let appKey = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
        let appSecret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
        
        let authHeader = TughTest.twitterOAuthTokenAuthHeader(
            "https://api.twitter.com/oauth/request_token",
            appKey: appKey,
            appSecret: appSecret,
            callbackURI: nil)
        
        let expectedHeaderValue = "OAuth oauth_signature_method=\"HMAC-SHA1\", oauth_version=\"1.0\", oauth_timestamp=\"1442358472\", oauth_signature=\"G1qKuDVd1VXDu5d1%2BBkM2IjTPtw%3D\", oauth_nonce=\"AlwaysTheSameNonceForTesting\", oauth_consumer_key=\"kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw\""

        XCTAssertEqual(expectedHeaderValue, authHeader)
    }
    
    func testAddCallbackToAuthGenerator() {
        let appKey = "whocaresaboutthisappKeyIDO"
        let appSecret = "thisIsTOTALLYASecretPeople"
        
        let authHeader = TughTest.twitterOAuthTokenAuthHeader(
            "http://example.com/oauth/something",
            appKey: appKey,
            appSecret: appSecret,
            callbackURI: "tugh://turn/down/for/wat")
        
        let expectedResult = "OAuth oauth_consumer_key=\"whocaresaboutthisappKeyIDO\", oauth_callback=\"tugh%3A%2F%2Fturn%2Fdown%2Ffor%2Fwat\", oauth_signature=\"zCUA46aJNrv6u7pUqbDCpYIGYcA%3D\", oauth_version=\"1.0\", oauth_timestamp=\"1442358472\", oauth_nonce=\"AlwaysTheSameNonceForTesting\", oauth_signature_method=\"HMAC-SHA1\""
        
        XCTAssertEqual(expectedResult, authHeader)
    }

}
