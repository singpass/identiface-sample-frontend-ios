//
//  ViewController.swift
//  Identiface-Sample
//
//  Created by Emmanuel Rayendra on 3/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import UIKit
import NDIWrapper
import SwiftyJSON
import SafariServices

class ViewController: UIViewController {
    
    // UI Outlets
    @IBOutlet var appLabel: UILabel!
    @IBOutlet var homeLabel: UILabel!
    @IBOutlet var nricField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var alternativeLoginButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet var validationNRICToggle: UISwitch!
    
    
    // UI styles
    let isDangerColor = UIColor(red:255/255.0, green:56/255.0, blue:96/255.0, alpha:1)
    
    // Identiface QuickStart API
    let baseURL = "https://www.identiface.live/api"
    let getSessionTokenAPI = "/face/verify/token"
    let validateResultAPI = "/face/verify/validate"
    
    // SingPass servers and SDK initialisations
    let streamingURL = "https://stg-bio-stream.singpass.gov.sg"
    var sessionToken = ""
    private var ndiWrapper: NDIWrapper!
    
    // Code begins here
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appLabel.text = "Login to Identiface"
        indicatorView.isHidden = true
        nricField.text = "G2957839M"
        print(validationNRICToggle.isOn)
        actionButton.layer.cornerRadius = 5
    }
    
    func getSessionToken(nric: String, sessionCompletionHandler: @escaping (JSON?) -> Void) {
        let getSessionTokenURL = URL(string: baseURL + getSessionTokenAPI)!
        
        let params: [String: Any] = [
            "service_id": "SingPass",
            "user_id": nric,
            "pw":"ndi-api"
        ]
        
        var request = URLRequest(url: getSessionTokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let reqBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return
        }
        request.httpBody = reqBody
        request.timeoutInterval = 10
        
        let session = URLSession.shared
        
        print(request.httpBody!)
        
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            if let error = error {
                print("ERROR FETCH: \(error)")
            }
            
            if let response = response {
                print("RESPONSE: \(response)")
            }
            
            if let data = data {
                do {
                    let json = try JSON(data: data)
                    sessionCompletionHandler(json)
                } catch {
                    print(error)
                }
            }
        })
        
        task.resume()
        
    }
    
    func validateResult() {
        
    }
    
    @IBAction func toggleNRIC(sender: UISwitch) {
        print(sender.isOn)
        nricField.text = sender.isOn ? "G2834561K" : "G2957839M"
    }
    
    @IBAction func loadFace(sender: AnyObject) {
        
        if (nricField.text == "") {
            homeLabel.text = "Key in your NRIC/FIN number above."
            homeLabel.textColor = isDangerColor
        } else {
            homeLabel.text = "Verifying your NRIC..."
            
            // hide actionButton when no input errors
            actionButton.isHidden = true
            alternativeLoginButton.isHidden = true
            
            indicatorView.startAnimating()
            indicatorView.isHidden = false
            
            getSessionToken(nric: nricField.text!, sessionCompletionHandler: {response in
                if let response = response {
                    self.sessionToken = response["token"].string!
                    self.ndiWrapper = NDIWrapper(streamingURL: self.streamingURL, sessionToken: self.sessionToken)
                    
                    self.ndiWrapper.launchBioAuth(streamingURL: self.streamingURL, sessionToken: self.sessionToken, callback: { (status) in
                        print(status)
                    })
                }
            })
        }
    }
    
    @IBAction func privacyStmtPressed(_ sender: UIButton) {
        if let url = URL(string: "https://go.gov.sg/singpass-identiface-data-privacy") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated:true, completion: nil)
        }
    }

}

