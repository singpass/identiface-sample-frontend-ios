//
//  ViewController.swift
//  Identiface-Sample
//
//  Created by Emmanuel Rayendra on 3/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import UIKit
import NDIWrapper

class ViewController: UIViewController {
    
    @IBOutlet var appLabel: UILabel!
    @IBOutlet var homeLabel: UILabel!
    @IBOutlet var nricField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    private var ndiWrapper: NDIWrapper!
    
    let isDangerColor = UIColor(red:255/255.0, green:56/255.0, blue:96/255.0, alpha:1)
    
    let baseURL = "https://www.identiface.live/api"
    let getSessionTokenAPI = "/face/verify/token"
    let validateResultAPI = "/face/verify/validate"
    
    let streamingURL = ""
    var sessionToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appLabel.text = "Welcome to Identiface"
        indicatorView.isHidden = true
    }
    
    func getSessionToken(nric: String) {
        let getSessionTokenURL = URL(string: baseURL + getSessionTokenAPI)!
        
        var request = URLRequest(url: getSessionTokenURL)
        request.httpMethod = "POST"
        
        let reqJSON = [
            "service_id": "SingPass",
            "user_id": nric,
            "pw":"ndi-api"
        ]
        
//        if let jsonData = try? JSONSerialization.data(withJSONObject: reqJSON, options: []) {
//            URLSession.shared.uploadTask(with: request, from: jsonData) { data}
//        }
    }
    
    func validateResult() {
        
    }
    
    @IBAction func loadFace(sender: AnyObject) {
        
        if (nricField.text == "") {
            homeLabel.text = "Key in your NRIC/FIN number above."
            homeLabel.textColor = isDangerColor
        } else {
            homeLabel.text = "Verifying your NRIC..."
            homeLabel.textColor = UIColor(red: 50/255.0, green: 115/255.0, blue: 220/255.0, alpha: 1)
            
            // hide actionButton when no input errors
            actionButton.isHidden = true
            
            indicatorView.startAnimating()
            indicatorView.isHidden = false
            ndiWrapper = NDIWrapper(streamingURL: streamingURL, sessionToken: sessionToken)
        }
    }

}

