//
//  Util.swift
//  Tugh
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import CryptoSwift

public class Util {
    
    public class func dictionaryFromOAuthCSV(string: String) -> [String : String] {
        let s = string.stringByReplacingOccurrencesOfString("OAuth ", withString: "")
        var dict = [String : String]()
        let params = s.componentsSeparatedByString(", ")
        params.forEach { (param) -> () in
            let pair = param.componentsSeparatedByString("=")
            guard pair.count == 2 else {
                return
            }
            let k = pair[0]
            let v = pair[1].stringByReplacingOccurrencesOfString("\"", withString: "")
            dict[k] = v
        }
        return dict
    }
    
    public class func dictionaryFromQueryStringInData(data: NSData) throws -> [String : String] {
        if let stringRepresentation = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            let dict = self.parseQueryString(stringRepresentation)
            return dict!
        } else {
            let responseParseErrorInfo = [
                NSLocalizedDescriptionKey : "Problem converting data object to Dictionary<String, String> type"
            ]
            let conversionError: NSError = NSError(domain: tughErrorDomain, code: -1, userInfo: responseParseErrorInfo)
            throw conversionError
        }
    }
    
    public class func simpleNonce() -> String {
        let s = NSUUID().UUIDString
        let nonce = s.stringByReplacingOccurrencesOfString("-", withString: "")
        return nonce
    }
    
    public class func percentEncode(string: String) -> String {
        // http://tools.ietf.org/html/rfc3986#section-2.1
        // https://dev.twitter.com/oauth/overview/percent-encoding-parameters
        let legit = "0123456789 -._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let charset = NSCharacterSet(charactersInString: legit)
        return string.stringByAddingPercentEncodingWithAllowedCharacters(charset)!
    }
    
    public class func parseQueryString(queryString: String) -> [String : String]? {
        var returnDict: [String : String]? = Dictionary<String, String>()
        
        // :D
        if let components = NSURLComponents(string: "http://example.com?" + queryString) {
            for item in components.queryItems! {
                returnDict![item.name] = item.value
            }
        }
        
        return returnDict
    }
}

extension String {    
    func hmacSHA1Base64(key: String) -> String {
        
        let uInt8Key:[UInt8] = Array(key.utf8)
        let message = Array(self.utf8)

        let hmacHex:[UInt8] = Authenticator.HMAC(key: uInt8Key, variant: .sha1).authenticate(message)!
        let bufSize: Int32 = 160 / 8
        let buffer = UnsafeMutablePointer<UInt8>.alloc(Int(bufSize))
        
        for i in 0 ..< Int(bufSize) {
            buffer[i] = hmacHex[i]
        }
        
        let data = NSData(bytesNoCopy: buffer, length: Int(bufSize), freeWhenDone: true)
        let base64Result = data.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        return base64Result
    }
}
