//
//  Tugh.swift
//  Tugh
//
//  Created by Robert Otani on 9/14/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import Accounts
import Social

public enum RequestMethod : String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
}

public struct SigningMethod {
    public static let HMAC_SHA1 = "HMAC-SHA1"
}

public struct NotificationInfo {
    public static let Name = "Tugh oAuth Notification"
    public static let URLKey = "Tugh oAuth Callback URL"
}

public struct TwitterEndpoint {
    public static let requestTokenURI: String = "https://api.twitter.com/oauth/request_token"// POST
    public static let authzURI: String = "https://api.twitter.com/oauth/authorize" // GET (login info)
    public static let accessTokenURI: String = "https://api.twitter.com/oauth/access_token" // POST
}

/**
Provide your own implementation of this protocol to give to the Tugh class.
Generally, it should be some simple wrapper around your network client of choice; this also
allows for easier testability.
*/
public protocol AsyncClientProtocol {
    func performPOST(
        uri: String,
        headers:[String : String]?,
        completion:((responseDict: [String : String]?, error: NSError?)->Void)?)
    
    func performGET(
        url: String,
        headres:[String : String]?,
        completion:((responseDict: [String : String]?, error: NSError?)->Void)?)
}

public struct TughTwitterSession {
    let authToken : String
    let authTokenSecret: String
    let screenName: String
    let userID: String
}

public protocol TughProtocol {
    static func twitterAuthHeader(
        requestTokenURI: String,
        method: RequestMethod,
        appKey: String,
        appSecret: String,
        additionalHeaders: [String : String]?,
        callbackURI: String?) -> String
    
    static func nonce() -> String
    
    static func timestamp() -> String
    
    static func isOAuthCallback(url: NSURL) -> Bool
    
    static func notifyWithCallbackURL(url: NSURL) -> Void
    
    func twitterLogin(
        consumerKey: String,
        consumerSecret: String,
        callbackURI: String,
        completion:((twSession: TughTwitterSession, error: NSError) -> Void)?)
}

public protocol TughDelegate {
    func tughCustomerDidSelectAccount(acAccount: ACAccount) -> Void
}


public class Tugh : TughProtocol {
    let httpClient: AsyncClientProtocol
    var delegate: TughDelegate?

    /**
        Generates a request header that you can use to make authorized requests. Take the string result of this function and then append it to the "Authorization" field in your HTTP request header.
    
        The last known latest Twitter documentation on Authorization headers is here:
        https://dev.twitter.com/oauth/overview/authorizing-requests
    */
    public class func twitterAuthHeader(
        requestTokenURI: String,
        method: RequestMethod,
        appKey: String,
        appSecret: String,
        additionalHeaders: [String : String]?,
        callbackURI: String?) -> String {

        let timestamp = self.timestamp()
        let nonce = self.nonce()
        
        var header: [String : String] = [
            "oauth_nonce" : nonce,
            "oauth_consumer_key" : appKey,
            "oauth_signature_method" : SigningMethod.HMAC_SHA1,
            "oauth_timestamp" : timestamp,
            "oauth_version" : "1.0"
        ]
            
        if additionalHeaders != nil {
            for (k, v) in additionalHeaders! {
                header[k] = v
            }
        }
            
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
    
    public class func isOAuthCallback(url: NSURL) -> Bool {
        if let host = url.host {
            return host.hasPrefix("oauth")
        }
        return false
    }
    
    public class func notifyWithCallbackURL(url: NSURL) {
        let userInfo = [NotificationInfo.URLKey : url]
        let notification = NSNotification(name: NotificationInfo.Name, object: nil, userInfo: userInfo)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    required public init(client: AsyncClientProtocol) {
        httpClient = client
    }
}
