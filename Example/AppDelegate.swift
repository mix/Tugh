//
//  AppDelegate.swift
//  Example
//
//  Created by Robert Otani on 9/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import UIKit
import Tugh

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if Tugh.isOAuthCallback(url) {
            Tugh.notifyWithCallbackURL(url)
        }
        return true
    }


}

