//
//  ViewController.swift
//  Identiface-Sample
//
//  Created by Emmanuel Rayendra on 3/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var appLabel: UILabel!
    @IBOutlet var homeLabel: UILabel!
    @IBOutlet var nricField: UITextField!
    
    let isDangerColor = UIColor(red:255/255.0, green:56/255.0, blue:96/255.0, alpha:1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appLabel.text = "Welcome to Identiface"
    }
    
    @IBAction func loadFace(sender: AnyObject) {
        if (nricField.text == "") {
            homeLabel.text = "Key in your NRIC/FIN number above."
            homeLabel.textColor = isDangerColor
        } else {
            homeLabel.text = "Verifying your NRIC..."
            homeLabel.textColor = UIColor(red: 50/255.0, green: 115/255.0, blue: 220/255.0, alpha: 1)
        }
    }


}

