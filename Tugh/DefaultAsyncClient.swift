//
//  DefaultAsyncClient.swift
//  Tugh
//
//  Created by Robert Otani on 9/19/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation

public class DefaultAsyncClient : AsyncClientProtocol {
    let sess: NSURLSession = NSURLSession(
        configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    
    required public init() {
    }
    
    deinit {
        sess.invalidateAndCancel()
    }
    
    public func performPOST(
        uri: String,
        postString: String?,
        headers: [String : String]?,
        completion: ((responseDict: [String : String]?, error: NSError?) -> Void)) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "\(RequestMethod.POST)"
            
        if postString != nil {
            request.HTTPBody = postString!.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
        if headers != nil {
            for (k, v) in headers! {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        performRequest(request) { (responseDict, response, error) -> Void in
            completion(responseDict: responseDict, error: error)
        }
        
    }
    
    public func performGET(
        uri: String,
        headers: [String : String]?,
        completion: ((responseDict: [String : String]?, error: NSError?) -> Void)) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "\(RequestMethod.GET)"
        
        if headers != nil {
            for (k, v) in headers! {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        performRequest(request) { (responseDict, response, error) -> Void in
            completion(responseDict: responseDict, error: error)
        }
        
    }
    
    private func performRequest(
        req: NSURLRequest,
        completion:((responseDict: [String : String]?, response: NSURLResponse?, error: NSError?)->Void)) {
        
        sess.dataTaskWithRequest(req) { (data, resp, error) -> Void in
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String
            debugPrint("DefaultAsyncClient:", responseString)
            guard error == nil && data != nil else {
                completion(responseDict: nil, response: resp, error: error)
                return
            }
            
            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                let responseDict = Util.parseQueryString(responseString)
                completion(responseDict: responseDict, response: resp, error: nil)
            } else {
                let responseParseErrorInfo = [
                    NSLocalizedDescriptionKey : "Problem parsing stringified response to Dictionary<String, String> type"
                ]
                let conversionError: NSError = NSError(domain: tughErrorDomain, code: -1, userInfo: responseParseErrorInfo)
                completion(responseDict: nil, response: resp, error: conversionError)
            }
            
        }.resume()
    }
    
}