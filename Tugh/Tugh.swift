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

public let tughErrorDomain: String = "com.otanistudio.Tugh.error"
public let tughUserDefaultsKeyCallbackURI: String = "com.otanistudio.Tugh.callbackURI"

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
    public static let verifyCredentialsURI: String = "https://api.twitter.com/1.1/account/verify_credentials.json" // GET
}

/**
Provide your own implementation of this protocol to give to the Tugh class.
Generally, it should be some simple wrapper around your network client of choice; this also
allows for easier testability.
*/
public protocol AsyncClientProtocol {
    func performPOST(
        uri: String,
        postBody: String?,
        headers:[String : String]?,
        completion:((data: NSData?, error: NSError?) -> Void))
    
    func performGET(
        uri: String,
        headers:[String : String]?,
        completion:((data: NSData?, error: NSError?) -> Void))
    
    func performRequest(
        req: NSURLRequest,
        completion:((data: NSData?, response: NSURLResponse?, error: NSError?)->Void))
}

public struct TughTwitterSession {
    public let authToken : String
    public let authTokenSecret: String
    public let screenName: String
    public let userID: String
}

public protocol TughProtocol {
    static func twitterAuthHeader(
        requestTokenURI: String,
        method: RequestMethod,
        appKey: String,
        appSecret: String,
        additionalHeaders: [String : String]?,
        callbackURI: String?) throws -> String
    
    static func nonce() -> String
    
    static func timestamp() -> String
    
    static func isOAuthCallback(url: NSURL) -> Bool
    
    static func notifyWithCallbackURL(url: NSURL) -> Void
    
    func twitterLogin(consumerKey: String, consumerSecret: String, callbackURI: String)
    func twitterReverseAuthForApplication(account: ACAccount, consumerKey: String, consumerSecret: String)
}

public protocol TughDelegate {
    func tughDidFail(error: NSError) -> Void
    func tughDidReceiveRequestToken(requestToken: String) -> Void
    func tughDidReceiveTwitterSession(twSession: TughTwitterSession) -> Void
}

public class Tugh : TughProtocol {
    let httpClient: AsyncClientProtocol
    let delegate: TughDelegate

