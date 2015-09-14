//
//  Util.swift
//  Tugh
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import CommonCrypto

public class Util {
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
}

extension String {    
    func hmacSHA1Base64(key: String) -> String {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = Int(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen: Int32 = CC_SHA1_DIGEST_LENGTH
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(Int(digestLen))
        let keyStr = key.cStringUsingEncoding(NSUTF8StringEncoding)
        let keyLen = Int(key.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let alg: CCHmacAlgorithm = CCHmacAlgorithm(kCCHmacAlgSHA1)
        CCHmac(alg, keyStr!, keyLen, str!, strLen, result)
        
        let data = NSData(bytesNoCopy: result, length: Int(digestLen))
        result.destroy()
        
        let digest = data.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        return digest
    }
}
