//
//  Tugh.swift
//  Tugh
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public class Tugh {
    /**
        Generates a request header that you can use to get the Twitter OAuth Token. Take the string result of this function and then append it to the "Authorize" header in your HTTP request.
    
        Customarily, the requestTokenURI is "https://api.twitter.com/oauth/request_token"
    */
    public class func twitterOAuthTokenAuthHeader(
        requestTokenURI: String,
        appKey: String,
        appSecret: String,
        callbackURI: String?) -> String {
            
        let method = "POST"
        let timestamp = self.timestamp()
        let nonce = self.nonce()
        
        var header: [String : String] = [
            "oauth_nonce" : nonce,
            "oauth_consumer_key" : appKey,
            "oauth_signature_method" : "HMAC-SHA1",
            "oauth_timestamp" : timestamp,
            "oauth_version" : "1.0"
        ]
            
        if callbackURI != nil {
            header["oauth_callback"] = callbackURI!
        }
        
        let signatureBaseFromHeaderParams = header.sort{ $0.0 < $1.0 }.map{ (k,v) -> String in
            let encK = Util.percentEncode(k)
            let encV = Util.percentEncode(v)
            return "\(encK)=\(encV)"
            }.joinWithSeparator("&")
        
        let encAPIURI = Util.percentEncode(requestTokenURI)
        let encParamString = Util.percentEncode(signatureBaseFromHeaderParams)
        let signatureBaseString = "\(method)&\(encAPIURI)&\(encParamString)"
        let signingKey = Util.percentEncode(appSecret) + "&"
        
        let signature = signatureBaseString.hmacSHA1Base64(signingKey)
        
        header["oauth_signature"] = signature
        
        let almostHeader = header.map { (key, val) -> String in
            let encKey = Util.percentEncode(key)
            let encVal = Util.percentEncode(val)
            return "\(encKey)=\"\(encVal)\""
            }.joinWithSeparator(", ")
        
        let headerFinally = "OAuth " + almostHeader
        
        return headerFinally
    }
    
    public class func nonce() -> String {
        return Util.simpleNonce()
    }
    
    public class func timestamp() -> String {
        return String(Int(NSDate().timeIntervalSince1970))
    }
}
