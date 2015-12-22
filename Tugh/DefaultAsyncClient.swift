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
        postBody: String?,
        headers: [String : String]?,
        completion: ((data: NSData?, error: NSError?) -> Void)) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "\(RequestMethod.POST)"
            
        if let body = postBody {
            request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
        headers?.forEach({ (k, v) -> () in
            request.setValue(v, forHTTPHeaderField: k)
        })
        
        performRequest(request) { (data, response, error) -> Void in
            completion(data: data, error: error)
        }
        
    }
    
    public func performGET(
        uri: String,
        headers: [String : String]?,
        completion: ((data: NSData?, error: NSError?) -> Void)) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "\(RequestMethod.GET)"
        
        if headers != nil {
            for (k, v) in headers! {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        performRequest(request) { (data, response, error) -> Void in
            completion(data: data, error: error)
        }
        
    }
    
    private func performRequest(
        req: NSURLRequest,
        completion:((data: NSData?, response: NSURLResponse?, error: NSError?)->Void)) {
        
        sess.dataTaskWithRequest(req) { (data, resp, error) -> Void in
            guard error == nil && data != nil else {
                completion(data: nil, response: resp, error: error)
                return
            }
            
            completion(data: data, response: resp, error: error)
            
        }.resume()
    }
    
    
}