    required public init(httpClient: AsyncClientProtocol, delegate: TughDelegate) {
        self.httpClient = httpClient
        self.delegate = delegate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didReceiveOAuthCallback(_:)), name: NotificationInfo.Name, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
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
        callbackURI: String?) throws -> String {

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
        
        let signature = try signatureBaseString.hmacSHA1Base64(signingKey)
        
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
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let callbackURI = userDefaults.stringForKey(tughUserDefaultsKeyCallbackURI) {
            let comp = NSURLComponents(string: callbackURI)
            return comp?.scheme == url.scheme && comp?.host == url.host && comp?.path == url.path
        }
        return false
    }
    
    public class func notifyWithCallbackURL(url: NSURL) {
        let userInfo = [NotificationInfo.URLKey : url]
        let notification = NSNotification(name: NotificationInfo.Name, object: nil, userInfo: userInfo)
        
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    /**
        Performs the requisite set of requests against the Twitter API Endpoints to obtain the
        user credentials (`oauth_token`, `oauth_secret`, `screen_name`, and `user_id` are encapsulated in the
        `TughTwitterSession` struct)
     
        - parameters consumerKey: Your Twitter application "consumer key"
        - parameters consumerSecret: Your Twitter application "consumer secret"
        - parameters callbackURI: Your iOS app's custom URL scheme
    */
    public func twitterLogin(consumerKey: String, consumerSecret: String, callbackURI: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(callbackURI, forKey: tughUserDefaultsKeyCallbackURI)
        userDefaults.synchronize()
        
        var oAuthHeader: String = ""
        do {
            oAuthHeader = try Tugh.twitterAuthHeader(TwitterEndpoint.requestTokenURI, method: .POST, appKey: consumerKey, appSecret: consumerSecret, additionalHeaders: nil, callbackURI: callbackURI)
        } catch {
            let oAuthHeaderError = NSError(
                domain: tughErrorDomain,
                code: -17,
                userInfo: [
                    NSLocalizedDescriptionKey : "[Tugh] twitterLogin: Failed to generate a valid authorization header for \(TwitterEndpoint.requestTokenURI)"
                ])
            self.delegate.tughDidFail(oAuthHeaderError)
            return
        }

        let headers = [
            "Authorization" : oAuthHeader
        ]
        
        httpClient.performPOST(TwitterEndpoint.requestTokenURI, postBody: nil, headers: headers) { (data, error) -> Void in
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.delegate.tughDidFail(error!)
                })
                return
            }
            
            var responseDict: [String : String]?
            do {
                responseDict = try Util.dictionaryFromQueryStringInData(data!)
            } catch _ {
                responseDict = [String : String]()
            }
            
            guard responseDict?.count > 0 else {
                // TODO: Make the callback's error object capture the data from the AsyncClient instead
                let responseError: NSError = NSError(
                    domain: tughErrorDomain,
                    code: -3,
                    userInfo: [
                        NSLocalizedDescriptionKey : "Failed while trying to retreive \(TwitterEndpoint.requestTokenURI). Check whether your Twitter App's oauth_callback setting is 'oob'"
                    ])
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.delegate.tughDidFail(responseError)
                })
                return
            }
            
            let oAuthToken = responseDict!["oauth_token"]!
            self.twitterAuthorize(oAuthToken)
        }
    }
    
    private func twitterAuthorize(oAuthToken: String) {
        debugPrint("[Tugh.twitterAuthorize] oAuthToken = \(oAuthToken)")
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate.tughDidReceiveRequestToken(oAuthToken)
        }
    }
    
    @objc public func didReceiveOAuthCallback(notification: NSNotification) {
        if notification.name == NotificationInfo.Name {
            let verifierURLFromNotification = notification.userInfo![NotificationInfo.URLKey] as! NSURL
            let verifierComponents = NSURLComponents(string: verifierURLFromNotification.absoluteString)
            let verifierInfo = Util.parseQueryString(verifierComponents!.query!)!
            let params: [String : String] = [
                "oauth_token" : verifierInfo["oauth_token"]!,
                "oauth_verifier" : verifierInfo["oauth_verifier"]!
            ]
            var paramPairs: [String] = []
            for (name, value) in params {
                paramPairs.append("\(name)=\(Util.percentEncode(value))")
            }
            let paramString = paramPairs.joinWithSeparator("&")
            let (consumerKey, consumerSecret) = ("placeholder_key", "placeholder_secret")
            
            let oAuthHeader: String
            do {
                oAuthHeader = try self.dynamicType.twitterAuthHeader(TwitterEndpoint.accessTokenURI, method: .POST, appKey: consumerKey, appSecret: consumerSecret, additionalHeaders:["oauth_verifier" : params["oauth_verifier"]!], callbackURI: nil)
                
            } catch {
                let oAuthHeaderError = NSError(
                    domain: tughErrorDomain,
                    code: -18,
                    userInfo: [
                        NSLocalizedDescriptionKey : "[Tugh] didReceiveOAuthCallback: Failed to generate a valid authorization header for \(TwitterEndpoint.accessTokenURI)"
                    ])
                self.delegate.tughDidFail(oAuthHeaderError)
                return
            }
            
            let headers = [
                "Content-Type" : "application/x-www-form-urlencoded",
                "Authorization" : oAuthHeader
            ]
            
            httpClient.performPOST(
                TwitterEndpoint.accessTokenURI,
                postBody: paramString,
                headers: headers,
                completion: { (data, error) -> Void in
                    guard error == nil else {
                        self.delegate.tughDidFail(error!)
                        return
                    }
                    
                    var responseDict: [String : String]?
                    do {
                        responseDict = try Util.dictionaryFromQueryStringInData(data!)
                    } catch _ {
                        responseDict = [String : String]()
                    }
                    
                    debugPrint("[Tugh.didReceiveOAuthCallback]: responseDict:\n\t\(responseDict)\n\tError: \(error)")
                    
                    let userOAuthToken = responseDict!["oauth_token"]!
                    let userOAuthSecret = responseDict!["oauth_token_secret"]!
                    let twUserID = responseDict!["user_id"]!
                    let twUsername = responseDict!["screen_name"]!
                    
                    let twSession = TughTwitterSession(authToken: userOAuthToken, authTokenSecret: userOAuthSecret, screenName: twUsername, userID: twUserID)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.delegate.tughDidReceiveTwitterSession(twSession)
                    })
                    
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    userDefaults.removeObjectForKey(tughUserDefaultsKeyCallbackURI)
            })

        }
    }
    
    /**
        Given an ACAccount, perform reverse authorization to get the TughTwitterSession against the application described by the `consumerKey` and `consumerSecret`. This function relies on the Twitter credentials from System Settings. A successful retrieval will call this delegate's `tughDidReceiveTwitterSession` function
     
        - parameter account: The account obtained for the Twitter type identifier from `ACAccountStore`
        - parameter consumerKey: Your app's "consumer key"
        - parameter consumerSecret: Your app's "consumer secret"
    */
    public func twitterReverseAuthForApplication(account: ACAccount, consumerKey: String, consumerSecret: String) {
        
        let params = [
            "x_auth_mode" : "reverse_auth"
        ]
        
        let reqTokenOAuthHeaderValue: String
        
        do {
            reqTokenOAuthHeaderValue = try self.dynamicType.twitterAuthHeader(TwitterEndpoint.requestTokenURI, method: .POST, appKey: consumerKey, appSecret: consumerSecret, additionalHeaders: params, callbackURI: "oob")
        } catch {
            let oAuthHeaderError = NSError(
                domain: tughErrorDomain,
                code: -19,
                userInfo: [
                    NSLocalizedDescriptionKey : "[Tugh] twitterReverseAuthForApplication: Failed to generate a valid authorization header for \(TwitterEndpoint.requestTokenURI)"
                ])
            self.delegate.tughDidFail(oAuthHeaderError)
            return
        }
        
        let reqTokenOAuthHeader = ["Authorization" : reqTokenOAuthHeaderValue]
        
        let postBody = params.map { (k, v) -> String in
            return "\(k)=\(v)"
        }.joinWithSeparator("&")
        
        httpClient.performPOST(TwitterEndpoint.requestTokenURI, postBody: postBody, headers: reqTokenOAuthHeader) { (data, error) -> Void in
            
            guard error == nil else {
                self.delegate.tughDidFail(error!)
                return
            }
            
            guard data != nil else {
                let noDataErr = NSError(domain: tughErrorDomain, code: 85, userInfo: [NSLocalizedDescriptionKey : "[Tugh] twitterReverseAuth: missing expected data in request token response"])
                self.delegate.tughDidFail(noDataErr)
                return
            }
            
            guard let reverseOAuthHeaderLikeParam = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String else {
                let badDataErr = NSError(domain: tughErrorDomain, code: 87, userInfo: [NSLocalizedDescriptionKey : "[Tugh] twitterReverseAuth: failed to stringify request token response"])
                self.delegate.tughDidFail(badDataErr)
                return
            }
            
            let verifyCredentialsURL = NSURL(string: TwitterEndpoint.verifyCredentialsURI)
            let slReq = SLRequest.init(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: verifyCredentialsURL, parameters: nil)
            
            slReq.performRequestWithHandler({ (data, resp, error) -> Void in
                guard error == nil else {
                    debugPrint("[Tugh] twitterReverseAuth: verify credentials error", error)
                    return
                }
                
                let reverseOAuthDictionary = Util.dictionaryFromOAuthCSV(reverseOAuthHeaderLikeParam)
                debugPrint("[Tugh] twitterReverseAuth: reverseOAuthHeaderLikeParam - processed", reverseOAuthDictionary)
                
                let accessTokenParams: [String : String] = [
                    "x_reverse_auth_target" : consumerKey,
                    "x_reverse_auth_parameters" : reverseOAuthHeaderLikeParam
                ]
                
                let slTokenReq = SLRequest.init(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: NSURL(string: TwitterEndpoint.accessTokenURI), parameters: accessTokenParams)
                slTokenReq.account = account
                let tokenReq = slTokenReq.preparedURLRequest()
                
                self.httpClient.performRequest(tokenReq, completion: { (data, response, error) -> Void in
                    let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    debugPrint("reverse token req", responseString)
                    
                    guard let finalDict = Util.parseQueryString(responseString as! String) else {
                        let badParseErr = NSError(domain: tughErrorDomain, code: 101, userInfo: [NSLocalizedDescriptionKey : "[Tugh] twitterReverseAuth: failed to parse reverse-auth access token response"])
                        self.delegate.tughDidFail(badParseErr)
                        return
                    }
                    
                    guard let finalToken = finalDict["oauth_token"] as String?,
                        let finalSecret = finalDict["oauth_token_secret"] as String?,
                        let finalUserID = finalDict["user_id"] as String?,
                        let finalScreenName = finalDict["screen_name"] as String?
                    else {
                        let missingKeyErr = NSError(domain: tughErrorDomain, code: 101, userInfo: [NSLocalizedDescriptionKey : "[Tugh] twitterReverseAuth: failed to find required keys in parsed access token response"])
                        self.delegate.tughDidFail(missingKeyErr)
                        return
                    }
                    
                    let tw = TughTwitterSession(authToken: finalToken, authTokenSecret: finalSecret, screenName: finalScreenName, userID: finalUserID)
                    self.delegate.tughDidReceiveTwitterSession(tw)
                })
                
            })
        }

    }
}
