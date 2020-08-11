//
//  LoggedIn.swift
//  ndi-identiface-sample-public-ios
//
//  Created by Emmanuel Rayendra on 11/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import UIKit

class LoggedIn: UIViewController {
    
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    var userID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeLabel.text = "Welcome, " + userID + "!"
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func logout(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
}
