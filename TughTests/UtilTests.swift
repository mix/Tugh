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
        let signed = try! str.hmacSHA1Base64(secret)
        XCTAssertEqual("xeFWxerNU5imfCeWnJLDqd1Evu0=", signed)
    }
    
    func testTwitterExample() {
        let str = "POST&https%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521"
        let secret = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw&LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
        let signed = try! str.hmacSHA1Base64(secret)
        XCTAssertEqual("tnnArxj06cWHq44gCs1OSKk/jLY=", signed)
    }
    
    func testParseQueryString() {
        let queryString = "oauth_token=6253282-eWudHldSbIaelX7swmsiHImEL4KinwaGloHANdrY&oauth_token_secret=2EEfA6BG3ly3sR3RjE0IBSnlQu4ZrUzPiYKmrkVU&user_id=6253282&screen_name=twitterap"
        
        let expectedDictionary = [
            "oauth_token" : "6253282-eWudHldSbIaelX7swmsiHImEL4KinwaGloHANdrY",
            "oauth_token_secret" : "2EEfA6BG3ly3sR3RjE0IBSnlQu4ZrUzPiYKmrkVU",
            "user_id" : "6253282",
            "screen_name" : "twitterap"
        ]
        
        XCTAssertEqual(expectedDictionary, Util.parseQueryString(queryString)!)
    }
    
    func testParseRequestTokenResponse() {
        let requestTokenResponse = "OAuth oauth_timestamp=\"1450765842\", oauth_signature=\"B%2asdfsdQj7as%3D\", oauth_consumer_key=\"NvpasfascfiNbWB3Iz\", oauth_nonce=\"cOdeeWQhd6ktnIMByGuKWK%2BS3Utg4xCJKj%2B0bsR38ig%3D\", oauth_token=\"-iuXlwasfsadchh98s\", oauth_signature_method=\"HMAC-SHA1\", oauth_version=\"1.0\""
        let parsed = Util.dictionaryFromOAuthCSV(requestTokenResponse)
        let expectedDictionary = [
            "oauth_nonce": "cOdeeWQhd6ktnIMByGuKWK%2BS3Utg4xCJKj%2B0bsR38ig%3D",
            "oauth_signature": "B%2asdfsdQj7as%3D",
            "oauth_version": "1.0",
            "oauth_timestamp": "1450765842",
            "oauth_token": "-iuXlwasfsadchh98s",
            "oauth_consumer_key": "NvpasfascfiNbWB3Iz",
            "oauth_signature_method": "HMAC-SHA1"
        ]
        XCTAssertEqual(expectedDictionary, parsed)
    }
    
}
