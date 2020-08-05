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

class ViewController: UIViewController {
    
    // UI Outlets
    @IBOutlet var appLabel: UILabel!
    @IBOutlet var homeLabel: UILabel!
    @IBOutlet var nricField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
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
        appLabel.text = "Welcome to Identiface"
        indicatorView.isHidden = true
        nricField.text = "G2979480X"
    }
    
    func getSessionToken(nric: String) -> (status: Int, token: String, type: String) {
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
            return (500, "Error", "error")
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
                    print(json)
                } catch {
                    print(error)
                }
            }
        })
        
        task.resume()
        
        return(500, "App Error", "error")
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
            
            getSessionToken(nric: nricField.text!)
            
            homeLabel.text = "SHIT"
            
//            ndiWrapper = NDIWrapper(streamingURL: streamingURL, sessionToken: sessionToken)
        }
    }

}

