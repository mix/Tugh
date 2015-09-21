//
//  ViewController.swift
//  Example
//
//  Created by Robert Otani on 9/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import UIKit
import Tugh
import Social
import Accounts

class ViewController: UIViewController, UITextFieldDelegate, TughDelegate {

    @IBOutlet weak var consumerKeyField: UITextField!
    @IBOutlet weak var consumerSecretField: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var reverseOAuthButton: UIButton!
    @IBOutlet weak var oAuthButton: UIButton!
    @IBOutlet weak var outputView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var outputBaseMessage: String?
    var tugh: Tugh?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reverseOAuthButton.enabled = false
        oAuthButton.enabled = false
        clearButton.enabled = false
        
        outputBaseMessage = outputView.text

        tugh = Tugh(httpClient: DefaultAsyncClient(), delegate: self)
    }
    
    @IBAction func didTapReverseOAuth(sender: AnyObject) {
        let accountStore = ACAccountStore()
        let twAccountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        accountStore.requestAccessToAccountsWithType(twAccountType, options: nil) { (isGranted, error) -> Void in
            guard isGranted else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.displayAlertWithMessage("Access to Twitter account denied. Check iOS Settings.")
                })
                
                return
            }
            
            let twAccounts = accountStore.accountsWithAccountType(twAccountType) as? [ACAccount]
            if twAccounts?.count > 0 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.chooseAccount(twAccounts!)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.displayAlertWithMessage("Sorry… couldn’t find Twitter accounts in iOS Settings")
                })
            }

        }
        
    }
    
    func chooseAccount(accounts: [ACAccount]) {
        if accounts.count == 1 {
            self.performReverseAuth(accounts.first!)
            return
        }
        
        let chooser = UIAlertController(title: "Twitter", message: "Choose Username", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for account in accounts {
            let choice = UIAlertAction(title: account.username, style: UIAlertActionStyle.Default, handler: { (actionChoice) -> Void in
                self.performReverseAuth(account)
            })
            chooser.addAction(choice)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        chooser.addAction(cancel)
        
        self.presentViewController(chooser, animated: true, completion: nil)
    }
    
    func performReverseAuth(twAccount: ACAccount) {
        debugPrint(twAccount.username)
        activityIndicator.startAnimating()
        let consumerKey = consumerKeyField.text!
        tugh?.twitterReverseAuth(twAccount, consumerKey: consumerKey)
    }
    
    @IBAction func didTapOAuth(sender: AnyObject) {
        let consumerKey: String = consumerKeyField.text!
        let consumerSecret: String = consumerSecretField.text!
        tugh?.twitterLogin(consumerKey, consumerSecret: consumerSecret, callbackURI: "tughexample://oauth/twitter")
    }
    
    func updateOutputView(text: String) {
        activityIndicator.stopAnimating()
        outputView.text = "\(outputView.text)\n\n\(text)"
    }
    
    @IBAction func didTapClear(sender: AnyObject) {
        consumerKeyField.text = nil
        consumerSecretField.text = nil
        outputView.text = outputBaseMessage
        updateButtonState()
    }
    
    @IBAction func textFieldEditingDidChange(sender: AnyObject) {
        updateButtonState()
    }
    
    
    func updateButtonState() {
        let enableButtons = consumerKeyField.text?.characters.count > 0 && consumerSecretField.text?.characters.count > 0
        reverseOAuthButton.enabled = enableButtons
        oAuthButton.enabled = enableButtons
        clearButton.enabled = consumerKeyField.text?.characters.count > 0 || consumerSecretField.text?.characters.count > 0
    }
    
    // MARK: Alert
    
    func displayAlertWithMessage(message: String) {
        let alert = UIAlertController(title: "Hey", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        updateButtonState()
        return true
    }

    // MARK: TughDelegate
    
    func tughDidFail(error: NSError) {
        self.updateOutputView("Problem with reverse oAuth: \(error)")
    }
    
    func tughDidReceiveRequestToken(requestToken: String) {
        let authz = "\(TwitterEndpoint.authzURI)?oauth_token=\(requestToken)"
        // Alternately, present a web view loaded with this URI
        UIApplication.sharedApplication().openURL(NSURL(string: authz)!)
    }
    
    func tughDidReceiveTwitterSession(twSession: TughTwitterSession) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in            
            self.updateOutputView("\(twSession)")
        }
    }

}

