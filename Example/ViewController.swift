//
//  ViewController.swift
//  Example
//
//  Created by Robert Otani on 9/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var consumerKeyField: UITextField!
    @IBOutlet weak var consumerSecretField: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var reverseOAuthButton: UIButton!
    @IBOutlet weak var oAuthButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func didTapReverseOAuth(sender: AnyObject) {
        debugPrint("reverse derp")
    }
    
    @IBAction func didTapOAuth(sender: AnyObject) {
        debugPrint("derp")
    }
    
    @IBAction func didTapClear(sender: AnyObject) {
        debugPrint("clear")
    }
    


}

