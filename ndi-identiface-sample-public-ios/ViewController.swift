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
    @IBOutlet weak var progressBar: UIProgressView!
    
    
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
        
//        progressBar.isHidden = true
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers![1].cornerRadius = 4
        progressBar.subviews[1].clipsToBounds = true
        
        nricField.text = "G2957839M"
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
    
    func validateResult(nric: String, sessionToken: String, sessionCompletionHandler: @escaping (JSON?) -> Void) {
           let validateResultURL = URL(string: baseURL + validateResultAPI)!
           
           let params: [String: Any] = [
               "service_id": "SingPass",
               "user_id": nric,
               "pw":"ndi-api",
               "token": sessionToken
           ]
           
           var request = URLRequest(url: validateResultURL)
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
    
    func sdkDidInitialise() {
        
        ndiWrapper.launchBioAuth(streamingURL: self.streamingURL, sessionToken: self.sessionToken, callback: { (status) in

            DispatchQueue.main.async {
                self.actionButton.isHidden = true
                self.progressBar.isHidden = false
            }
            
            switch status {
            case .success(token: let token):
                if (token != self.sessionToken) {
                    let alert = UIAlertController(title: "Error", message: "Session Error. Please try again", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                    
                    DispatchQueue.main.async {
                        self.sessionToken = ""
                        
                        self.actionButton.setTitle("Verify my identity", for: .normal)
                        self.actionButton.backgroundColor = UIColor.systemBlue
                        
                        self.homeLabel.text = "Let's try again?"
                        self.homeLabel.textColor = UIColor.systemRed
                    }
                } else {
                    DispatchQueue.main.async {
                        self.homeLabel.text = "Verifying with SingPass servers..."
                    }
                    
                    self.validateResult(nric: self.nricField.text!, sessionToken: token, sessionCompletionHandler: { response in
                            if let response = response {
                                print("====")
                                print(response)
                            }
                        }
                    )
                }
                break
            case .error:
                print("ERROR!")
                print(type(of: status))
                break
            case .processing(progress: let progress, message: let progressMessage):
                DispatchQueue.main.async {
                    self.homeLabel.text = progressMessage
                    self.progressBar.setProgress(Float(progress), animated: true)
                    print(Float(progress))
                }
                break
            default:
                print(status)
                break
            }
        })
        
    }
    
    @IBAction func toggleNRIC(sender: UISwitch) {
        print(sender.isOn)
        nricField.text = sender.isOn ? "G2834561K" : "G2957839M"
    }
    
    @IBAction func loadFace(sender: AnyObject) {
        
        if (sessionToken != "") {
            sdkDidInitialise()
        } else {
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
                        
                        print(response)
                        
                        if (response["type"].string! == "success") {
                            DispatchQueue.main.async {
                                self.sessionToken = response["token"].string!
                                
                                // initialise SDK
                                self.ndiWrapper = NDIWrapper(streamingURL: self.streamingURL, sessionToken: self.sessionToken)

                                
                                self.actionButton.isHidden = false
                                self.indicatorView.isHidden = true
                                
                                self.actionButton.setTitle("Launch Face Verification", for: .normal)
                                self.actionButton.backgroundColor = UIColor.systemGreen
                                
                                self.homeLabel.text = "Let's begin face verification with SingPass Face."
                            }
                        }
                    }
                })
            }
        }
        
        
    }

    
    @IBAction func privacyStmtPressed(_ sender: UIButton) {
        if let url = URL(string: "https://go.gov.sg/singpass-identiface-data-privacy") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated:true, completion: nil)
        }
    }
    
    func userDidLogIn() {
        print("LOGGED IN")
    }

}

